import 'package:flutter/material.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/shared/animations/security_animation.dart';
import 'package:qds/shared/widgets/app_card.dart';
import 'package:qds/shared/widgets/security_badge.dart';

/// A card summarizing security status for the home dashboard.
class SecurityStatusCard extends StatelessWidget {
  const SecurityStatusCard({
    super.key,
    this.status = QdsSecurityStatus.trusted,
    this.title = 'Quantum Signature Active',
    this.subtitle = 'Dilithium3 / PQC-Hybrid verification verified intact',
    this.onTap,
    this.trailing,
  });

  final QdsSecurityStatus status;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final securityColors = context.securityColors;
    final statusColor = securityColors.colorForStatus(status);

    return AppCard(
      onTap: onTap,
      securityStatus: status,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SecurityBadge(
                status: status,
                variant: SecurityBadgeVariant.compact,
              ),
              const Spacer(),
              SecurityStatusDot(
                color: statusColor,
                isPulsing: status.isThreat || status == QdsSecurityStatus.monitoring,
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTypography.cardTitle.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
