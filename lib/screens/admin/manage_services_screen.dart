import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/service_model.dart';
import '../../providers/providers.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/loading_shimmer.dart';

class ManageServicesScreen extends ConsumerStatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  ConsumerState<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends ConsumerState<ManageServicesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _timeController = TextEditingController();
  String? _selectedBranchId;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _openServiceDialog({ServiceModel? service}) {
    if (_selectedBranchId == null) return;

    if (service != null) {
      _nameController.text = service.name;
      _descController.text = service.description;
      _timeController.text = service.avgServiceTime.toString();
    } else {
      _nameController.clear();
      _descController.clear();
      _timeController.text = '10'; // Default 10 minutes
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
                      service != null ? 'Edit Service' : 'Add New Service',
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
                      decoration: _inputDecoration('Service Name', Icons.settings_suggest_rounded),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: Spacing.s16),

                    // Description Field
                    TextFormField(
                      controller: _descController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration: _inputDecoration('Description', Icons.description_outlined),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: Spacing.s16),

                    // Average Service Time Field
                    TextFormField(
                      controller: _timeController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Avg. Service Time (Minutes)', Icons.access_time_rounded),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Required';
                        final parsed = int.tryParse(val);
                        if (parsed == null || parsed <= 0) return 'Enter a valid positive number';
                        return null;
                      },
                    ),
                    const SizedBox(height: Spacing.s24),

                    StatefulBuilder(
                      builder: (context, setSubState) {
                        return GradientButton(
                          label: service != null ? 'Save Changes' : 'Create Service',
                          isLoading: _isLoading,
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;
                            
                            setSubState(() => _isLoading = true);
                            try {
                              final branchService = ref.read(branchServiceProvider);
                              final avgTime = int.parse(_timeController.text.trim());

                              if (service != null) {
                                await branchService.updateService(
                                  id: service.id,
                                  name: _nameController.text.trim(),
                                  description: _descController.text.trim(),
                                  avgServiceTime: avgTime,
                                );
                              } else {
                                await branchService.createService(
                                  branchId: _selectedBranchId!,
                                  name: _nameController.text.trim(),
                                  description: _descController.text.trim(),
                                  avgServiceTime: avgTime,
                                );
                              }
                              
                              ref.invalidate(allBranchServicesProvider(_selectedBranchId!));
                              ref.invalidate(branchServicesProvider(_selectedBranchId!));
                              
                              if (context.mounted) {
                                Navigator.of(dialogContext).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(service != null
                                        ? 'Service updated successfully'
                                        : 'Service created successfully'),
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

  Future<void> _deleteService(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Service', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this service? All existing queue tokens for this service will also be affected.',
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

    if (confirm == true && mounted && _selectedBranchId != null) {
      try {
        await ref.read(branchServiceProvider).deleteService(id);
        ref.invalidate(allBranchServicesProvider(_selectedBranchId!));
        ref.invalidate(branchServicesProvider(_selectedBranchId!));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service deleted successfully'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete service: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleActive(ServiceModel service, bool isActive) async {
    try {
      await ref.read(branchServiceProvider).toggleService(service.id, isActive);
      if (_selectedBranchId != null) {
        ref.invalidate(allBranchServicesProvider(_selectedBranchId!));
        ref.invalidate(branchServicesProvider(_selectedBranchId!));
      }
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
      appBar: const CustomAppBar(title: 'Manage Services'),
      floatingActionButton: _selectedBranchId != null
          ? FloatingActionButton(
              onPressed: () => _openServiceDialog(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: Column(
        children: [
          // Branch Selector
          Padding(
            padding: const EdgeInsets.all(Spacing.s24),
            child: branchesAsync.when(
              data: (branches) {
                if (branches.isEmpty) {
                  return const EmptyState(
                    icon: Icons.storefront_rounded,
                    title: 'No Branches Available',
                    subtitle: 'Create a branch first to assign services.',
                  );
                }

                if (_selectedBranchId == null && branches.isNotEmpty) {
                  _selectedBranchId = branches.first.id;
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
                        });
                      },
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Text('Error loading branches: $err', style: const TextStyle(color: Colors.white)),
            ),
          ),

          // Services List
          if (_selectedBranchId != null)
            Expanded(
              child: ref.watch(allBranchServicesProvider(_selectedBranchId!)).when(
                    data: (services) {
                      if (services.isEmpty) {
                        return const EmptyState(
                          icon: Icons.settings_suggest_rounded,
                          title: 'No Services',
                          subtitle: 'Tap the + button to add the first queue category.',
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(allBranchServicesProvider(_selectedBranchId!));
                        },
                        color: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: Spacing.s24),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: services.length,
                          itemBuilder: (context, index) {
                            final service = services[index];

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
                                            service.name,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Switch.adaptive(
                                          value: service.isActive,
                                          activeThumbColor: AppColors.primary,
                                          inactiveTrackColor: AppColors.surface,
                                          onChanged: (val) => _toggleActive(service, val),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: Spacing.s4),
                                    Text(
                                      service.description,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: Spacing.s12),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Average Service Time: ${service.avgServiceTime} minutes',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: Spacing.s12),
                                    const Divider(color: AppColors.divider, height: 1),
                                    const SizedBox(height: Spacing.s8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          icon: const Icon(Icons.edit_rounded, size: 16),
                                          label: const Text('Edit'),
                                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                                          onPressed: () => _openServiceDialog(service: service),
                                        ),
                                        const SizedBox(width: Spacing.s12),
                                        TextButton.icon(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                          label: const Text('Delete'),
                                          style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                          onPressed: () => _deleteService(service.id),
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
                    error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
                  ),
            )
          else
            const Expanded(
              child: Center(
                child: Text(
                  'Please select a branch to view and manage its services.',
                  style: TextStyle(color: AppColors.textTertiary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
