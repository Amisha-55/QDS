import 'package:flutter/material.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/shared/widgets/app_card.dart';
import 'package:qds/shared/widgets/security_badge.dart';

/// Card summarizing a digital signature verification record.
class VerificationCard extends StatelessWidget {
  const VerificationCard({
    super.key,
    required this.algorithm,
    required this.keyFingerprint,
    required this.timestamp,
    required this.status,
    this.latencyMs,
  });

  final String algorithm;
  final String keyFingerprint;
  final String timestamp;
  final QdsSecurityStatus status;
  final int? latencyMs;

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
                'Signature Verification',
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
          _buildRow(
            context,
            label: 'Algorithm',
            value: algorithm,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRow(
            context,
            label: 'Key Fingerprint',
            value: keyFingerprint,
            isMono: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRow(
            context,
            label: 'Verification Timestamp',
            value: timestamp,
          ),
          if (latencyMs != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildRow(
              context,
              label: 'Execution Time',
              value: '$latencyMs ms',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isMono = false,
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
          style: (isMono ? AppTypography.codeMono : AppTypography.bodySmall).copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
