import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/service_model.dart';
import '../../providers/providers.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/queue/estimated_wait.dart';

class BranchDetailScreen extends ConsumerStatefulWidget {
  final String branchId;

  const BranchDetailScreen({
    super.key,
    required this.branchId,
  });

  @override
  ConsumerState<BranchDetailScreen> createState() => _BranchDetailScreenState();
}

class _BranchDetailScreenState extends ConsumerState<BranchDetailScreen> {
  bool _isJoining = false;
  String? _joiningServiceId;

  Future<void> _joinQueue(ServiceModel service) async {
    setState(() {
      _isJoining = true;
      _joiningServiceId = service.id;
    });

    try {
      final queueService = ref.read(queueServiceProvider);
      final token = await queueService.generateToken(
        serviceId: service.id,
        branchId: widget.branchId,
      );

      // Invalidate tokens provider to update home screen list
      ref.invalidate(userActiveTokensProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully joined queue! Your token is ${token.tokenNumber}'),
          backgroundColor: AppColors.success,
        ),
      );

      context.push('/queue/${token.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join queue: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _joiningServiceId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchAsync = ref.watch(branchByIdProvider(widget.branchId));
    final servicesAsync = ref.watch(branchServicesProvider(widget.branchId));

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Branch Details',
        showBack: true,
      ),
      body: SafeArea(
        child: branchAsync.when(
          data: (branch) {
            if (branch == null) {
              return const EmptyState(
                icon: Icons.storefront_rounded,
                title: 'Branch Not Found',
                subtitle: 'The requested branch does not exist.',
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Spacing.s8),
                  // Branch Header Info
                  GlassCard(
                    padding: const EdgeInsets.all(Spacing.s20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branch.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: Spacing.s8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                branch.address,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacing.s8),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              branch.contact,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.s24),

                  // Services Header
                  Text(
                    'Available Services',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: Spacing.s12),

                  // Services List
                  Expanded(
                    child: servicesAsync.when(
                      data: (services) {
                        if (services.isEmpty) {
                          return const EmptyState(
                            icon: Icons.design_services_outlined,
                            title: 'No Services Available',
                            subtitle: 'This branch is not offering any services at this time.',
                          );
                        }

                        return ListView.builder(
                          itemCount: services.length,
                          itemBuilder: (context, index) {
                            final service = services[index];
                            final isServiceJoining = _isJoining && _joiningServiceId == service.id;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: Spacing.s12),
                              child: GlassCard(
                                padding: const EdgeInsets.all(Spacing.s16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                service.name,
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                service.description,
                                                style: TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: Spacing.s8),
                                        EstimatedWait(
                                          minutes: service.avgServiceTime,
                                          compact: true,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: Spacing.s16),
                                    GradientButton(
                                      label: 'Join Queue',
                                      isLoading: isServiceJoining,
                                      onPressed: _isJoining ? null : () => _joinQueue(service),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const LoadingShimmerList(count: 3, itemHeight: 120),
                      error: (err, _) => Center(child: Text('Error loading services: $err')),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(child: Text('Error loading branch: $err')),
        ),
      ),
    );
  }
}
