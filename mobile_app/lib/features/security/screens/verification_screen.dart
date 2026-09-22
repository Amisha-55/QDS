import 'package:flutter/material.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/models/security_event_model.dart';
import 'package:qds/core/models/security_telemetry.dart';
import 'package:qds/core/services/security_service.dart';
import 'package:qds/core/utils/date_utils.dart';
import 'package:qds/features/security/widgets/threat_detection_card.dart';
import 'package:qds/shared/widgets/app_card.dart';
import 'package:qds/shared/widgets/security_badge.dart';

/// Full-screen inspection interface for a single cryptographic verification record.
///
/// Binds strictly to [SecurityTelemetry] and [SecurityEventModel] produced by
/// the Python research core. Displays real evidence without fabricated metrics.
class VerificationScreen extends StatelessWidget {
  const VerificationScreen({
    super.key,
    this.telemetry,
    this.event,
  });

  final SecurityTelemetry? telemetry;
  final SecurityEventModel? event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final securityColors = context.securityColors;

    final tel = telemetry ??
        event?.telemetry ??
        SecurityService.instance.latestTelemetry ??
        const SecurityTelemetry();

    final status = event?.status ?? SecurityService.mapTelemetryToSecurityStatus(tel);
    final statusColor = securityColors.colorForStatus(status);

    String? packetSigId;
    final packetObj = tel.rawTelemetry['packet'];
    if (packetObj is Map) {
      final payloadObj = packetObj['payload'];
      if (payloadObj is Map) {
        packetSigId = payloadObj['signature_id'] as String?;
      }
    }

    final messageId = event?.messageId ??
        (tel.rawTelemetry['message_id'] as String?) ??
        packetSigId ??
        'Unavailable';

    final timestampStr = event != null
        ? AppDateUtils.formatDateTime(event!.timestamp)
        : (tel.rawTelemetry['timestamp'] != null
            ? tel.rawTelemetry['timestamp'].toString()
            : 'Unavailable');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                securityStatus: status,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(status.icon, color: statusColor, size: 28),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Security Verification',
                                  style: AppTypography.cardTitle.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                      _getFactualSummary(tel, status),
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (status != QdsSecurityStatus.trusted &&
                  status != QdsSecurityStatus.monitoring &&
                  tel.isNotEmpty) ...[
                ThreatDetectionCard(
                  telemetry: tel,
                  status: status,
                  event: event,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message Information',
                      style: AppTypography.cardTitle.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildDataRow(
                      context,
                      label: 'Message ID',
                      value: messageId,
                      isMono: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDataRow(
                      context,
                      label: 'Timestamp',
                      value: timestampStr,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDataRow(
                      context,
                      label: 'Signer',
                      value: tel.displaySigner,
                      isMono: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cryptographic Verification',
                      style: AppTypography.cardTitle.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildCheckRow(
                      context,
                      label: 'Classical Signature',
                      value: tel.displayClassicalSignature,
                      isValid: tel.classicalSignatureValid,
                      subtext: 'Ed25519 asymmetric signature validation',
                    ),
                    const Divider(height: AppSpacing.lg),
                    _buildCheckRow(
                      context,
                      label: 'QDS Verification',
                      value: tel.displayQdsVerification,
                      isValid: tel.qdsValid,
                      subtext: 'Quantum-inspired decoy state fidelity check',
                    ),
                    const Divider(height: AppSpacing.lg),
                    _buildDataRow(
                      context,
                      label: 'QDS Decision',
                      value: tel.qdsDecision ?? 'Unavailable',
                      isMono: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDataRow(
                      context,
                      label: 'Final Decision',
                      value: tel.displayFinalDecision,
                      isMono: true,
                      valueColor: statusColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attack Classification',
                      style: AppTypography.cardTitle.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildCheckRow(
                      context,
                      label: 'Replay Protection',
                      value: tel.displayReplayDetection,
                      isValid: tel.replayDetected == null ? null : !tel.replayDetected!,
                      subtext: 'Nonce and signature ID collision detection',
                    ),
                    const Divider(height: AppSpacing.lg),
                    _buildDataRow(
                      context,
                      label: 'Classified Attack Type',
                      value: tel.displayAttackType,
                      valueColor: tel.likelyAttackType != null &&
                              tel.likelyAttackType != 'NONE' &&
                              tel.likelyAttackType != 'LEGITIMATE'
                          ? securityColors.critical
                          : securityColors.trusted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantum Telemetry',
                      style: AppTypography.cardTitle.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (tel.verificationAccuracy != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Verification Accuracy',
                              style: AppTypography.bodySmall.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            tel.displayVerificationAccuracy,
                            style: AppTypography.cardTitle.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: tel.verificationAccuracy!.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ] else ...[
                      _buildDataRow(
                        context,
                        label: 'Verification Accuracy',
                        value: 'Unavailable',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],

                    _buildDataRow(
                      context,
                      label: 'Quantum Error Rate (QBER)',
                      value: tel.displayErrorRate,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDataRow(
                      context,
                      label: 'Measurement Shots',
                      value: tel.totalShots != null && tel.totalShots! > 0
                          ? '${tel.correctShots ?? 0} / ${tel.totalShots} correct'
                          : 'Unavailable',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDataRow(
                      context,
                      label: 'Quantum Bit Count',
                      value: tel.quantumBitCount != null ? '${tel.quantumBitCount} qubits' : 'Unavailable',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDataRow(
                      context,
                      label: 'Accuracy Threshold',
                      value: tel.displayThreshold,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  'QDS research simulation verification evidence.\nTelemetry generated directly by the Python security core.',
                  style: AppTypography.caption.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  String _getFactualSummary(SecurityTelemetry tel, QdsSecurityStatus status) {
    if (tel.replayDetected == true) {
      return 'Critical: Nonce or signature collision detected. Message packet has been replayed.';
    }
    if (tel.likelyAttackType?.toUpperCase() == 'CHANNEL_ATTACK') {
      return 'Warning: Quantum channel noise or phase distortion detected during decoy state measurement.';
    }
    if (tel.likelyAttackType?.toUpperCase() == 'FORGERY_OR_IMPERSONATION' ||
        tel.likelyAttackType?.toUpperCase() == 'FORGERY') {
      return 'Warning: Classical cryptographic signature failed mathematical verification. Key impersonation suspected.';
    }
    if (tel.classicalSignatureValid == false) {
      return 'Verification anomaly: Classical Ed25519 digital signature is invalid.';
    }
    if (tel.qdsValid == false) {
      return 'Verification anomaly: Quantum-inspired digital signature state could not be validated.';
    }
    if (status == QdsSecurityStatus.trusted) {
      return 'Verified: Classical asymmetric signature and quantum state measurement successfully verified.';
    }
    return 'Security verification completed with status: ${status.label}.';
  }

  Widget _buildCheckRow(
    BuildContext context, {
    required String label,
    required String value,
    required bool? isValid,
    required String subtext,
  }) {
    final theme = Theme.of(context);
    final securityColors = context.securityColors;

    Color iconColor;
    IconData iconData;

    if (isValid == null) {
      iconColor = theme.colorScheme.onSurfaceVariant;
      iconData = Icons.help_outline_rounded;
    } else if (isValid) {
      iconColor = securityColors.trusted;
      iconData = Icons.check_circle_rounded;
    } else {
      iconColor = securityColors.critical;
      iconData = Icons.cancel_rounded;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(iconData, color: iconColor, size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    value,
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 14,
                      color: iconColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtext,
                style: AppTypography.caption.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isMono = false,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: (isMono ? AppTypography.codeMono : AppTypography.bodySmall).copyWith(
              color: valueColor ?? theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
