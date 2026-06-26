import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/queue_token.dart';
import '../common/glass_card.dart';
import '../common/status_badge.dart';
import 'estimated_wait.dart';

class TokenCard extends StatelessWidget {
  final QueueToken token;
  final VoidCallback? onTap;
  final bool showActions;

  const TokenCard({
    super.key,
    required this.token,
    this.onTap,
    this.showActions = false,
  });

  Color _getStatusColor() {
    switch (token.status) {
      case TokenStatus.waiting:
        return AppColors.warning;
      case TokenStatus.called:
        return AppColors.primary;
      case TokenStatus.serving:
        return AppColors.secondary;
      case TokenStatus.completed:
        return AppColors.success;
      case TokenStatus.cancelled:
        return AppColors.error;
      case TokenStatus.skipped:
      case TokenStatus.noShow:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.s16),
      child: Stack(
        children: [
          GlassCard(
            onTap: onTap,
            padding: const EdgeInsets.all(Spacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Hero(
                      tag: 'token_num_${token.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          token.tokenNumber,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ),
                    ),
                    StatusBadge(status: token.status),
                  ],
                ),
                const SizedBox(height: Spacing.s12),
                Text(
                  token.serviceName ?? 'Queue Service',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: Spacing.s4),
                Row(
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        token.branchName ?? 'Main Branch',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.s16),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: Spacing.s12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (token.status == TokenStatus.waiting || token.status == TokenStatus.called) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.groups_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            token.position == 1
                                ? 'Next in line'
                                : '${token.position} people ahead',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                      EstimatedWait(
                        minutes: token.estimatedWaitMinutes ?? 0,
                        compact: true,
                      ),
                    ] else ...[
                      Text(
                        'Created on ${_formatDate(token.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                      ),
                      if (token.completedAt != null)
                        Text(
                          'Completed at ${_formatTime(token.completedAt!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 16,
            bottom: 16,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = local.minute.toString().padLeft(2, '0');
    return '$hour:$minuteStr $ampm';
  }
}
