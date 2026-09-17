import 'package:flutter/material.dart';
import 'package:qds/app/routes.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/models/security_telemetry.dart';
import 'package:qds/core/services/security_service.dart';
import 'package:qds/shared/widgets/security_badge.dart';

/// Reusable modal sheet displaying factual, evidence-based cryptographic verification details.
///
/// Binds strictly to [SecurityTelemetry] received from the Python research core.
class MessageSecurityDetailsSheet extends StatelessWidget {
  const MessageSecurityDetailsSheet({
    super.key,
    required this.telemetry,
    this.messageSnippet,
  });

  final SecurityTelemetry telemetry;
  final String? messageSnippet;

  static Future<void> show(
    BuildContext context, {
    required SecurityTelemetry telemetry,
    String? messageSnippet,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MessageSecurityDetailsSheet(
        telemetry: telemetry,
        messageSnippet: messageSnippet,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = SecurityService.mapTelemetryToSecurityStatus(telemetry);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.cardRadiusLg)),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            width: AppDimensions.borderWidthThin,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        left: AppDimensions.screenPadding,
        right: AppDimensions.screenPadding,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Verification Details',
                style: AppTypography.sectionHeading.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SecurityBadge(
                status: status,
                variant: SecurityBadgeVariant.compact,
              ),
            ],
          ),
          if (messageSnippet != null && messageSnippet!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '"$messageSnippet"',
              style: AppTypography.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _buildTelemetryRow(
            context,
            label: 'Security Status',
            value: status.label,
            valueColor: context.securityColors.colorForStatus(status),
            isBold: true,
          ),
          _buildDivider(theme),

          _buildTelemetryRow(
            context,
            label: 'Attack Type',
            value: telemetry.displayAttackType,
            valueColor: telemetry.likelyAttackType != null &&
                    telemetry.likelyAttackType != 'NONE' &&
                    telemetry.likelyAttackType != 'LEGITIMATE'
                ? context.securityColors.critical
                : null,
          ),
          _buildDivider(theme),

          _buildTelemetryRow(
            context,
            label: 'Classical Signature',
            value: telemetry.displayClassicalSignature,
            valueColor: telemetry.classicalSignatureValid == false
                ? context.securityColors.critical
                : null,
          ),
          _buildDivider(theme),

          _buildTelemetryRow(
            context,
            label: 'QDS Verification',
            value: telemetry.displayQdsVerification,
            valueColor: telemetry.qdsValid == false
                ? context.securityColors.critical
                : null,
          ),
          _buildDivider(theme),

          _buildTelemetryRow(
            context,
            label: 'Replay Detection',
            value: telemetry.displayReplayDetection,
            valueColor: telemetry.replayDetected == true
                ? context.securityColors.critical
                : null,
          ),

          if (telemetry.verificationAccuracy != null) ...[
            _buildDivider(theme),
            _buildTelemetryRow(
              context,
              label: 'Verification Accuracy',
              value: telemetry.displayVerificationAccuracy,
            ),
          ],

          if (telemetry.errorRate != null) ...[
            _buildDivider(theme),
            _buildTelemetryRow(
              context,
              label: 'Error Rate',
              value: telemetry.displayErrorRate,
            ),
          ],

          if (telemetry.totalShots != null && telemetry.totalShots! > 0) ...[
            _buildDivider(theme),
            _buildTelemetryRow(
              context,
              label: 'Quantum Verification',
              value: '${telemetry.correctShots ?? 0} / ${telemetry.totalShots} correct',
            ),
          ],

          if (telemetry.threshold != null) ...[
            _buildDivider(theme),
            _buildTelemetryRow(
              context,
              label: 'Threshold',
              value: telemetry.displayThreshold,
            ),
          ],

          if (telemetry.signerId != null && telemetry.signerId!.isNotEmpty) ...[
            _buildDivider(theme),
            _buildTelemetryRow(
              context,
              label: 'Signer',
              value: telemetry.displaySigner,
              isMono: true,
            ),
          ],

          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.verified_user_outlined, size: 18),
              label: const Text('View Full Verification Details'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(
                  context,
                  AppRoutes.verificationDetails,
                  arguments: telemetry,
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildTelemetryRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
    bool isMono = false,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: (isMono ? AppTypography.codeMono : AppTypography.bodySmall).copyWith(
                color: valueColor ?? theme.colorScheme.onSurface,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: theme.colorScheme.outline.withValues(alpha: 0.15),
    );
  }
}
