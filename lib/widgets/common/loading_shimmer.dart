import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:equeue/config/theme.dart';

/// A shimmering placeholder widget for loading states.
class LoadingShimmer extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    this.width,
    this.height = 80,
    this.borderRadius = AppRadius.r16,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.primary.withValues(alpha: 0.2),
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// A list of shimmer placeholders for loading list states.
class LoadingShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;
  final double spacing;
  final double borderRadius;

  const LoadingShimmerList({
    super.key,
    this.count = 5,
    this.itemHeight = 88,
    this.spacing = Spacing.s12,
    this.borderRadius = AppRadius.r16,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index < count - 1 ? spacing : 0),
          child: Shimmer.fromColors(
            baseColor: AppColors.surface,
            highlightColor: AppColors.primary.withValues(alpha: 0.15),
            period: Duration(milliseconds: 1500 + (index * 100)),
            child: Container(
              height: itemHeight,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Row(
                children: [
                  const SizedBox(width: Spacing.s16),
                  // Simulated avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                  ),
                  const SizedBox(width: Spacing.s12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title placeholder
                        Container(
                          width: double.infinity,
                          height: 14,
                          margin: const EdgeInsets.only(right: Spacing.s48),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(AppRadius.r4),
                          ),
                        ),
                        const SizedBox(height: Spacing.s8),
                        // Subtitle placeholder
                        Container(
                          width: 120,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(AppRadius.r4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Spacing.s16),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
