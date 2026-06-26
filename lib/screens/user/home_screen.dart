import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/queue/token_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(currentProfileProvider);
    ref.invalidate(userActiveTokensProvider);
    ref.invalidate(branchesProvider);
    ref.invalidate(unreadCountProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final activeTokensAsync = ref.watch(userActiveTokensProvider);
    final branchesAsync = ref.watch(branchesProvider);
    final unreadCountAsync = ref.watch(unreadCountProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _onRefresh(ref),
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Spacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Greeting + Profile info + Notification icon)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    profileAsync.when(
                      data: (profile) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello,',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          Text(
                            profile?.fullName ?? 'Guest',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      loading: () => const LoadingShimmer(height: 50, width: 150),
                      error: (_, __) => const Text('Error loading profile'),
                    ),
                    Row(
                      children: [
                        // Notification bell
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined, size: 28, color: Colors.white),
                              onPressed: () => context.push('/notifications'),
                            ),
                            unreadCountAsync.when(
                              data: (count) {
                                if (count <= 0) return const SizedBox.shrink();
                                return Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$count',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // Profile Avatar
                        profileAsync.when(
                          data: (profile) => GestureDetector(
                            onTap: () => context.push('/profile'),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                profile?.initials ?? '?',
                                style: const TextStyle(
                                  color: AppColors.background,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          loading: () => const CircleAvatar(radius: 20, backgroundColor: AppColors.surfaceLight),
                          error: (_, __) => const CircleAvatar(radius: 20, child: Icon(Icons.person)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.s24),

                // Active Tokens Horizontal Scroll Section
                Text(
                  'Your Active Tokens',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: Spacing.s12),
                activeTokensAsync.when(
                  data: (tokens) {
                    if (tokens.isEmpty) {
                      return EmptyState(
                        icon: Icons.confirmation_number_outlined,
                        title: 'No Active Tokens',
                        subtitle: 'Join a queue to generate virtual tokens.',
                        actionLabel: 'Browse Branches',
                        onAction: () => context.push('/branches'),
                      );
                    }
                    return SizedBox(
                      height: 185,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: tokens.length,
                        itemBuilder: (context, index) {
                          final token = tokens[index];
                          return SizedBox(
                            width: MediaQuery.of(context).size.width * 0.85,
                            child: Padding(
                              padding: const EdgeInsets.only(right: Spacing.s16),
                              child: TokenCard(
                                token: token,
                                onTap: () => context.push('/queue/${token.id}'),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const LoadingShimmer(height: 160),
                  error: (err, _) => Center(child: Text('Error loading tokens: $err')),
                ),
                const SizedBox(height: Spacing.s24),

                // Quick Actions Grid
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: Spacing.s12),
                Row(
                  children: [
                    Expanded(
                      child: GlassCard(
                        onTap: () => context.push('/branches'),
                        padding: const EdgeInsets.symmetric(vertical: Spacing.s20),
                        child: Column(
                          children: [
                            const Icon(Icons.add_circle_outline_rounded, size: 32, color: AppColors.primary),
                            const SizedBox(height: Spacing.s8),
                            Text(
                              'Join Queue',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Find branches',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.s16),
                    Expanded(
                      child: GlassCard(
                        onTap: () => context.push('/history'),
                        padding: const EdgeInsets.symmetric(vertical: Spacing.s20),
                        child: Column(
                          children: [
                            const Icon(Icons.history_toggle_off_rounded, size: 32, color: AppColors.secondary),
                            const SizedBox(height: Spacing.s8),
                            Text(
                              'My History',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Past tokens',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.s24),

                // Nearby Branches
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Featured Branches',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/branches'),
                      child: const Row(
                        children: [
                          Text('See All', style: TextStyle(color: AppColors.primary)),
                          Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.s8),
                branchesAsync.when(
                  data: (branches) {
                    if (branches.isEmpty) {
                      return const Center(child: Text('No branches available'));
                    }
                    final displayBranches = branches.take(3).toList();
                    return Column(
                      children: displayBranches.map((branch) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.s12),
                          child: GlassCard(
                            onTap: () => context.push('/branches/${branch.id}'),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.storefront_rounded, color: AppColors.primary),
                                ),
                                const SizedBox(width: Spacing.s16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        branch.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        branch.address,
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const LoadingShimmerList(count: 3, itemHeight: 70),
                  error: (err, _) => Center(child: Text('Error loading branches: $err')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
