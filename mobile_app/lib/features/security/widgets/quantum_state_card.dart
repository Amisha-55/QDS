import 'package:flutter/material.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/shared/widgets/app_card.dart';
import 'package:qds/shared/widgets/security_badge.dart';

/// Technical telemetry card displaying simulated quantum-inspired state properties.
class QuantumStateCard extends StatelessWidget {
  const QuantumStateCard({
    super.key,
    required this.entropy,
    required this.fidelity,
    required this.stateVectorDimension,
    this.status = QdsSecurityStatus.verified,
  });

  final double entropy;
  final double fidelity;
  final int stateVectorDimension;
  final QdsSecurityStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      securityStatus: status,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quantum State Telemetry',
                style: AppTypography.cardTitle.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SecurityBadge(
                status: status,
                variant: SecurityBadgeVariant.compact,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildMetricRow(
            context,
            label: 'Von Neumann Entropy',
            value: entropy.toStringAsFixed(4),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildMetricRow(
            context,
            label: 'State Fidelity',
            value: '${(fidelity * 100).toStringAsFixed(2)}%',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildMetricRow(
            context,
            label: 'Hilbert Dimension',
            value: '2^$stateVectorDimension ($stateVectorDimension-qubit simulated)',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context, {
    required String label,
    required String value,
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
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
