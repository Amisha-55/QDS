import 'package:flutter/material.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/models/message_model.dart';
import 'package:qds/core/models/security_telemetry.dart';
import 'package:qds/core/utils/date_utils.dart';
import 'package:qds/features/messaging/widgets/message_status.dart';
import 'package:qds/features/security/widgets/message_security_details_sheet.dart';

/// A message bubble displaying message content, timestamp, status, and verification state.
/// Dynamically styled depending on whether it was sent by the local user or received from peer.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  final MessageModel message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.78;

    final bgColor = isMe
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;

    final textColor = isMe
        ? Colors.white
        : theme.colorScheme.onSurface;

    final metaColor = isMe
        ? Colors.white.withValues(alpha: 0.75)
        : theme.colorScheme.onSurfaceVariant;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: isMe ? const Radius.circular(14) : const Radius.circular(2),
      bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(14),
    );

    final hasSecurity = message.securityData != null && message.securityData!.isNotEmpty;
    final secStatus = message.securityStatus ?? QdsSecurityStatus.trusted;
    final isThreat = hasSecurity &&
        (secStatus == QdsSecurityStatus.threatDetected ||
            secStatus == QdsSecurityStatus.suspicious ||
            secStatus == QdsSecurityStatus.verificationFailed ||
            secStatus == QdsSecurityStatus.warning);

    final statusColor = context.securityColors.colorForStatus(secStatus);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: hasSecurity
            ? () {
                final telemetry = SecurityTelemetry.fromJson(message.securityData);
                MessageSecurityDetailsSheet.show(
                  context,
                  telemetry: telemetry,
                  messageSnippet: message.content,
                );
              }
            : null,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius,
            border: isMe
                ? (isThreat ? Border.all(color: Colors.amberAccent.withValues(alpha: 0.8), width: 1.5) : null)
                : Border.all(
                    color: isThreat ? statusColor.withValues(alpha: 0.7) : theme.colorScheme.outline.withValues(alpha: 0.4),
                    width: isThreat ? 1.5 : AppDimensions.borderWidthThin,
                  ),
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.content,
                style: AppTypography.bodyMedium.copyWith(
                  color: textColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppDateUtils.formatTime(message.timestamp),
                    style: AppTypography.caption.copyWith(
                      color: metaColor,
                      fontSize: 10.5,
                    ),
                  ),
                  if (hasSecurity) ...[
                    const SizedBox(width: 5),
                    if (isThreat) ...[
                      Icon(
                        secStatus.icon,
                        size: 11,
                        color: isMe ? Colors.amberAccent : statusColor,
                      ),
                      const SizedBox(width: 2.5),
                      Text(
                        secStatus == QdsSecurityStatus.verificationFailed
                            ? 'Verification failed'
                            : 'Security warning',
                        style: AppTypography.caption.copyWith(
                          color: isMe ? Colors.amberAccent : statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ] else ...[
                      Icon(
                        Icons.check_circle_rounded,
                        size: 11,
                        color: isMe ? metaColor : context.securityColors.trusted,
                      ),
                      const SizedBox(width: 2.5),
                      Text(
                        'Verified',
                        style: AppTypography.caption.copyWith(
                          color: isMe ? metaColor : context.securityColors.trusted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    MessageStatusWidget(
                      status: message.status,
                      color: metaColor,
                      size: 13,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
