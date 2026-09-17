import 'package:flutter/material.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/models/message_model.dart';

/// Subtle status indicator for message delivery states (sending, sent, delivered, read, failed).
class MessageStatusWidget extends StatelessWidget {
  const MessageStatusWidget({
    super.key,
    required this.status,
    this.color,
    this.size = 14.0,
  });

  final MessageDeliveryStatus status;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    final securityColors = context.securityColors;

    switch (status) {
      case MessageDeliveryStatus.sending:
        return SizedBox(
          width: size - 2,
          height: size - 2,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
          ),
        );
      case MessageDeliveryStatus.sent:
        return Icon(
          Icons.check_rounded,
          size: size,
          color: effectiveColor,
        );
      case MessageDeliveryStatus.delivered:
        return Icon(
          Icons.done_all_rounded,
          size: size,
          color: effectiveColor,
        );
      case MessageDeliveryStatus.read:
        return Icon(
          Icons.done_all_rounded,
          size: size,
          color: Theme.of(context).colorScheme.primary,
        );
      case MessageDeliveryStatus.failed:
        return Icon(
          Icons.error_outline_rounded,
          size: size,
          color: securityColors.critical,
        );
    }
  }
}
