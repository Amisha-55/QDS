import 'dart:async';
import 'dart:developer' as dev;

import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/models/conversation_model.dart';
import 'package:qds/core/models/message_model.dart';
import 'package:qds/core/models/user_model.dart';
import 'package:qds/core/network/websocket_client.dart';
import 'package:qds/core/services/security_service.dart';
import 'package:qds/core/storage/local_storage.dart';

/// Clean service boundary for messaging operations.
/// Connects to the QDS WebSocket Gateway while delegating all cryptographic
/// processing to the Python backend.
class MessagingService {
  MessagingService({WebSocketClient? client})
      : _client = client ?? WebSocketClient() {
    _initSubscriptions();
  }

  static final MessagingService instance = MessagingService();

  final WebSocketClient _client;

  final List<ConversationModel> _conversations = [];
  final Map<String, List<MessageModel>> _messagesByConversation = {};
  final Set<String> _processedMessageIds = {};

  final StreamController<MessageModel> _messageReceivedController =
      StreamController<MessageModel>.broadcast();
  final StreamController<MessageModel> _messageUpdatedController =
      StreamController<MessageModel>.broadcast();

  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<WebSocketConnectionState>? _stateSubscription;

  /// Stream of new incoming messages received from the gateway.
  Stream<MessageModel> get onMessageReceived => _messageReceivedController.stream;

  /// Stream of message status updates (e.g. sending -> delivered via ACK).
  Stream<MessageModel> get onMessageUpdated => _messageUpdatedController.stream;

  /// Active WebSocket connection state.
  WebSocketConnectionState get connectionState => _client.state;

  /// Stream of WebSocket connection state changes.
  Stream<WebSocketConnectionState> get connectionStateStream => _client.stateStream;

  /// Underlying client (for testing or direct inspection).
  WebSocketClient get client => _client;

  void _initSubscriptions() {
    _messageSubscription = _client.messageStream.listen(_handleGatewayMessage);
    _stateSubscription = _client.stateStream.listen((state) {
      if (state == WebSocketConnectionState.connected) {
        registerCurrentIdentity();
      }
    });
  }

  /// Connects to the QDS Gateway and registers the active identity.
  Future<void> connect({String? url}) async {
    await _client.connect(url: url);
  }

  /// Disconnects from the QDS Gateway.
  Future<void> disconnect() async {
    await _client.disconnect();
  }

  /// Registers the device's configured identity (X=sender or Y=receiver) with the gateway.
  bool registerCurrentIdentity() {
    final role = LocalStorage.instance.role ?? UserRole.sender;
    return registerIdentity(
      userId: role.code,
      role: role == UserRole.sender ? 'sender' : 'receiver',
    );
  }

  /// Explicitly registers a user ID and role with the gateway.
  bool registerIdentity({required String userId, required String role}) {
    dev.log('Registering identity with gateway: user_id=$userId, role=$role', name: 'MessagingService');
    return _client.sendJson({
      'type': 'register',
      'user_id': userId,
      'role': role,
    });
  }

  Future<List<ConversationModel>> getConversations() async {
    return List.unmodifiable(_conversations);
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    return List.unmodifiable(_messagesByConversation[conversationId] ?? []);
  }

  /// Dispatches an outgoing message to the QDS Gateway.
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    required UserRole senderRole,
    required String senderName,
  }) async {
    final peerRole = senderRole == UserRole.sender ? UserRole.receiver : UserRole.sender;
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final initialMessage = MessageModel(
      id: tempId,
      conversationId: conversationId,
      senderRole: senderRole,
      senderName: senderName,
      content: content,
      timestamp: DateTime.now(),
      status: MessageDeliveryStatus.sending,
    );

    _messagesByConversation.putIfAbsent(conversationId, () => []).add(initialMessage);
    _updateConversationSnippet(conversationId, content, initialMessage.timestamp);

    final sent = _client.sendJson({
      'type': 'message',
      'sender_id': senderRole.code,
      'receiver_id': peerRole.code,
      'message': content,
    });

    if (!sent) {
      final failedMessage = initialMessage.copyWith(status: MessageDeliveryStatus.failed);
      _replaceMessage(conversationId, tempId, failedMessage);
      return failedMessage;
    }

    return initialMessage;
  }

  void _handleGatewayMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    if (type == 'message_result') {
      _handleIncomingMessageResult(data);
    } else if (type == 'ack') {
      _handleAck(data);
    } else if (type == 'registered') {
      dev.log('Gateway confirmed registration for ${data['user_id']}', name: 'MessagingService');
    } else if (type == 'error') {
      dev.log('Gateway returned error: ${data['error_code']} - ${data['message']}', name: 'MessagingService');
    }
  }

  void _handleIncomingMessageResult(Map<String, dynamic> data) {
    final messageId = data['message_id'] as String? ?? '';
    if (messageId.isNotEmpty && _processedMessageIds.contains(messageId)) {
      dev.log('Duplicate message ignored: $messageId', name: 'MessagingService');
      return;
    }
    if (messageId.isNotEmpty) {
      _processedMessageIds.add(messageId);
    }

    final senderId = data['sender_id'] as String? ?? 'X';
    final content = data['message'] as String? ?? '';
    final receiveTimestamp = DateTime.now();
    final securityData = data['security'] as Map<String, dynamic>?;

    final senderRole = senderId == 'X' ? UserRole.sender : UserRole.receiver;
    final senderName = senderId == 'X' ? 'Sender X' : 'Receiver Y';
    final conversationId = 'conv_${senderRole.code.toLowerCase()}';

    final securityStatus = _mapSecurityStatus(securityData);

    final incomingMessage = MessageModel(
      id: messageId,
      conversationId: conversationId,
      senderRole: senderRole,
      senderName: senderName,
      content: content,
      timestamp: receiveTimestamp,
      status: MessageDeliveryStatus.delivered,
      securityStatus: securityStatus,
      securityData: securityData,
    );

    createOrGetConversation(
      peerName: senderName,
      peerRole: senderRole,
      conversationId: conversationId,
    );

    _messagesByConversation.putIfAbsent(conversationId, () => []).add(incomingMessage);
    _updateConversationSnippet(conversationId, content, receiveTimestamp);

    _messageReceivedController.add(incomingMessage);
  }

  void _handleAck(Map<String, dynamic> data) {
    final messageId = data['message_id'] as String? ?? '';
    final status = data['status'] as String? ?? 'delivered';
    final details = data['details'] as Map<String, dynamic>? ?? {};
    final securityData = details['security'] as Map<String, dynamic>?;

    final newDeliveryStatus = status == 'delivered'
        ? MessageDeliveryStatus.delivered
        : (status == 'receiver_offline' ? MessageDeliveryStatus.sent : MessageDeliveryStatus.failed);

    final securityStatus = _mapSecurityStatus(securityData);

    for (final entry in _messagesByConversation.entries) {
      final list = entry.value;
      final index = list.indexWhere(
        (m) => m.id == messageId || (m.status == MessageDeliveryStatus.sending && m.id.startsWith('temp_')),
      );

      if (index != -1) {
        final existing = list[index];
        final updated = existing.copyWith(
          id: messageId.isNotEmpty ? messageId : existing.id,
          status: newDeliveryStatus,
          securityStatus: securityStatus ?? existing.securityStatus,
          securityData: securityData ?? existing.securityData,
        );
        list[index] = updated;
        if (messageId.isNotEmpty) {
          _processedMessageIds.add(messageId);
        }
        _messageUpdatedController.add(updated);
        break;
      }
    }
  }

  QdsSecurityStatus? _mapSecurityStatus(Map<String, dynamic>? securityData) {
    if (securityData == null || securityData.isEmpty) return null;
    return SecurityService.deriveSecurityStatus(securityData);
  }

  void _replaceMessage(String conversationId, String targetId, MessageModel newMessage) {
    final list = _messagesByConversation[conversationId];
    if (list != null) {
      final index = list.indexWhere((m) => m.id == targetId);
      if (index != -1) {
        list[index] = newMessage;
        _messageUpdatedController.add(newMessage);
      }
    }
  }

  void _updateConversationSnippet(String conversationId, String content, DateTime timestamp) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(
        lastMessage: content,
        lastMessageTimestamp: timestamp,
      );
    }
  }

  Future<ConversationModel> createOrGetConversation({
    required String peerName,
    required UserRole peerRole,
    String? conversationId,
  }) async {
    final id = conversationId ?? 'conv_${peerRole.code.toLowerCase()}';
    final existingIndex = _conversations.indexWhere((c) => c.id == id);
    if (existingIndex != -1) {
      return _conversations[existingIndex];
    }

    final newConv = ConversationModel(
      id: id,
      peerName: peerName,
      peerRole: peerRole,
    );
    _conversations.add(newConv);
    return newConv;
  }

  /// Reset all stored state for testing.
  void clear() {
    _client.disconnect();
    _conversations.clear();
    _messagesByConversation.clear();
    _processedMessageIds.clear();
    SecurityService.instance.clear();
  }

  /// Dispose service resources.
  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    await _stateSubscription?.cancel();
    await _messageReceivedController.close();
    await _messageUpdatedController.close();
    await _client.dispose();
  }
}
