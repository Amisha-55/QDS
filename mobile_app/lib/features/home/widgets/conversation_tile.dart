import 'package:flutter/material.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/models/conversation_model.dart';
import 'package:qds/core/utils/date_utils.dart';
import 'package:qds/shared/widgets/security_badge.dart';

/// List tile representing an active conversation on the Home screen.
class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    this.onTap,
  });

  final ConversationModel conversation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.3 : 0.6),
            width: AppDimensions.borderWidthThin,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
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
                  conversation.peerRole.code,
                  style: AppTypography.cardTitle.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.peerName,
                          style: AppTypography.cardTitle.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.lastMessageTimestamp != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          AppDateUtils.formatDateOrTime(conversation.lastMessageTimestamp!),
                          style: AppTypography.caption.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage ?? 'No messages yet',
                          style: AppTypography.bodySmall.copyWith(
                            color: conversation.unreadCount > 0
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SecurityBadge(
                        status: conversation.securityStatus,
                        variant: SecurityBadgeVariant.compact,
                      ),
                      if (conversation.unreadCount > 0) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
