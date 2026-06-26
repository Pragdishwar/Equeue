import 'dart:math';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/queue_token.dart';
import '../common/animated_counter.dart';

class QueuePositionIndicator extends StatefulWidget {
  final int position;
  final int total;
  final TokenStatus status;

  const QueuePositionIndicator({
    super.key,
    required this.position,
    required this.total,
    required this.status,
  });

  @override
  State<QueuePositionIndicator> createState() => _QueuePositionIndicatorState();
}

class _QueuePositionIndicatorState extends State<QueuePositionIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    final double targetPercentage = widget.total > 0
        ? (widget.total - widget.position + 1) / widget.total
        : 0.0;

    _progressAnimation = Tween<double>(begin: 0.0, end: targetPercentage).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    _progressController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (_shouldPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  bool get _shouldPulse =>
      widget.status == TokenStatus.called || widget.position == 1;

  @override
  void didUpdateWidget(covariant QueuePositionIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position || oldWidget.total != widget.total) {
      final double targetPercentage = widget.total > 0
          ? (widget.total - widget.position + 1) / widget.total
          : 0.0;

      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: targetPercentage,
      ).animate(
        CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
      );
      _progressController.reset();
      _progressController.forward();
    }

    if (_shouldPulse) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (widget.status) {
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
    final color = _getStatusColor();

    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            if (_shouldPulse)
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 30,
                spreadRadius: 2,
              ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, _) {
            return CustomPaint(
              painter: _PositionArcPainter(
                percentage: _progressAnimation.value,
                color: color,
                trackColor: AppColors.surfaceLight,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.status == TokenStatus.called) ...[
                      const Icon(
                        Icons.campaign_rounded,
                        size: 32,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: Spacing.s4),
                      Text(
                        'Your Turn!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ] else ...[
                      AnimatedCounter(
                        value: widget.position,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            ),
                      ),
                      const SizedBox(height: Spacing.s4),
                      Text(
                        'in line',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: Spacing.s4),
                      Text(
                        'of ${widget.total} tokens',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PositionArcPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color trackColor;

  _PositionArcPainter({
    required this.percentage,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 8;

    // Draw background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(center, radius, trackPaint);

    // Draw progress arc
    if (percentage > 0) {
      final arcPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      final startAngle = -pi / 2;
      final sweepAngle = 2 * pi * percentage;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PositionArcPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
