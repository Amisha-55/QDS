import 'package:flutter/material.dart';
import 'package:qds/app/routes.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/models/conversation_model.dart';
import 'package:qds/core/models/message_model.dart';
import 'package:qds/core/models/user_model.dart';
import 'package:qds/core/network/websocket_client.dart';
import 'package:qds/core/storage/local_storage.dart';
import 'package:qds/core/utils/date_utils.dart';
import 'package:qds/features/messaging/providers/chat_provider.dart';
import 'package:qds/features/messaging/widgets/chat_app_bar.dart';
import 'package:qds/features/messaging/widgets/message_bubble.dart';
import 'package:qds/features/messaging/widgets/message_input.dart';
import 'package:qds/features/messaging/widgets/typing_indicator.dart';
import 'package:qds/features/security/providers/security_provider.dart';
import 'package:qds/features/security/widgets/threat_alert_banner.dart';

/// The central messaging chat screen.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.conversation,
    this.provider,
    this.securityProvider,
  });

  final ConversationModel? conversation;
  final ChatProvider? provider;
  final SecurityProvider? securityProvider;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatProvider _chatProvider;
  late final SecurityProvider _securityProvider;
  late final ConversationModel _conversation;
  final ScrollController _scrollController = ScrollController();
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _chatProvider = widget.provider ?? ChatProvider();
    _securityProvider = widget.securityProvider ?? SecurityProvider();
    _conversation = widget.conversation ??
        _chatProvider.activeConversation ??
        const ConversationModel(
          id: 'default',
          peerName: 'Receiver Y',
          peerRole: UserRole.receiver,
        );

    _chatProvider.openConversation(_conversation);
    _chatProvider.addListener(_handleProviderUpdate);
    _securityProvider.addListener(_handleProviderUpdate);
    if (_chatProvider.connectionState != WebSocketConnectionState.connected &&
        LocalStorage.instance.role != null) {
      _chatProvider.connectGateway();
    }
  }

  void _handleProviderUpdate() {
    if (!mounted) return;
    setState(() {});
    _scrollToBottom(force: false);
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    return (maxScroll - currentScroll) <= 120.0;
  }

  void _scrollToBottom({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (force || _isNearBottom()) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _chatProvider.removeListener(_handleProviderUpdate);
    _securityProvider.removeListener(_handleProviderUpdate);
    if (widget.securityProvider == null) {
      _securityProvider.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildConnectionBanner(BuildContext context) {
    final state = _chatProvider.connectionState;
    if (state == WebSocketConnectionState.connected) {
      return const SizedBox.shrink();
    }

    final isConnecting = state == WebSocketConnectionState.connecting ||
        state == WebSocketConnectionState.reconnecting;
    final color = isConnecting ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    final text = isConnecting
        ? (state == WebSocketConnectionState.connecting
            ? 'Connecting to QDS gateway...'
            : 'Reconnecting to QDS gateway...')
        : 'QDS gateway is offline';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      color: color.withValues(alpha: 0.12),
      child: Row(
        children: [
          if (isConnecting)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          else
            Icon(Icons.cloud_off_rounded, size: 14, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!isConnecting)
            InkWell(
              onTap: () => _chatProvider.connectGateway(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  'Retry',
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localRole = LocalStorage.instance.role ?? UserRole.sender;
    final messages = _chatProvider.currentMessages;

    return Scaffold(
      appBar: ChatAppBar(
        peerName: _conversation.peerName,
        peerRole: _conversation.peerRole,
        securityStatus: _conversation.securityStatus,
        onInfoPressed: () async {
          if (_isNavigating) return;
          _isNavigating = true;
          try {
            await Navigator.pushNamed(
              context,
              AppRoutes.conversationInfo,
              arguments: _conversation,
            );
          } finally {
            if (mounted) {
              _isNavigating = false;
            }
          }
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildConnectionBanner(context),
            if (_securityProvider.activeThreatAlert != null)
              ThreatAlertBanner(
                event: _securityProvider.activeThreatAlert!,
                onDismiss: () => _securityProvider.dismissThreatAlert(),
              ),
            Expanded(
              child: messages.isEmpty
                  ? _buildEmptyState(context)
                  : _buildMessageList(context, messages, localRole),
            ),
            if (_chatProvider.isPeerTyping)
              TypingIndicator(peerName: _conversation.peerName),
            MessageInput(
              onSend: (text) async {
                await _chatProvider.sendMessage(text);
                _scrollToBottom(force: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 28,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No messages yet',
              style: AppTypography.cardTitle.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Send a message to start communicating with ${_conversation.peerName}.',
              style: AppTypography.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(
    BuildContext context,
    List<MessageModel> messages,
    UserRole localRole,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderRole == localRole;
        final showDateSeparator = index == 0 ||
            !AppDateUtils.isSameDay(
              messages[index - 1].timestamp,
              message.timestamp,
            );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDateSeparator) _buildDateSeparator(context, message.timestamp),
            MessageBubble(
              message: message,
              isMe: isMe,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(BuildContext context, DateTime timestamp) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        AppDateUtils.formatDateOrTime(timestamp),
        style: AppTypography.caption.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 10.5,
        ),
      ),
    );
  }
}
