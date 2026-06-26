import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/app_notification.dart';
import '../../providers/providers.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/loading_shimmer.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Notifications',
        actions: [
          notificationsAsync.maybeWhen(
            data: (list) => list.any((n) => !n.isRead)
                ? TextButton(
                    onPressed: () async {
                      try {
                        await ref.read(notificationServiceProvider).markAllAsRead();
                        ref.invalidate(notificationsProvider);
                        ref.invalidate(unreadCountProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All notifications marked as read'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No Notifications',
              subtitle: 'We will notify you here when your queue status changes.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadCountProvider);
            },
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: ListView.builder(
              padding: const EdgeInsets.all(Spacing.s24),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: Spacing.s12),
                  child: Dismissible(
                    key: Key(notification.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: Spacing.s24),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error,
                      ),
                    ),
                    onDismissed: (direction) async {
                      try {
                        await ref
                            .read(notificationServiceProvider)
                            .deleteNotification(notification.id);
                        // No need to reload everything, but invalidate to keep provider in sync
                        ref.invalidate(notificationsProvider);
                        ref.invalidate(unreadCountProvider);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to delete notification: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                    child: GlassCard(
                      onTap: () async {
                        if (!notification.isRead) {
                          try {
                            await ref
                                .read(notificationServiceProvider)
                                .markAsRead(notification.id);
                            ref.invalidate(notificationsProvider);
                            ref.invalidate(unreadCountProvider);
                          } catch (_) {}
                        }
                      },
                      padding: const EdgeInsets.all(Spacing.s16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Type Icon Indicator
                          _buildNotificationIcon(notification.type, notification.isRead),
                          const SizedBox(width: Spacing.s16),

                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: notification.isRead
                                                  ? FontWeight.w500
                                                  : FontWeight.bold,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (!notification.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: Spacing.s4),
                                Text(
                                  notification.message,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: notification.isRead
                                            ? AppColors.textSecondary
                                            : Colors.white.withValues(alpha: 0.9),
                                        height: 1.3,
                                      ),
                                ),
                                const SizedBox(height: Spacing.s8),
                                Text(
                                  _formatTimeAgo(notification.createdAt),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textTertiary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(horizontal: Spacing.s24),
          child: LoadingShimmerList(count: 4, itemHeight: 90),
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
                  'Failed to load notifications: $err',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.s16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(notificationsProvider);
                    ref.invalidate(unreadCountProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type, bool isRead) {
    Color color;
    IconData icon;

    switch (type) {
      case NotificationType.queueUpdate:
        color = AppColors.secondary;
        icon = Icons.queue_music_rounded;
        break;
      case NotificationType.turnReminder:
        color = AppColors.primary;
        icon = Icons.notifications_active_rounded;
        break;
      case NotificationType.delay:
        color = AppColors.warning;
        icon = Icons.hourglass_top_rounded;
        break;
      case NotificationType.completion:
        color = AppColors.success;
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    final opacity = isRead ? 0.15 : 0.25;

    return Container(
      padding: const EdgeInsets.all(Spacing.s8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: isRead ? color.withValues(alpha: 0.6) : color,
        size: 20,
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
