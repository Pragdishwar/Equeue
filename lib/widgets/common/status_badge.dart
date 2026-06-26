import 'package:flutter/material.dart';
import 'package:equeue/config/theme.dart';
import 'package:equeue/models/queue_token.dart';

/// A colored pill badge showing the token status with an animated dot indicator.
class StatusBadge extends StatelessWidget {
  final TokenStatus status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  Color get _statusColor {
    switch (status) {
      case TokenStatus.waiting:
        return AppColors.warning;
      case TokenStatus.called:
        return AppColors.primary;
      case TokenStatus.serving:
        return AppColors.secondary;
      case TokenStatus.completed:
        return const Color(0xFF2ED573);
      case TokenStatus.cancelled:
        return AppColors.error;
      case TokenStatus.skipped:
        return const Color(0xFFFF9F43);
      case TokenStatus.noShow:
        return AppColors.textTertiary;
    }
  }

  String get _statusLabel {
    switch (status) {
      case TokenStatus.waiting:
        return 'Waiting';
      case TokenStatus.called:
        return 'Called';
      case TokenStatus.serving:
        return 'Serving';
      case TokenStatus.completed:
        return 'Completed';
      case TokenStatus.cancelled:
        return 'Cancelled';
      case TokenStatus.skipped:
        return 'Skipped';
      case TokenStatus.noShow:
        return 'No Show';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _AnimatedDot(color: _statusColor);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s12,
        vertical: Spacing.s4,
      ),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.15),
        borderRadius: AppRadius.br32,
        border: Border.all(
          color: _statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AnimatedDot(color: _statusColor),
          const SizedBox(width: Spacing.s8),
          Text(
            _statusLabel,
            style: TextStyle(
              color: _statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// A pulsing dot indicator.
class _AnimatedDot extends StatefulWidget {
  final Color color;

  const _AnimatedDot({required this.color});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: _pulseAnimation.value),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _pulseAnimation.value * 0.5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
