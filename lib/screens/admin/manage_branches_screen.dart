import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/branch.dart';
import '../../providers/providers.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/loading_shimmer.dart';

class ManageBranchesScreen extends ConsumerStatefulWidget {
  const ManageBranchesScreen({super.key});

  @override
  ConsumerState<ManageBranchesScreen> createState() => _ManageBranchesScreenState();
}

class _ManageBranchesScreenState extends ConsumerState<ManageBranchesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _openBranchDialog({Branch? branch}) {
    if (branch != null) {
      _nameController.text = branch.name;
      _addressController.text = branch.address;
      _contactController.text = branch.contact;
    } else {
      _nameController.clear();
      _addressController.clear();
      _contactController.clear();
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            padding: const EdgeInsets.all(Spacing.s24),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch != null ? 'Edit Branch' : 'Add New Branch',
                      style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: Spacing.s20),
                    
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Branch Name', Icons.storefront_rounded),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: Spacing.s16),

                    // Address Field
                    TextFormField(
                      controller: _addressController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration: _inputDecoration('Address', Icons.location_on_outlined),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: Spacing.s16),

                    // Contact Field
                    TextFormField(
                      controller: _contactController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Contact Number', Icons.phone_outlined),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: Spacing.s24),

                    StatefulBuilder(
                      builder: (context, setSubState) {
                        return GradientButton(
                          label: branch != null ? 'Save Changes' : 'Create Branch',
                          isLoading: _isLoading,
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;
                            
                            setSubState(() => _isLoading = true);
                            try {
                              final branchService = ref.read(branchServiceProvider);
                              if (branch != null) {
                                await branchService.updateBranch(
                                  id: branch.id,
                                  name: _nameController.text.trim(),
                                  address: _addressController.text.trim(),
                                  contact: _contactController.text.trim(),
                                );
                              } else {
                                await branchService.createBranch(
                                  name: _nameController.text.trim(),
                                  address: _addressController.text.trim(),
                                  contact: _contactController.text.trim(),
                                );
                              }
                              
                              ref.invalidate(allBranchesProvider);
                              ref.invalidate(branchesProvider);
                              
                              if (context.mounted) {
                                Navigator.of(dialogContext).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(branch != null
                                        ? 'Branch updated successfully'
                                        : 'Branch created successfully'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            } finally {
                              setSubState(() => _isLoading = false);
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  Future<void> _deleteBranch(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Branch', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this branch? This action will permanently remove all services and tokens associated with it.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(branchServiceProvider).deleteBranch(id);
        ref.invalidate(allBranchesProvider);
        ref.invalidate(branchesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Branch deleted successfully'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete branch: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleActive(Branch branch, bool isActive) async {
    try {
      await ref.read(branchServiceProvider).toggleBranch(branch.id, isActive);
      ref.invalidate(allBranchesProvider);
      ref.invalidate(branchesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
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
      appBar: const CustomAppBar(title: 'Manage Branches'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openBranchDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: branchesAsync.when(
        data: (branches) {
          if (branches.isEmpty) {
            return const EmptyState(
              icon: Icons.storefront_rounded,
              title: 'No Branches',
              subtitle: 'Tap the + button to add your first branch office.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allBranchesProvider);
            },
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: ListView.builder(
              padding: const EdgeInsets.all(Spacing.s24),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: branches.length,
              itemBuilder: (context, index) {
                final branch = branches[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: Spacing.s16),
                  child: GlassCard(
                    padding: const EdgeInsets.all(Spacing.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                branch.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Switch.adaptive(
                              value: branch.isActive,
                              activeThumbColor: AppColors.primary,
                              inactiveTrackColor: AppColors.surface,
                              onChanged: (val) => _toggleActive(branch, val),
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacing.s4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                branch.address,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacing.s8),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              branch.contact,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacing.s12),
                        const Divider(color: AppColors.divider, height: 1),
                        const SizedBox(height: Spacing.s12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.edit_rounded, size: 16),
                              label: const Text('Edit'),
                              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                              onPressed: () => _openBranchDialog(branch: branch),
                            ),
                            const SizedBox(width: Spacing.s12),
                            TextButton.icon(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16),
                              label: const Text('Delete'),
                              style: TextButton.styleFrom(foregroundColor: AppColors.error),
                              onPressed: () => _deleteBranch(branch.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(horizontal: Spacing.s24),
          child: LoadingShimmerList(count: 3, itemHeight: 180),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.s24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                const SizedBox(height: Spacing.s16),
                Text('Failed to load branches: $err', style: const TextStyle(color: Colors.white)),
                const SizedBox(height: Spacing.s16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(allBranchesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
