import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/queue_token.dart';
import '../common/glass_card.dart';
import '../common/status_badge.dart';

class QueueListItem extends StatelessWidget {
  final QueueToken token;
  final VoidCallback? onCall;
  final VoidCallback? onSkip;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;

  const QueueListItem({
    super.key,
    required this.token,
    this.onCall,
    this.onSkip,
    this.onCancel,
    this.onComplete,
  });

  bool get _hasActions =>
      onCall != null || onSkip != null || onCancel != null || onComplete != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.s12),
      child: GlassCard(
        padding: const EdgeInsets.all(Spacing.s12),
        child: Row(
          children: [
            // Leading Position Circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  token.position > 0 ? '${token.position}' : '#',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            const SizedBox(width: Spacing.s12),

            // Middle Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    token.tokenNumber,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        token.userName ?? 'Walk-in Customer',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(status: token.status),
                    ],
                  ),
                ],
              ),
            ),

            // Trailing Actions or Info
            if (_hasActions) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onCall != null && token.status == TokenStatus.waiting)
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                      tooltip: 'Call Next',
                      onPressed: onCall,
                    ),
                  if (onComplete != null && token.status == TokenStatus.called)
                    IconButton(
                      icon: const Icon(Icons.check_circle_rounded, color: AppColors.success),
                      tooltip: 'Complete',
                      onPressed: onComplete,
                    ),
                  if (onSkip != null && (token.status == TokenStatus.waiting || token.status == TokenStatus.called))
                    IconButton(
                      icon: const Icon(Icons.redo_rounded, color: AppColors.warning),
                      tooltip: 'Skip',
                      onPressed: onSkip,
                    ),
                  if (onCancel != null && token.status == TokenStatus.waiting)
                    IconButton(
                      icon: const Icon(Icons.cancel_rounded, color: AppColors.error),
                      tooltip: 'Cancel',
                      onPressed: onCancel,
                    ),
                ],
              ),
            ] else ...[
              Text(
                '~${token.estimatedWaitMinutes}m wait',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
