import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';

/// Message composer widget providing multiline text input and send action.
class MessageInput extends StatefulWidget {
  const MessageInput({
    super.key,
    required this.onSend,
    this.hintText = 'Type a message...',
    this.isEnabled = true,
  });

  final FutureOr<void> Function(String) onSend;
  final String hintText;
  final bool isEnabled;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  bool _canSend = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    final canSend = _controller.text.trim().isNotEmpty;
    if (canSend != _canSend) {
      setState(() => _canSend = canSend);
    }
  }

  Future<void> _handleSubmit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.isEnabled || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    _controller.clear();
    try {
      await widget.onSend(text);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.isEnabled && _canSend && !_isSubmitting;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPadding,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: AppDimensions.borderWidthThin,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: AppDimensions.borderWidthThin,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  enabled: widget.isEnabled,
                  minLines: 1,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTypography.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Semantics(
              label: 'Send message',
              button: true,
              enabled: isEnabled,
              child: Container(
                width: 42,
                height: 42,
                margin: const EdgeInsets.only(bottom: 1),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  tooltip: 'Send',
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          Icons.arrow_upward_rounded,
                          size: 20,
                          color: isEnabled
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                  onPressed: isEnabled ? _handleSubmit : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
