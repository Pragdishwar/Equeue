import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../models/queue_token.dart';
import '../../providers/providers.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/queue/estimated_wait.dart';
import '../../widgets/queue/qr_display.dart';
import '../../widgets/queue/queue_position_indicator.dart';

class QueueTrackingScreen extends ConsumerStatefulWidget {
  final String tokenId;

  const QueueTrackingScreen({
    super.key,
    required this.tokenId,
  });

  @override
  ConsumerState<QueueTrackingScreen> createState() => _QueueTrackingScreenState();
}

class _QueueTrackingScreenState extends ConsumerState<QueueTrackingScreen>
    with SingleTickerProviderStateMixin {
  RealtimeChannel? _realtimeChannel;
  QueueToken? _token;
  bool _isLoading = true;
  String? _errorMessage;
  int _totalInQueue = 0;

  // Animation controller for celebration pulse
  late final AnimationController _celebrationController;
  late final Animation<double> _celebrationScale;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _celebrationScale = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: Curves.elasticOut,
      ),
    );
    
    // Fetch initial data and start realtime subscription
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTokenData();
    });
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _unsubscribeRealtime();
    super.dispose();
  }

  void _unsubscribeRealtime() {
    if (_realtimeChannel != null) {
      ref.read(queueServiceProvider).unsubscribe(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }

  Future<void> _loadTokenData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final queueService = ref.read(queueServiceProvider);
      final token = await queueService.getToken(widget.tokenId);
      
      if (token == null) {
        setState(() {
          _errorMessage = 'Token not found';
          _isLoading = false;
        });
        return;
      }

      // Get count of waiting + called tokens for the same service today
      final currentQueue = await queueService.getQueueForService(token.serviceId);
      
      if (mounted) {
        setState(() {
          _token = token;
          _totalInQueue = currentQueue.length;
          _isLoading = false;
        });

        if (token.status == TokenStatus.called) {
          _celebrationController.forward();
        }

        _subscribeRealtime();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load queue details: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeRealtime() {
    _unsubscribeRealtime();
    
    final queueService = ref.read(queueServiceProvider);
    
    _realtimeChannel = queueService.subscribeToToken(
      widget.tokenId,
      (newRecord) async {
        if (!mounted) return;
        
        // Refresh token from database to ensure related service/branch names are loaded
        final updatedToken = await queueService.getToken(widget.tokenId);
        final currentQueue = updatedToken != null 
            ? await queueService.getQueueForService(updatedToken.serviceId)
            : [];
            
        if (mounted && updatedToken != null) {
          final oldStatus = _token?.status;
          setState(() {
            _token = updatedToken;
            _totalInQueue = currentQueue.length;
          });

          // If the token was just called, trigger the celebration effect
          if (updatedToken.status == TokenStatus.called && oldStatus != TokenStatus.called) {
            _celebrationController.reset();
            _celebrationController.forward();
            _showCelebrationDialog();
          }
        }
      },
    );
  }

  void _showCelebrationDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            padding: const EdgeInsets.all(Spacing.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.campaign_rounded,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: Spacing.s16),
                Text(
                  'IT\'S YOUR TURN!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.s12),
                Text(
                  'Please proceed to the counter. Your token number ${_token?.tokenNumber} is now being called.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.s24),
                GradientButton(
                  label: 'Proceed',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _cancelToken() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cancel Token', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to cancel this virtual token? You will lose your current position in the queue.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Token', style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel Token'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        setState(() => _isLoading = true);
        await ref.read(queueServiceProvider).cancelToken(widget.tokenId);
        
        // Invalidate active tokens so home screen updates
        ref.invalidate(userActiveTokensProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Token cancelled successfully'),
              backgroundColor: AppColors.error,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to cancel token: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _token == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(title: 'Loading Queue...'),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const CustomAppBar(title: 'Error'),
        body: Padding(
          padding: const EdgeInsets.all(Spacing.s24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 64,
                ),
                const SizedBox(height: Spacing.s16),
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.s24),
                GradientButton(
                  label: 'Go Back',
                  onPressed: () => context.pop(),
                  width: 200,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final token = _token!;
    final isWaiting = token.status == TokenStatus.waiting;
    final isFinished = token.status == TokenStatus.completed || 
                       token.status == TokenStatus.cancelled || 
                       token.status == TokenStatus.skipped;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: token.serviceName ?? 'Queue Status',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadTokenData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.s24,
            vertical: Spacing.s16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Branch Name Header
              Text(
                token.branchName ?? 'Virtual Token',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.s24),

              // Status Badge
              StatusBadge(status: token.status),
              const SizedBox(height: Spacing.s24),

              // Circular Position Indicator / Called State
              if (!isFinished) ...[
                QueuePositionIndicator(
                  position: token.position,
                  total: _totalInQueue,
                  status: token.status,
                ),
                const SizedBox(height: Spacing.s24),
                EstimatedWait(minutes: token.estimatedWaitMinutes ?? 0),
              ] else ...[
                // Finished states
                ScaleTransition(
                  scale: _celebrationScale,
                  child: Container(
                    padding: const EdgeInsets.all(Spacing.s32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getStatusColor(token.status).withValues(alpha: 0.1),
                      border: Border.all(
                        color: _getStatusColor(token.status).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _getStatusIcon(token.status),
                      size: 72,
                      color: _getStatusColor(token.status),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.s24),
                Text(
                  _getStatusText(token.status),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: Spacing.s8),
                Text(
                  'Token: ${token.tokenNumber}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],

              const SizedBox(height: Spacing.s32),

              // QR Display if not finished
              if (!isFinished) ...[
                QRDisplay(
                  data: token.qrCode,
                  tokenNumber: token.tokenNumber,
                  size: 160,
                ),
                const SizedBox(height: Spacing.s32),
              ],

              // Actions
              if (isWaiting) ...[
                OutlinedButton.icon(
                  onPressed: _cancelToken,
                  icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                  label: const Text('Cancel Token'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 1.5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.s24,
                      vertical: Spacing.s12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ] else if (isFinished) ...[
                GradientButton(
                  label: 'Back to Home',
                  onPressed: () => context.go('/home'),
                  width: double.infinity,
                ),
              ],
              const SizedBox(height: Spacing.s24),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(TokenStatus status) {
    switch (status) {
      case TokenStatus.completed:
        return AppColors.success;
      case TokenStatus.cancelled:
        return AppColors.error;
      case TokenStatus.skipped:
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(TokenStatus status) {
    switch (status) {
      case TokenStatus.completed:
        return Icons.check_circle_outline_rounded;
      case TokenStatus.cancelled:
        return Icons.cancel_outlined;
      case TokenStatus.skipped:
        return Icons.redo_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getStatusText(TokenStatus status) {
    switch (status) {
      case TokenStatus.completed:
        return 'Queue Completed';
      case TokenStatus.cancelled:
        return 'Token Cancelled';
      case TokenStatus.skipped:
        return 'Token Skipped';
      default:
        return 'Finished';
    }
  }
}
