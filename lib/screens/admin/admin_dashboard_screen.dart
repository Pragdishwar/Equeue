import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/admin/stat_card.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_button.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(queueStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Admin Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(queueStatsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(queueStatsProvider);
            },
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(Spacing.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Queue Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: Spacing.s16),

                  // Stat Cards Grid
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: Spacing.s16,
                    mainAxisSpacing: Spacing.s16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.15,
                    children: [
                      StatCard(
                        title: 'Tokens Issued',
                        value: stats.tokensToday.toString(),
                        icon: Icons.confirmation_number_rounded,
                        color: AppColors.primary,
                      ),
                      StatCard(
                        title: 'Now Serving',
                        value: stats.currentlyServing.toString(),
                        icon: Icons.play_arrow_rounded,
                        color: AppColors.secondary,
                      ),
                      StatCard(
                        title: 'Waiting in Queue',
                        value: stats.inQueue.toString(),
                        icon: Icons.hourglass_empty_rounded,
                        color: AppColors.warning,
                      ),
                      StatCard(
                        title: 'Avg Wait Time',
                        value: '${stats.avgWaitMinutes.toStringAsFixed(1)}m',
                        icon: Icons.access_time_filled_rounded,
                        color: AppColors.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.s32),

                  // Quick Actions Card
                  Text(
                    'Administrative Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: Spacing.s16),

                  GlassCard(
                    padding: const EdgeInsets.all(Spacing.s20),
                    child: Column(
                      children: [
                        _buildQuickActionRow(
                          context,
                          title: 'Live Queue Console',
                          subtitle: 'Call next, skip, and manage tokens',
                          icon: Icons.queue_play_next_rounded,
                          color: AppColors.primary,
                          onTap: () => context.push('/admin/queue'),
                        ),
                        const Divider(color: AppColors.divider, height: 24),
                        _buildQuickActionRow(
                          context,
                          title: 'Manage Branches',
                          subtitle: 'View and edit active offices',
                          icon: Icons.storefront_rounded,
                          color: AppColors.secondary,
                          onTap: () => context.push('/admin/branches'),
                        ),
                        const Divider(color: AppColors.divider, height: 24),
                        _buildQuickActionRow(
                          context,
                          title: 'Manage Services',
                          subtitle: 'Configure branch categories & timings',
                          icon: Icons.settings_suggest_rounded,
                          color: AppColors.warning,
                          onTap: () => context.push('/admin/services'),
                        ),
                        const Divider(color: AppColors.divider, height: 24),
                        _buildQuickActionRow(
                          context,
                          title: 'Analytics & Reports',
                          subtitle: 'Peak hours, wait lists & counts',
                          icon: Icons.analytics_rounded,
                          color: AppColors.error,
                          onTap: () => context.push('/admin/reports'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.s24),

                  // Return to user view
                  GradientButton(
                    label: 'Switch to Customer View',
                    onPressed: () => context.go('/home'),
                    gradient: const LinearGradient(
                      colors: [AppColors.surfaceLight, AppColors.surface],
                    ),
                  ),
                  const SizedBox(height: Spacing.s24),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.s24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                const SizedBox(height: Spacing.s16),
                Text('Failed to load dashboard metrics: $err', style: const TextStyle(color: Colors.white)),
                const SizedBox(height: Spacing.s16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(queueStatsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.s4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(Spacing.s12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: Spacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
