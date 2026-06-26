import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/theme.dart';
import '../common/glass_card.dart';

class QRDisplay extends StatelessWidget {
  final String data;
  final double size;
  final String tokenNumber;

  const QRDisplay({
    super.key,
    required this.data,
    this.size = 180,
    required this.tokenNumber,
  });

  void _showEnlargedQR(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(Spacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Token $tokenNumber',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.s16),
              Container(
                padding: const EdgeInsets.all(Spacing.s16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 240,
                  gapless: false,
                  errorStateBuilder: (cxt, err) {
                    return const Center(
                      child: Text(
                        'Failed to generate QR code.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: Spacing.s16),
              Text(
                'Show this QR code at the counter',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _showEnlargedQR(context),
          child: GlassCard(
            padding: const EdgeInsets.all(Spacing.s16),
            child: Container(
              padding: const EdgeInsets.all(Spacing.s12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: data,
                version: QrVersions.auto,
                size: size,
                gapless: false,
                errorStateBuilder: (cxt, err) {
                  return const SizedBox(
                    width: 140,
                    height: 140,
                    child: Center(
                      child: Text(
                        'Error',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.s12),
        Text(
          'Token: $tokenNumber',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: Spacing.s4),
        Text(
          'Tap QR code to enlarge',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
        ),
      ],
    );
  }
}
