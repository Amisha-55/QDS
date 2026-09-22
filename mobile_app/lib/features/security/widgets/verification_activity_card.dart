import 'package:flutter/material.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/models/security_event_model.dart';
import 'package:qds/shared/widgets/app_card.dart';

/// Renders genuine verification activity aggregates strictly calculated from real [SecurityEventModel] data.
///
/// Returns [SizedBox.shrink] if there are no events to avoid displaying misleading placeholder metrics.
class VerificationActivityCard extends StatelessWidget {
  const VerificationActivityCard({
    super.key,
    required this.events,
  });

  final List<SecurityEventModel> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final securityColors = context.securityColors;

    final verifiedCount = events
        .where((e) => e.status == QdsSecurityStatus.trusted || e.status == QdsSecurityStatus.verified)
        .length;

    final failureCount = events
        .where((e) => e.status == QdsSecurityStatus.verificationFailed)
        .length;

    final threatCount = events
        .where((e) => e.status == QdsSecurityStatus.threatDetected)
        .length;

    final replayCount = events
        .where((e) => e.telemetry?.replayDetected == true || e.attackType.toUpperCase().contains('REPLAY'))
        .length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Verification Activity',
                style: AppTypography.cardTitle.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '${events.length} audited',
                style: AppTypography.caption.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'Verified',
                  count: verifiedCount,
                  color: securityColors.trusted,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'Threats',
                  count: threatCount,
                  color: threatCount > 0 ? securityColors.critical : theme.colorScheme.onSurfaceVariant,
                  icon: Icons.gpp_bad_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'Failures',
                  count: failureCount,
                  color: failureCount > 0 ? securityColors.critical : theme.colorScheme.onSurfaceVariant,
                  icon: Icons.cancel_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'Replays',
                  count: replayCount,
                  color: replayCount > 0 ? securityColors.critical : theme.colorScheme.onSurfaceVariant,
                  icon: Icons.history_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadiusSm),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: AppDimensions.borderWidthThin,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 2),
          Text(
            '$count',
            style: AppTypography.cardTitle.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
