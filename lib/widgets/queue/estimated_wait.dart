import 'package:flutter/material.dart';
import '../../config/theme.dart';

class EstimatedWait extends StatelessWidget {
  final int minutes;
  final bool compact;

  const EstimatedWait({
    super.key,
    required this.minutes,
    this.compact = false,
  });

  Color _getWaitColor(int mins) {
    if (mins < 15) return AppColors.success;
    if (mins < 30) return AppColors.warning;
    return AppColors.error;
  }

  String _formatWaitTime(int mins) {
    if (mins <= 0) return 'Immediate';
    if (mins < 60) return '$mins min';
    final hours = mins ~/ 60;
    final remainingMins = mins % 60;
    if (remainingMins == 0) {
      return '$hours hr${hours > 1 ? 's' : ''}';
    }
    return '$hours hr $remainingMins min';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getWaitColor(minutes);
    final timeText = _formatWaitTime(minutes);

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            timeText,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Estimated Wait',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                timeText,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
