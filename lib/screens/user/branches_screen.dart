import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/loading_shimmer.dart';

class BranchesScreen extends ConsumerStatefulWidget {
  const BranchesScreen({super.key});

  @override
  ConsumerState<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends ConsumerState<BranchesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Branches',
        showBack: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.s16),
          child: Column(
            children: [
              const SizedBox(height: Spacing.s8),
              // Search Input
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search branches...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textTertiary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceLight.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: Spacing.s16),

              // Branches list
              Expanded(
                child: branchesAsync.when(
                  data: (branches) {
                    final filteredBranches = branches.where((branch) {
                      final nameMatch = branch.name.toLowerCase().contains(_searchQuery);
                      final addressMatch = branch.address.toLowerCase().contains(_searchQuery);
                      return nameMatch || addressMatch;
                    }).toList();

                    if (filteredBranches.isEmpty) {
                      return EmptyState(
                        icon: Icons.storefront_rounded,
                        title: 'No Branches Found',
                        subtitle: _searchQuery.isEmpty
                            ? 'There are no active branches at the moment.'
                            : 'Try searching for something else.',
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredBranches.length,
                      itemBuilder: (context, index) {
                        final branch = filteredBranches[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.s12),
                          child: GlassCard(
                            onTap: () => context.push('/branches/${branch.id}'),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
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
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        branch.address,
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        branch.contact,
                                        style: TextStyle(
                                          color: AppColors.textTertiary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const LoadingShimmerList(count: 5, itemHeight: 88),
                  error: (err, _) => Center(child: Text('Error loading branches: $err')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
