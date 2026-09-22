import 'package:flutter/material.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/models/user_model.dart';
import 'package:qds/shared/widgets/security_badge.dart';

/// Compact and clear app bar for chat conversations.
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBar({
    super.key,
    required this.peerName,
    required this.peerRole,
    this.securityStatus = QdsSecurityStatus.trusted,
    this.onInfoPressed,
    this.onBackPressed,
  });

  final String peerName;
  final UserRole peerRole;
  final QdsSecurityStatus securityStatus;
  final VoidCallback? onInfoPressed;
  final VoidCallback? onBackPressed;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Back',
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: AppDimensions.borderWidthThin,
              ),
            ),
            child: Center(
              child: Text(
                peerRole.code,
                style: AppTypography.cardTitle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  peerName,
                  style: AppTypography.cardTitle.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${peerRole.code} • ${peerRole.label}',
                  style: AppTypography.caption.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: SecurityBadge(
              status: securityStatus,
              variant: SecurityBadgeVariant.compact,
            ),
          ),
        ),
        if (onInfoPressed != null)
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Conversation details',
            onPressed: onInfoPressed,
          ),
      ],
    );
  }
}
