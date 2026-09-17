import 'package:flutter/material.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/models/security_event_model.dart';
import 'package:qds/core/models/security_telemetry.dart';
import 'package:qds/features/security/utils/attack_presentation_helper.dart';
import 'package:qds/shared/widgets/app_card.dart';
import 'package:qds/shared/widgets/security_badge.dart';

/// Reusable card displaying detailed attack evidence, classified attack type,
/// factual detection rationale, and navigation to full verification details.
///
/// Designed to handle all attack categories:
/// - Replay
/// - Forgery / Impersonation
/// - Channel Attack
/// - Classical / QDS verification failures
class ThreatDetectionCard extends StatelessWidget {
  const ThreatDetectionCard({
    super.key,
    required this.telemetry,
    required this.status,
    this.event,
    this.onViewDetails,
  });

  final SecurityTelemetry telemetry;
  final QdsSecurityStatus status;
  final SecurityEventModel? event;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final securityColors = context.securityColors;
    final statusColor = securityColors.colorForStatus(status);

    final rawAttackType = event?.attackType ?? telemetry.likelyAttackType ?? 'UNKNOWN';
    final formattedAttackType = AttackPresentationHelper.formatAttackType(rawAttackType);
    final attackIcon = AttackPresentationHelper.getAttackIcon(rawAttackType, status);
    final explanation = AttackPresentationHelper.getFactualExplanation(telemetry, status);

    return AppCard(
      securityStatus: status,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        attackIcon,
                        color: statusColor,
                        size: 20,
                        semanticLabel: status.label,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.label.toUpperCase(),
                            style: AppTypography.cardTitle.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            formattedAttackType,
                            style: AppTypography.cardTitle.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              SecurityBadge(
                status: status,
                variant: SecurityBadgeVariant.compact,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            explanation,
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          ..._buildEvidenceRows(context, rawAttackType),
          const SizedBox(height: AppSpacing.md),
          if (onViewDetails != null)
            InkWell(
              onTap: onViewDetails,
              borderRadius: BorderRadius.circular(AppDimensions.cardRadiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'View Verification Details',
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

  List<Widget> _buildEvidenceRows(BuildContext context, String rawAttackType) {
    final normalized = rawAttackType.toUpperCase();

    if (telemetry.replayDetected == true || normalized.contains('REPLAY')) {
      return [
        _buildRow(context, label: 'Attack Classification', value: telemetry.likelyAttackType ?? 'REPLAY', isMono: true),
        const SizedBox(height: AppSpacing.xs),
        _buildRow(
          context,
          label: 'Replay Detection',
          value: telemetry.replayDetected == null
              ? 'Unavailable'
              : (telemetry.replayDetected! ? 'Detected' : 'Not detected'),
          isWarning: telemetry.replayDetected == true,
        ),
        const SizedBox(height: AppSpacing.xs),
        _buildRow(context, label: 'Signer', value: telemetry.displaySigner, isMono: true),
        const SizedBox(height: AppSpacing.xs),
        _buildRow(context, label: 'Final Decision', value: telemetry.displayFinalDecision, isWarning: true),
      ];
    }

    if (normalized.contains('FORGERY') || normalized.contains('IMPERSONATION')) {
      return [
        _buildRow(context, label: 'Attack Classification', value: telemetry.likelyAttackType ?? 'FORGERY_OR_IMPERSONATION', isMono: true),
        const SizedBox(height: AppSpacing.xs),
        _buildRow(context, label: 'Classical Signature', value: telemetry.displayClassicalSignature, isWarning: telemetry.classicalSignatureValid == false),
        const SizedBox(height: AppSpacing.xs),
        _buildRow(context, label: 'QDS Verification', value: telemetry.displayQdsVerification, isWarning: telemetry.qdsValid == false),
        const SizedBox(height: AppSpacing.xs),
        _buildRow(context, label: 'Signer', value: telemetry.displaySigner, isMono: true),
        const SizedBox(height: AppSpacing.xs),
        _buildRow(context, label: 'Final Decision', value: telemetry.displayFinalDecision, isWarning: true),
      ];
    }

    if (normalized.contains('CHANNEL')) {
      return [
        _buildRow(context, label: 'Attack Classification', value: telemetry.likelyAttackType ?? 'CHANNEL_ATTACK', isMono: true),
        const SizedBox(height: AppSpacing.xs),
        _buildRow(context, label: 'QDS Verification', value: telemetry.displayQdsVerification, isWarning: telemetry.qdsValid == false),
        const SizedBox(height: AppSpacing.xs),
        _buildRow(context, label: 'Verification Accuracy', value: telemetry.displayVerificationAccuracy, isWarning: true),
        const SizedBox(height: AppSpacing.xs),
        _buildRow(context, label: 'Quantum Error Rate', value: telemetry.displayErrorRate, isWarning: true),
        const SizedBox(height: AppSpacing.xs),
        _buildRow(context, label: 'Accuracy Threshold', value: telemetry.displayThreshold),
        const SizedBox(height: AppSpacing.xs),
        _buildRow(context, label: 'Classical Signature', value: telemetry.displayClassicalSignature),
      ];
    }

    return [
      _buildRow(context, label: 'Attack Classification', value: telemetry.likelyAttackType ?? rawAttackType, isMono: true),
      const SizedBox(height: AppSpacing.xs),
      _buildRow(context, label: 'Classical Signature', value: telemetry.displayClassicalSignature, isWarning: telemetry.classicalSignatureValid == false),
      const SizedBox(height: AppSpacing.xs),
      _buildRow(context, label: 'QDS Verification', value: telemetry.displayQdsVerification, isWarning: telemetry.qdsValid == false),
      const SizedBox(height: AppSpacing.xs),
      _buildRow(context, label: 'Final Decision', value: telemetry.displayFinalDecision, isWarning: true),
    ];
  }

  Widget _buildRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isWarning = false,
    bool isMono = false,
  }) {
    final theme = Theme.of(context);
    final securityColors = context.securityColors;

    final valueColor = isWarning
        ? securityColors.critical
        : theme.colorScheme.onSurface;

    final baseStyle = isMono ? AppTypography.codeMono : AppTypography.bodySmall;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            style: baseStyle.copyWith(
              color: valueColor,
              fontWeight: isWarning ? FontWeight.w700 : FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
