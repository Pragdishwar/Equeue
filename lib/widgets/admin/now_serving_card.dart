import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/queue_token.dart';
import '../common/glass_card.dart';

class NowServingCard extends StatefulWidget {
  final QueueToken? token;

  const NowServingCard({
    super.key,
    required this.token,
  });

  @override
  State<NowServingCard> createState() => _NowServingCardState();
}

class _NowServingCardState extends State<NowServingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _glowAnimation = Tween<double>(begin: 4.0, end: 16.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.token != null) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant NowServingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.token != null) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.token == null) {
      return GlassCard(
        padding: const EdgeInsets.symmetric(vertical: Spacing.s32, horizontal: Spacing.s16),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.desktop_access_disabled_rounded,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: Spacing.s12),
              Text(
                'No Active Customer',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: Spacing.s4),
              Text(
                'Call the next customer from the queue below.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final token = widget.token!;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: _glowAnimation.value,
                spreadRadius: _glowAnimation.value / 4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: GlassCard(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        padding: const EdgeInsets.all(Spacing.s24),
        child: Column(
          children: [
            // Subtitle header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.s12, vertical: Spacing.s4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'NOW SERVING',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            const SizedBox(height: Spacing.s20),
            // Token Number
            Text(
              token.tokenNumber,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    fontSize: 48,
                  ),
            ),
            const SizedBox(height: Spacing.s8),
            // Service Name
            Text(
              token.serviceName ?? 'General Queue',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: Spacing.s16),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: Spacing.s16),
            // Customer Meta
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMeta(
                  context,
                  Icons.person_rounded,
                  token.userName ?? 'Walk-in',
                  'Customer',
                ),
                _buildMeta(
                  context,
                  Icons.timer_rounded,
                  '${token.estimatedWaitMinutes} min',
                  'Est. Service Time',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeta(BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}
