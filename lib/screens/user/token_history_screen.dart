import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/queue_token.dart';
import '../../providers/providers.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/queue/token_card.dart';

class TokenHistoryScreen extends ConsumerStatefulWidget {
  const TokenHistoryScreen({super.key});

  @override
  ConsumerState<TokenHistoryScreen> createState() => _TokenHistoryScreenState();
}

class _TokenHistoryScreenState extends ConsumerState<TokenHistoryScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(userTokenHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Queue History'),
      body: Column(
        children: [
          // Filter Row
          _buildFilterBar(),

          // History List
          Expanded(
            child: historyAsync.when(
              data: (tokens) {
                final filteredTokens = _filterTokens(tokens);

                if (filteredTokens.isEmpty) {
                  return const EmptyState(
                    icon: Icons.history_rounded,
                    title: 'No History',
                    subtitle: 'You do not have any tokens matching this filter.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(userTokenHistoryProvider);
                  },
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.s24,
                      vertical: Spacing.s8,
                    ),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filteredTokens.length,
                    itemBuilder: (context, index) {
                      final token = filteredTokens[index];
                      return TokenCard(
                        token: token,
                        onTap: () {
                          // Allow tracking if not completed, else show details
                          context.push('/queue/${token.id}');
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: Spacing.s24),
                child: LoadingShimmerList(count: 3, itemHeight: 160),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.s24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                      const SizedBox(height: Spacing.s16),
                      Text(
                        'Failed to load history: $err',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Spacing.s16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(userTokenHistoryProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = ['All', 'Completed', 'Cancelled', 'Skipped'];
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: Spacing.s12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.s24),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: Spacing.s8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                }
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  List<QueueToken> _filterTokens(List<QueueToken> tokens) {
    if (_selectedFilter == 'All') return tokens;
    
    return tokens.where((token) {
      switch (_selectedFilter) {
        case 'Completed':
          return token.status == TokenStatus.completed;
        case 'Cancelled':
          return token.status == TokenStatus.cancelled;
        case 'Skipped':
          return token.status == TokenStatus.skipped;
        default:
          return true;
      }
    }).toList();
  }
}
