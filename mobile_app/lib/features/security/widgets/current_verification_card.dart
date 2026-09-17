import 'package:flutter/material.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/models/security_telemetry.dart';
import 'package:qds/shared/widgets/app_card.dart';
import 'package:qds/shared/widgets/security_badge.dart';

/// A card displaying the most recent verification outcome.
///
/// Binds strictly to [SecurityTelemetry] and [QdsSecurityStatus] with no fabricated metrics.
class CurrentVerificationCard extends StatelessWidget {
  const CurrentVerificationCard({
    super.key,
    this.telemetry,
    this.status = QdsSecurityStatus.monitoring,
    this.onViewDetails,
  });

  final SecurityTelemetry? telemetry;
  final QdsSecurityStatus status;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = telemetry != null && telemetry!.isNotEmpty;

    if (!hasData) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 22,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No verified messages yet',
                      style: AppTypography.cardTitle.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cryptographic verification telemetry will appear here once messages are exchanged.',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final tel = telemetry!;
    final summaryText = _getSummaryText(tel, status);

    return AppCard(
      securityStatus: status,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest Verification',
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            summaryText,
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          _buildRow(
            context,
            label: 'Classical Signature',
            value: tel.displayClassicalSignature,
            isWarning: tel.classicalSignatureValid == false,
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildRow(
            context,
            label: 'QDS Verification',
            value: tel.displayQdsVerification,
            isWarning: tel.qdsValid == false,
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildRow(
            context,
            label: 'Replay Detection',
            value: tel.displayReplayDetection,
            isWarning: tel.replayDetected == true,
          ),

          if (tel.verificationAccuracy != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _buildRow(
              context,
              label: 'Verification Accuracy',
              value: tel.displayVerificationAccuracy,
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: onViewDetails,
            borderRadius: BorderRadius.circular(AppDimensions.cardRadiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'View verification details',
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSummaryText(SecurityTelemetry tel, QdsSecurityStatus status) {
    if (tel.replayDetected == true) {
      return 'Cryptographic signature replay detected for latest packet.';
    }
    if (tel.likelyAttackType?.toUpperCase() == 'CHANNEL_ATTACK') {
      return 'Quantum channel noise or manipulation detected.';
    }
    if (tel.likelyAttackType?.toUpperCase() == 'FORGERY_OR_IMPERSONATION') {
      return 'Possible signature forgery or impersonation detected.';
    }
    if (tel.classicalSignatureValid == false) {
      return 'Classical Ed25519 signature validation failed.';
    }
    if (tel.qdsValid == false) {
      return 'Quantum-inspired digital signature could not be verified.';
    }
    if (status == QdsSecurityStatus.trusted) {
      return 'Message verified successfully with quantum integrity.';
    }
    return 'Verification completed with status: ${status.label}.';
  }

  Widget _buildRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isWarning = false,
  }) {
    final theme = Theme.of(context);
    final securityColors = context.securityColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: AppTypography.caption.copyWith(
            color: isWarning ? securityColors.critical : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
