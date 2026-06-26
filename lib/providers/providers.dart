import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/branch.dart';
import '../models/service_model.dart';
import '../models/queue_token.dart';
import '../models/app_notification.dart';
import '../services/auth_service.dart';
import '../services/queue_service.dart';
import '../services/branch_service.dart';
import '../services/notification_service.dart';

// ── Core Service Providers ──────────────────────────────────────────────────

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

final queueServiceProvider = Provider<QueueService>((ref) {
  return QueueService(ref.watch(supabaseClientProvider));
});

final branchServiceProvider = Provider<BranchService>((ref) {
  return BranchService(ref.watch(supabaseClientProvider));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(supabaseClientProvider));
});

// ── Auth Providers ──────────────────────────────────────────────────────────

final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  if (!authService.isAuthenticated) return null;
  return await authService.getProfile();
});

final isAdminProvider = Provider<bool>((ref) {
  final profile = ref.watch(currentProfileProvider).valueOrNull;
  return profile?.isAdmin ?? false;
});

// ── Queue Providers ─────────────────────────────────────────────────────────

final userActiveTokensProvider = FutureProvider<List<QueueToken>>((ref) async {
  final queueService = ref.watch(queueServiceProvider);
  return await queueService.getUserActiveTokens();
});

final userTokenHistoryProvider = FutureProvider<List<QueueToken>>((ref) async {
  final queueService = ref.watch(queueServiceProvider);
  return await queueService.getUserTokenHistory();
});

final tokenByIdProvider =
    FutureProvider.family<QueueToken?, String>((ref, tokenId) async {
  final queueService = ref.watch(queueServiceProvider);
  return await queueService.getToken(tokenId);
});

final queueStatsProvider = FutureProvider<QueueStats>((ref) async {
  final queueService = ref.watch(queueServiceProvider);
  return await queueService.getQueueStats();
});

final serviceQueueProvider =
    FutureProvider.family<List<QueueToken>, String>((ref, serviceId) async {
  final queueService = ref.watch(queueServiceProvider);
  return await queueService.getQueueForService(serviceId);
});

final currentServingProvider =
    FutureProvider.family<QueueToken?, String>((ref, serviceId) async {
  final queueService = ref.watch(queueServiceProvider);
  return await queueService.getCurrentServing(serviceId);
});

final completedTodayProvider =
    FutureProvider.family<List<QueueToken>, String>((ref, serviceId) async {
  final queueService = ref.watch(queueServiceProvider);
  return await queueService.getCompletedToday(serviceId);
});

// ── Branch Providers ────────────────────────────────────────────────────────

final branchesProvider = FutureProvider<List<Branch>>((ref) async {
  final branchService = ref.watch(branchServiceProvider);
  return await branchService.getBranches();
});

final allBranchesProvider = FutureProvider<List<Branch>>((ref) async {
  final branchService = ref.watch(branchServiceProvider);
  return await branchService.getAllBranches();
});

final branchByIdProvider =
    FutureProvider.family<Branch?, String>((ref, branchId) async {
  final branchService = ref.watch(branchServiceProvider);
  return await branchService.getBranch(branchId);
});

final branchServicesProvider =
    FutureProvider.family<List<ServiceModel>, String>((ref, branchId) async {
  final branchService = ref.watch(branchServiceProvider);
  return await branchService.getServicesForBranch(branchId);
});

final allBranchServicesProvider =
    FutureProvider.family<List<ServiceModel>, String>((ref, branchId) async {
  final branchService = ref.watch(branchServiceProvider);
  return await branchService.getAllServicesForBranch(branchId);
});

// ── Notification Providers ──────────────────────────────────────────────────

final notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  final notifService = ref.watch(notificationServiceProvider);
  return await notifService.getNotifications();
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  final notifService = ref.watch(notificationServiceProvider);
  return await notifService.getUnreadCount();
});
