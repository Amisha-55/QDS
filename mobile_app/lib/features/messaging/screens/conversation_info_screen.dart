import 'package:flutter/material.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/models/conversation_model.dart';
import 'package:qds/core/models/user_model.dart';
import 'package:qds/shared/widgets/app_card.dart';
import 'package:qds/shared/widgets/security_badge.dart';

/// Screen displaying conversation metadata, peer identity, and security parameters.
class ConversationInfoScreen extends StatelessWidget {
  const ConversationInfoScreen({
    super.key,
    this.conversation,
  });

  final ConversationModel? conversation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conv = conversation ?? const ConversationModel(
      id: 'default',
      peerName: 'Counterpart Peer',
      peerRole: UserRole.receiver,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation Info'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
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
                          conv.peerRole.code,
                          style: AppTypography.pageHeading.copyWith(
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
                          Text(
                            conv.peerName,
                            style: AppTypography.cardTitle.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Demonstration Role: ${conv.peerRole.label} (${conv.peerRole.code})',
                            style: AppTypography.bodySmall.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SecurityBadge(
                      status: conv.securityStatus,
                      variant: SecurityBadgeVariant.compact,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                title: 'Security Layer Status',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SecurityBadge(
                      status: conv.securityStatus,
                      variant: SecurityBadgeVariant.detailed,
                      supportingText: 'Channel prepared for quantum-inspired digital signature verification.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                title: 'Signature Verification',
                subtitle: 'Cryptographic telemetry',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Live verification will be captured when messages are transmitted across the backend.',
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                title: 'Security Audit Events',
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text(
                      'No threat or anomaly events detected for this session.',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
