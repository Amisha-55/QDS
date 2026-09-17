import 'package:flutter/material.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/constants/security_constants.dart';

/// A clean metric widget displaying calculated threat scores and severity levels.
class ThreatScoreMetric extends StatelessWidget {
  const ThreatScoreMetric({
    super.key,
    required this.score,
    this.label = 'Anomaly / Threat Score',
    this.showBar = true,
  });

  /// Score between 0.0 (safe) and 1.0 (critical threat).
  final double score;
  final String label;
  final bool showBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final securityColors = context.securityColors;
    final clampedScore = score.clamp(0.0, 1.0);
    final severity = ThreatSeverity.fromScore(clampedScore);
    final color = securityColors.colorForSeverity(severity);
    final percentage = (clampedScore * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$percentage%',
                  style: AppTypography.metricLarge.copyWith(
                    color: color,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '(${severity.label})',
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (showBar) ...[
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clampedScore,
              minHeight: 6,
              backgroundColor: theme.colorScheme.outlineVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact threat score badge for list items or message headers.
class ThreatScoreBadge extends StatelessWidget {
  const ThreatScoreBadge({
    super.key,
    required this.score,
  });

  final double score;

  @override
  Widget build(BuildContext context) {
    final securityColors = context.securityColors;
    final clampedScore = score.clamp(0.0, 1.0);
    final severity = ThreatSeverity.fromScore(clampedScore);
    final color = securityColors.colorForSeverity(severity);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.badgeRadius),
        border: Border.all(color: color.withValues(alpha: 0.35), width: AppDimensions.borderWidthThin),
      ),
      child: Text(
        'Score: ${(clampedScore * 100).toInt()}% (${severity.label})',
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
