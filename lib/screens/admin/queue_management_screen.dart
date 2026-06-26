import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../models/branch.dart';
import '../../models/queue_token.dart';
import '../../providers/providers.dart';
import '../../services/qr_service.dart';
import '../../widgets/admin/now_serving_card.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/queue/queue_list_item.dart';

class QueueManagementScreen extends ConsumerStatefulWidget {
  const QueueManagementScreen({super.key});

  @override
  ConsumerState<QueueManagementScreen> createState() => _QueueManagementScreenState();
}

class _QueueManagementScreenState extends ConsumerState<QueueManagementScreen> {
  String? _selectedBranchId;
  String? _selectedServiceId;
  RealtimeChannel? _queueSubscription;
  bool _isCallingNext = false;

  @override
  void dispose() {
    _unsubscribeQueue();
    super.dispose();
  }

  void _unsubscribeQueue() {
    if (_queueSubscription != null) {
      ref.read(queueServiceProvider).unsubscribe(_queueSubscription!);
      _queueSubscription = null;
    }
  }

  void _subscribeQueue(String serviceId) {
    _unsubscribeQueue();
    _queueSubscription = ref.read(queueServiceProvider).subscribeToServiceQueue(
      serviceId,
      () {
        if (!mounted) return;
        // Invalidate relevant providers to force reload in UI
        ref.invalidate(serviceQueueProvider(serviceId));
        ref.invalidate(currentServingProvider(serviceId));
        ref.invalidate(completedTodayProvider(serviceId));
        ref.invalidate(queueStatsProvider);
      },
    );
  }

  Future<void> _callNext() async {
    if (_selectedServiceId == null) return;

    setState(() => _isCallingNext = true);
    try {
      final token = await ref.read(queueServiceProvider).callNextToken(_selectedServiceId!);
      
      if (mounted) {
        setState(() => _isCallingNext = false);
        if (token != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Called token ${token.tokenNumber}'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No customers waiting in the queue'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCallingNext = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to call next: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _completeToken(String tokenId) async {
    try {
      await ref.read(queueServiceProvider).completeToken(tokenId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token completed'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _skipToken(String tokenId) async {
    try {
      await ref.read(queueServiceProvider).skipToken(tokenId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token marked as skipped'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _cancelToken(String tokenId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cancel Token', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to cancel this token?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No', style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel Token'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(queueServiceProvider).cancelToken(tokenId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Token cancelled'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _openQRScanner() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            padding: const EdgeInsets.all(Spacing.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Scan Customer QR',
                      style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.s16),
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: MobileScanner(
                      controller: MobileScannerController(
                        detectionSpeed: DetectionSpeed.normal,
                        facing: CameraFacing.back,
                      ),
                      onDetect: (capture) async {
                        final barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty) {
                          final codeValue = barcodes.first.rawValue;
                          if (codeValue != null) {
                            Navigator.of(dialogContext).pop(); // Close scanner
                            _handleScannedQR(codeValue);
                          }
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.s16),
                const Text(
                  'Align the customer\'s QR code within the square to scan and check them in.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleScannedQR(String codeData) async {
    final parsed = QRService.parseQRData(codeData);
    if (parsed == null || !QRService.isValidTokenQR(parsed)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR Code Format'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final tokenId = parsed['token_id'] as String;
    final tokenNumber = parsed['token_number'] as String;

    try {
      // Fetch token details to ensure it belongs to selected branch/service (optional check)
      final queueService = ref.read(queueServiceProvider);
      final token = await queueService.getToken(tokenId);

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Token not found in database'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      if (token.status == TokenStatus.completed || 
          token.status == TokenStatus.cancelled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Token $tokenNumber is already ${token.status.name}'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      // Mark token as serving (Checked In)
      await queueService.serveToken(tokenId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Token $tokenNumber successfully checked in and serving'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(allBranchesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Queue Console'),
      floatingActionButton: FloatingActionButton(
        onPressed: _openQRScanner,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.qr_code_scanner_rounded),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.s24),
        child: Column(
          children: [
            const SizedBox(height: Spacing.s16),
            // Selectors
            branchesAsync.when(
              data: (branches) {
                if (branches.isEmpty) {
                  return const EmptyState(
                    icon: Icons.storefront_rounded,
                    title: 'No Branches Available',
                    subtitle: 'Create a branch first to manage queue lists.',
                  );
                }

                // Auto-select first branch if none selected
                if (_selectedBranchId == null && branches.isNotEmpty) {
                  _selectedBranchId = branches.first.id;
                }

                return Column(
                  children: [
                    // Branch Dropdown
                    _buildBranchDropdown(branches),
                    const SizedBox(height: Spacing.s12),

                    // Service Dropdown
                    _buildServiceSelector(),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Text('Error loading branches: $err', style: const TextStyle(color: Colors.white)),
            ),
            
            const SizedBox(height: Spacing.s20),

            // Main Console View
            if (_selectedServiceId != null)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Now Serving Card
                      ref.watch(currentServingProvider(_selectedServiceId!)).when(
                        data: (token) {
                          return Column(
                            children: [
                              NowServingCard(token: token),
                              if (token != null) ...[
                                const SizedBox(height: Spacing.s16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GradientButton(
                                        label: 'Complete Serving',
                                        onPressed: () => _completeToken(token.id),
                                        gradient: const LinearGradient(
                                          colors: [AppColors.success, AppColors.primary],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: Spacing.s12),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _skipToken(token.id),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.warning,
                                          side: const BorderSide(color: AppColors.warning),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                        ),
                                        child: const Text('Skip Customer'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        error: (err, _) => Text('Error loading current serving: $err', style: const TextStyle(color: Colors.white)),
                      ),
                      
                      const SizedBox(height: Spacing.s24),

                      // Call Next Button
                      GradientButton(
                        label: 'CALL NEXT CUSTOMER',
                        onPressed: _callNext,
                        isLoading: _isCallingNext,
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                      ),

                      const SizedBox(height: Spacing.s32),

                      // Queue List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Waiting Queue',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          ref.watch(serviceQueueProvider(_selectedServiceId!)).maybeWhen(
                            data: (list) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${list.length} waiting',
                                style: const TextStyle(color: AppColors.primary, fontSize: 12),
                              ),
                            ),
                            orElse: () => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.s16),

                      ref.watch(serviceQueueProvider(_selectedServiceId!)).when(
                        data: (tokens) {
                          if (tokens.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: Spacing.s32),
                              child: Text(
                                'Queue is empty.',
                                style: TextStyle(color: AppColors.textTertiary),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: tokens.length,
                            itemBuilder: (context, index) {
                              final token = tokens[index];
                              return QueueListItem(
                                token: token,
                                onCall: () => _callNext(), // In practice callNext serves sequential
                                onSkip: () => _skipToken(token.id),
                                onCancel: () => _cancelToken(token.id),
                                onComplete: () => _completeToken(token.id),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.white)),
                      ),

                      const SizedBox(height: Spacing.s24),

                      // Completed Today Section
                      Row(
                        children: [
                          Text(
                            'Completed Today',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.s16),

                      ref.watch(completedTodayProvider(_selectedServiceId!)).when(
                        data: (completedList) {
                          if (completedList.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: Spacing.s20),
                              child: Text(
                                'No completions yet today.',
                                style: TextStyle(color: AppColors.textTertiary),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: completedList.length,
                            itemBuilder: (context, index) {
                              final token = completedList[index];
                              return QueueListItem(token: token); // Render without action buttons
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(height: Spacing.s48),
                    ],
                  ),
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text(
                    'Please select a branch and service to start managing the queue.',
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchDropdown(List<Branch> branches) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBranchId,
          dropdownColor: AppColors.surface,
          hint: const Text('Select Branch', style: TextStyle(color: AppColors.textSecondary)),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
          isExpanded: true,
          style: const TextStyle(color: Colors.white),
          items: branches.map((b) {
            return DropdownMenuItem<String>(
              value: b.id,
              child: Text(b.name),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedBranchId = val;
              _selectedServiceId = null;
              _unsubscribeQueue();
            });
          },
        ),
      ),
    );
  }

  Widget _buildServiceSelector() {
    if (_selectedBranchId == null) return const SizedBox.shrink();

    final servicesAsync = ref.watch(allBranchServicesProvider(_selectedBranchId!));

    return servicesAsync.when(
      data: (services) {
        if (services.isEmpty) {
          return const Text(
            'No services found for this branch.',
            style: TextStyle(color: AppColors.textTertiary),
          );
        }

        // Auto-select first service if none selected
        if (_selectedServiceId == null && services.isNotEmpty) {
          _selectedServiceId = services.first.id;
          // Subscribe immediately
          _subscribeQueue(_selectedServiceId!);
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.s16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedServiceId,
              dropdownColor: AppColors.surface,
              hint: const Text('Select Service', style: TextStyle(color: AppColors.textSecondary)),
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
              isExpanded: true,
              style: const TextStyle(color: Colors.white),
              items: services.map((s) {
                return DropdownMenuItem<String>(
                  value: s.id,
                  child: Text(s.name),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedServiceId = val;
                });
                if (val != null) {
                  _subscribeQueue(val);
                }
              },
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.white)),
    );
  }
}
