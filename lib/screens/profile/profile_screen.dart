import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/user_profile.dart';
import '../../providers/providers.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    
    // Seed initial values from current profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(currentProfileProvider).valueOrNull;
      if (profile != null) {
        _nameController.text = profile.fullName;
        _phoneController.text = profile.phone;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).updateProfile(
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
          );
      
      ref.invalidate(currentProfileProvider);
      
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out of Equeue?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(authServiceProvider).signOut();
        // Invalidate auth-related providers
        ref.invalidate(currentProfileProvider);
        if (mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to sign out: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Profile',
        actions: [
          profileAsync.maybeWhen(
            data: (profile) {
              if (profile == null) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(
                  _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  setState(() {
                    if (_isEditing) {
                      // Reset values
                      _nameController.text = profile.fullName;
                      _phoneController.text = profile.phone;
                    }
                    _isEditing = !_isEditing;
                  });
                },
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Please log in.'));
          }

          // If controllers were not seeded yet, seed them
          if (!_isEditing && _nameController.text.isEmpty) {
            _nameController.text = profile.fullName;
            _phoneController.text = profile.phone;
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.s24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar & Meta Info
                    _buildAvatarSection(profile),
                    const SizedBox(height: Spacing.s32),

                    // User Details Form
                    GlassCard(
                      padding: const EdgeInsets.all(Spacing.s20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Information',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: Spacing.s16),
                          
                          // Full Name
                          TextFormField(
                            controller: _nameController,
                            enabled: _isEditing,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: const Icon(Icons.person_outline),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                              ),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Name is required'
                                : null,
                          ),
                          const SizedBox(height: Spacing.s16),

                          // Email (Disabled always)
                          TextFormField(
                            initialValue: profile.email,
                            enabled: false,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: const Icon(Icons.mail_outline),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                              ),
                            ),
                          ),
                          const SizedBox(height: Spacing.s16),

                          // Phone
                          TextFormField(
                            controller: _phoneController,
                            enabled: _isEditing,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: const Icon(Icons.phone_outlined),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                              ),
                            ),
                            validator: (val) => val == null || val.trim().length < 10
                                ? 'Enter a valid 10-digit phone number'
                                : null,
                          ),

                          if (_isEditing) ...[
                            const SizedBox(height: Spacing.s24),
                            GradientButton(
                              label: 'Save Changes',
                              onPressed: _saveProfile,
                              isLoading: _isLoading,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.s20),

                    // App Settings / Notification preferences
                    GlassCard(
                      padding: const EdgeInsets.all(Spacing.s20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preferences',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: Spacing.s8),
                          SwitchListTile(
                            title: const Text('Push Notifications', style: TextStyle(color: Colors.white)),
                            subtitle: const Text('Receive turn reminders and status updates', style: TextStyle(color: AppColors.textTertiary)),
                            value: _pushNotifications,
                            activeThumbColor: AppColors.primary,
                            inactiveTrackColor: AppColors.surface,
                            onChanged: (val) {
                              setState(() => _pushNotifications = val);
                            },
                          ),
                          SwitchListTile(
                            title: const Text('Email Updates', style: TextStyle(color: Colors.white)),
                            subtitle: const Text('Receive daily queue summary and reports', style: TextStyle(color: AppColors.textTertiary)),
                            value: _emailNotifications,
                            activeThumbColor: AppColors.primary,
                            inactiveTrackColor: AppColors.surface,
                            onChanged: (val) {
                              setState(() => _emailNotifications = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.s20),

                    // Admin view quick toggle if user is admin
                    if (profile.isAdmin) ...[
                      GlassCard(
                        padding: const EdgeInsets.all(Spacing.s20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Options',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: Spacing.s12),
                            Text(
                              'You have administrator access. Switch to the dashboard to manage queues and services.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: Spacing.s16),
                            GradientButton(
                              label: 'Go to Admin Dashboard',
                              onPressed: () => context.go('/admin'),
                              gradient: const LinearGradient(
                                colors: [AppColors.secondary, AppColors.primary],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.s20),
                    ],

                    // Sign Out and App Info
                    TextButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                      label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.s24,
                          vertical: Spacing.s12,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.s16),
                    const Text(
                      'Equeue v1.0.0 (Phase 1 MVP)',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                    ),
                    const SizedBox(height: Spacing.s24),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(UserProfile profile) {
    final initials = profile.fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials.isNotEmpty ? initials : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.s16),
        Text(
          profile.fullName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: Spacing.s4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: profile.isAdmin 
                ? AppColors.primary.withValues(alpha: 0.15) 
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: profile.isAdmin 
                  ? AppColors.primary.withValues(alpha: 0.3) 
                  : AppColors.border,
              width: 1,
            ),
          ),
          child: Text(
            profile.role.value.toUpperCase(),
            style: TextStyle(
              color: profile.isAdmin ? AppColors.primary : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}
