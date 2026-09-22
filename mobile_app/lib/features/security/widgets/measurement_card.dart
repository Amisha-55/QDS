import 'package:flutter/material.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/shared/widgets/app_card.dart';

/// Telemetry card displaying signature measurement and statistical telemetry.
class MeasurementCard extends StatelessWidget {
  const MeasurementCard({
    super.key,
    required this.sampleSize,
    required this.phaseDrift,
    required this.errorRate,
    required this.threshold,
  });

  final int sampleSize;
  final double phaseDrift;
  final double errorRate;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final securityColors = context.securityColors;
    final isWithinThreshold = errorRate <= threshold;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Channel Measurements',
            style: AppTypography.cardTitle.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildRow(
            context,
            label: 'Sample Points Analyzed',
            value: '$sampleSize samples',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRow(
            context,
            label: 'Estimated Phase Drift',
            value: '${(phaseDrift * 1000).toStringAsFixed(2)} mrad',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRow(
            context,
            label: 'Quantum Bit Error Rate (QBER)',
            value: '${(errorRate * 100).toStringAsFixed(3)}%',
            valueColor: isWithinThreshold ? securityColors.trusted : securityColors.critical,
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Tolerance limit: ${(threshold * 100).toStringAsFixed(1)}%',
              style: AppTypography.caption.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: AppTypography.codeMono.copyWith(
            color: valueColor ?? theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
