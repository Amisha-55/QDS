import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:qds/core/models/conversation_model.dart';
import 'package:qds/core/models/message_model.dart';
import 'package:qds/core/models/user_model.dart';
import 'package:qds/core/network/websocket_client.dart';
import 'package:qds/core/services/messaging_service.dart';
import 'package:qds/core/storage/local_storage.dart';

/// State management for the messaging feature.
/// Subscribes to real-time events from [MessagingService] (powered by WebSocketClient).
class ChatProvider extends ChangeNotifier {
  ChatProvider({MessagingService? service})
      : _service = service ?? MessagingService.instance {
    _initSubscriptions();
  }

  final MessagingService _service;

  List<ConversationModel> _conversations = [];
  List<MessageModel> _currentMessages = [];
  ConversationModel? _activeConversation;
  bool _isLoading = false;
  bool _isPeerTyping = false;

  StreamSubscription<MessageModel>? _messageReceivedSub;
  StreamSubscription<MessageModel>? _messageUpdatedSub;
  StreamSubscription<WebSocketConnectionState>? _stateSub;

  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get currentMessages => _currentMessages;
  ConversationModel? get activeConversation => _activeConversation;
  bool get isLoading => _isLoading;
  bool get isPeerTyping => _isPeerTyping;
  WebSocketConnectionState get connectionState => _service.connectionState;

  void _initSubscriptions() {
    _messageReceivedSub = _service.onMessageReceived.listen(_handleMessageReceived);
    _messageUpdatedSub = _service.onMessageUpdated.listen(_handleMessageUpdated);
    _stateSub = _service.connectionStateStream.listen((_) {
      notifyListeners();
    });
  }

  void _handleMessageReceived(MessageModel message) {
    if (_activeConversation != null && message.conversationId == _activeConversation!.id) {
      final index = _currentMessages.indexWhere((m) => m.id == message.id);
      if (index == -1) {
        _currentMessages = [..._currentMessages, message];
      }
    }
    loadConversations();
  }

  void _handleMessageUpdated(MessageModel message) {
    if (_activeConversation != null && message.conversationId == _activeConversation!.id) {
      final index = _currentMessages.indexWhere(
        (m) => m.id == message.id || (m.status == MessageDeliveryStatus.sending && m.id.startsWith('temp_')),
      );
      if (index != -1) {
        final updated = List<MessageModel>.from(_currentMessages);
        updated[index] = message;
        _currentMessages = updated;
      }
    }
    loadConversations();
  }

  Future<void> connectGateway({String? url}) async {
    await _service.connect(url: url);
  }

  Future<void> disconnectGateway() async {
    await _service.disconnect();
  }

  Future<void> loadConversations() async {
    _isLoading = true;
    notifyListeners();

    _conversations = await _service.getConversations();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> openConversation(ConversationModel conversation) async {
    _activeConversation = conversation;
    _isLoading = true;
    notifyListeners();

    _currentMessages = await _service.getMessages(conversation.id);
    _isLoading = false;
    notifyListeners();
  }

  Future<MessageModel?> sendMessage(String content) async {
    if (_activeConversation == null || content.trim().isEmpty) return null;

    final localRole = LocalStorage.instance.role ?? UserRole.sender;
    final localName = LocalStorage.instance.displayName ?? 'User';

    final sentMessage = await _service.sendMessage(
      conversationId: _activeConversation!.id,
      content: content.trim(),
      senderRole: localRole,
      senderName: localName,
    );

    _currentMessages = await _service.getMessages(_activeConversation!.id);
    await loadConversations();
    notifyListeners();

    return sentMessage;
  }

  void setPeerTyping(bool typing) {
    _isPeerTyping = typing;
    notifyListeners();
  }

  /// Creates a conversation with the counterpart peer (Sender X <-> Receiver Y)
  Future<ConversationModel> startConversationWithCounterpart() async {
    final localRole = LocalStorage.instance.role ?? UserRole.sender;
    final peerRole = localRole == UserRole.sender ? UserRole.receiver : UserRole.sender;
    final peerName = peerRole == UserRole.receiver ? 'Receiver Y' : 'Sender X';

    final conv = await _service.createOrGetConversation(
      peerName: peerName,
      peerRole: peerRole,
    );

    await loadConversations();
    await openConversation(conv);
    return conv;
  }

  @override
  void dispose() {
    _messageReceivedSub?.cancel();
    _messageUpdatedSub?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }
}
