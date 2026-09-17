import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qds/core/constants/api_constants.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/models/conversation_model.dart';
import 'package:qds/core/models/message_model.dart';
import 'package:qds/core/models/user_model.dart';
import 'package:qds/core/network/websocket_client.dart';
import 'package:qds/core/services/messaging_service.dart';
import 'package:qds/core/storage/local_storage.dart';
import 'package:qds/features/messaging/providers/chat_provider.dart';

/// In-memory fake WebSocket conforming to dart:io WebSocket interface.
class FakeWebSocket extends Stream<dynamic> implements WebSocket {
  final StreamController<dynamic> _incomingController = StreamController<dynamic>.broadcast();
  final List<String> sentFrames = [];
  bool _isClosed = false;
  final Completer<void> _doneCompleter = Completer<void>();

  void feedIncoming(dynamic data) {
    if (data is Map<String, dynamic>) {
      _incomingController.add(jsonEncode(data));
    } else {
      _incomingController.add(data);
    }
  }

  void feedError(dynamic error) {
    _incomingController.addError(error);
  }

  void simulateClose() {
    _isClosed = true;
    _incomingController.close();
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.complete();
    }
  }

  @override
  StreamSubscription<dynamic> listen(
    void Function(dynamic event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _incomingController.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  void add(dynamic data) {
    sentFrames.add(data.toString());
  }

  @override
  void addUtf8Text(List<int> bytes) {
    sentFrames.add(utf8.decode(bytes));
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future addStream(Stream stream) async {
    await for (final data in stream) {
      add(data);
    }
  }

  @override
  Future close([int? code, String? reason]) async {
    _isClosed = true;
    await _incomingController.close();
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.complete();
    }
  }

  @override
  Future get done => _doneCompleter.future;

  @override
  Duration? pingInterval;

  @override
  int? get closeCode => _isClosed ? WebSocketStatus.normalClosure : null;

  @override
  String? get closeReason => null;

  @override
  String get extensions => '';

  @override
  String get protocol => '';

  @override
  int get readyState => _isClosed ? WebSocket.closed : WebSocket.open;
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await LocalStorage.instance.init();
    await LocalStorage.instance.clear();
    MessagingService.instance.clear();
    ApiConstants.customHost = null;
    ApiConstants.customPort = null;
  });

  group('WebSocket Gateway URL Configuration', () {
    test('Default URL defaults to 127.0.0.1:8000/ws', () {
      expect(ApiConstants.wsUrl, equals('ws://127.0.0.1:8000/ws'));
      expect(ApiConstants.httpBaseUrl, equals('http://127.0.0.1:8000'));
    });

    test('Custom host and port can be configured at runtime', () {
      ApiConstants.customHost = '192.168.1.105';
      ApiConstants.customPort = 8080;

      expect(ApiConstants.wsUrl, equals('ws://192.168.1.105:8080/ws'));
      expect(ApiConstants.httpBaseUrl, equals('http://192.168.1.105:8080'));
    });
  });

  group('WebSocketClient Connection Lifecycle', () {
    test('Connects and transitions state to connected', () async {
      final fakeSocket = FakeWebSocket();
      final client = WebSocketClient(
        connector: (url) async => fakeSocket,
        autoReconnect: false,
      );

      expect(client.state, equals(WebSocketConnectionState.disconnected));

      final stateHistory = <WebSocketConnectionState>[];
      final sub = client.stateStream.listen(stateHistory.add);

      await client.connect(url: 'ws://test:8000/ws');

      expect(client.state, equals(WebSocketConnectionState.connected));
      expect(client.isConnected, isTrue);
      expect(stateHistory, contains(WebSocketConnectionState.connected));

      await client.disconnect();
      expect(client.state, equals(WebSocketConnectionState.disconnected));
      expect(client.isConnected, isFalse);

      await sub.cancel();
      await client.dispose();
    });

    test('Handles socket closure gracefully', () async {
      final fakeSocket = FakeWebSocket();
      final client = WebSocketClient(
        connector: (url) async => fakeSocket,
        autoReconnect: false,
      );

      await client.connect();
      expect(client.isConnected, isTrue);

      fakeSocket.simulateClose();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(client.isConnected, isFalse);
      await client.dispose();
    });
  });

  group('QDS Gateway Registration Protocol', () {
    test('Sender X registration payload format', () async {
      final fakeSocket = FakeWebSocket();
      final client = WebSocketClient(
        connector: (url) async => fakeSocket,
        autoReconnect: false,
      );
      final service = MessagingService(client: client);

      await service.connect();
      service.registerIdentity(userId: 'X', role: 'sender');

      expect(fakeSocket.sentFrames, isNotEmpty);
      final sent = jsonDecode(fakeSocket.sentFrames.last) as Map<String, dynamic>;
      expect(sent['type'], equals('register'));
      expect(sent['user_id'], equals('X'));
      expect(sent['role'], equals('sender'));

      await service.dispose();
    });

    test('Receiver Y registration payload format', () async {
      final fakeSocket = FakeWebSocket();
      final client = WebSocketClient(
        connector: (url) async => fakeSocket,
        autoReconnect: false,
      );
      final service = MessagingService(client: client);

      await service.connect();
      service.registerIdentity(userId: 'Y', role: 'receiver');

      expect(fakeSocket.sentFrames, isNotEmpty);
      final sent = jsonDecode(fakeSocket.sentFrames.last) as Map<String, dynamic>;
      expect(sent['type'], equals('register'));
      expect(sent['user_id'], equals('Y'));
      expect(sent['role'], equals('receiver'));

      await service.dispose();
    });

    test('Automatic registration uses LocalStorage role when connected', () async {
      await LocalStorage.instance.saveIdentity(name: 'Alice', role: 'Y');

      final fakeSocket = FakeWebSocket();
      final client = WebSocketClient(
        connector: (url) async => fakeSocket,
        autoReconnect: false,
      );
      final service = MessagingService(client: client);

      await service.connect();

      // _stateSubscription calls registerCurrentIdentity upon connected
      expect(fakeSocket.sentFrames, isNotEmpty);
      final sent = jsonDecode(fakeSocket.sentFrames.last) as Map<String, dynamic>;
      expect(sent['type'], equals('register'));
      expect(sent['user_id'], equals('Y'));
      expect(sent['role'], equals('receiver'));

      await service.dispose();
    });
  });

  group('Sending Messages across WebSocket', () {
    test('Outgoing message is sent over WebSocket and saved locally as sending', () async {
      final fakeSocket = FakeWebSocket();
      final client = WebSocketClient(
        connector: (url) async => fakeSocket,
        autoReconnect: false,
      );
      final service = MessagingService(client: client);
      await service.connect();

      final sentMsg = await service.sendMessage(
        conversationId: 'conv_y',
        content: 'Meeting at 10am',
        senderRole: UserRole.sender,
        senderName: 'Sender X',
      );

      expect(sentMsg.content, equals('Meeting at 10am'));
      expect(sentMsg.status, equals(MessageDeliveryStatus.sending));

      // Check frame sent over WebSocket
      expect(fakeSocket.sentFrames, isNotEmpty);
      final payload = jsonDecode(fakeSocket.sentFrames.last) as Map<String, dynamic>;
      expect(payload['type'], equals('message'));
      expect(payload['sender_id'], equals('X'));
      expect(payload['receiver_id'], equals('Y'));
      expect(payload['message'], equals('Meeting at 10am'));

      await service.dispose();
    });

    test('Sending message while offline returns failed message', () async {
      final client = WebSocketClient(autoReconnect: false);
      final service = MessagingService(client: client);

      final msg = await service.sendMessage(
        conversationId: 'conv_y',
        content: 'Failed attempt',
        senderRole: UserRole.sender,
        senderName: 'Sender X',
      );

      expect(msg.status, equals(MessageDeliveryStatus.failed));
      await service.dispose();
    });
  });

  group('Incoming message_result & Telemetry Handling', () {
    test('Parses message_result and preserves all 12 security telemetry fields', () async {
      final fakeSocket = FakeWebSocket();
      final client = WebSocketClient(
        connector: (url) async => fakeSocket,
        autoReconnect: false,
      );
      final service = MessagingService(client: client);
      await service.connect();

      final receivedMessages = <MessageModel>[];
      final sub = service.onMessageReceived.listen(receivedMessages.add);

      fakeSocket.feedIncoming({
        'type': 'message_result',
        'message_id': 'msg_test_001',
        'sender_id': 'X',
        'receiver_id': 'Y',
        'message': 'Quantum signature valid',
        'timestamp': '2026-09-17T21:00:00Z',
        'packet': {'packet_id': 'pkt_001'},
        'security': {
          'final_decision': 'TRUSTED',
          'likely_attack_type': 'NONE',
          'classical_signature_valid': true,
          'qds_valid': true,
          'replay_detected': false,
          'verification_accuracy': 0.995,
          'error_rate': 0.005,
          'quantum_bit_count': 64,
          'total_shots': 1024,
          'correct_shots': 1018,
          'threshold': 0.85,
          'qds_decision': 'ACCEPT',
          'signer_id': 'X',
        },
      });

      await Future.delayed(const Duration(milliseconds: 20));

      expect(receivedMessages, hasLength(1));
      final msg = receivedMessages.first;
      expect(msg.id, equals('msg_test_001'));
      expect(msg.content, equals('Quantum signature valid'));
      expect(msg.status, equals(MessageDeliveryStatus.delivered));
      expect(msg.securityStatus, equals(QdsSecurityStatus.trusted));

      // Validate all 12 real telemetry fields
      expect(msg.finalDecision, equals('TRUSTED'));
      expect(msg.likelyAttackType, equals('NONE'));
      expect(msg.classicalSignatureValid, isTrue);
      expect(msg.qdsValid, isTrue);
      expect(msg.replayDetected, isFalse);
      expect(msg.verificationAccuracy, equals(0.995));
      expect(msg.errorRate, equals(0.005));
      expect(msg.quantumBitCount, equals(64));
      expect(msg.totalShots, equals(1024));
      expect(msg.correctShots, equals(1018));
      expect(msg.threshold, equals(0.85));
      expect(msg.qdsDecision, equals('ACCEPT'));
      expect(msg.signerId, equals('X'));

      await sub.cancel();
      await service.dispose();
    });

    test('Detects replay attack in security payload and marks threatDetected', () async {
      final fakeSocket = FakeWebSocket();
      final client = WebSocketClient(
        connector: (url) async => fakeSocket,
        autoReconnect: false,
      );
      final service = MessagingService(client: client);
      await service.connect();

      final receivedMessages = <MessageModel>[];
      final sub = service.onMessageReceived.listen(receivedMessages.add);

      fakeSocket.feedIncoming({
        'type': 'message_result',
        'message_id': 'msg_replay_001',
        'sender_id': 'X',
        'receiver_id': 'Y',
        'message': 'Replayed message',
        'security': {
          'final_decision': 'REPLAY_ATTACK',
          'likely_attack_type': 'REPLAY',
          'classical_signature_valid': true,
          'qds_valid': false,
          'replay_detected': true,
        },
      });

      await Future.delayed(const Duration(milliseconds: 20));

      expect(receivedMessages, hasLength(1));
      expect(receivedMessages.first.securityStatus, equals(QdsSecurityStatus.threatDetected));
      expect(receivedMessages.first.replayDetected, isTrue);

      await sub.cancel();
      await service.dispose();
    });

    test('Duplicate message_id is ignored and not duplicated', () async {
      final fakeSocket = FakeWebSocket();
      final client = WebSocketClient(
        connector: (url) async => fakeSocket,
        autoReconnect: false,
      );
      final service = MessagingService(client: client);
      await service.connect();

      final receivedMessages = <MessageModel>[];
      final sub = service.onMessageReceived.listen(receivedMessages.add);

      final incomingPayload = {
        'type': 'message_result',
        'message_id': 'duplicate_id_999',
        'sender_id': 'X',
        'receiver_id': 'Y',
        'message': 'Once only',
      };

      fakeSocket.feedIncoming(incomingPayload);
      await Future.delayed(const Duration(milliseconds: 10));

      fakeSocket.feedIncoming(incomingPayload);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedMessages, hasLength(1));

      await sub.cancel();
      await service.dispose();
    });
  });

  group('Receiving ACK for Sent Message', () {
    test('ACK transitions local sending message to delivered and attaches telemetry', () async {
      final fakeSocket = FakeWebSocket();
      final client = WebSocketClient(
        connector: (url) async => fakeSocket,
        autoReconnect: false,
      );
      final service = MessagingService(client: client);
      await service.connect();

      final initialMsg = await service.sendMessage(
        conversationId: 'conv_y',
        content: 'Hello with ACK',
        senderRole: UserRole.sender,
        senderName: 'Sender X',
      );

      expect(initialMsg.status, equals(MessageDeliveryStatus.sending));

      final updatedMessages = <MessageModel>[];
      final sub = service.onMessageUpdated.listen(updatedMessages.add);

      // Gateway returns ACK
      fakeSocket.feedIncoming({
        'type': 'ack',
        'message_id': 'server_msg_id_123',
        'status': 'delivered',
        'details': {
          'security': {
            'final_decision': 'TRUSTED',
            'likely_attack_type': 'NONE',
            'classical_signature_valid': true,
            'qds_valid': true,
            'replay_detected': false,
            'verification_accuracy': 0.99,
            'error_rate': 0.01,
          },
        },
      });

      await Future.delayed(const Duration(milliseconds: 20));

      expect(updatedMessages, hasLength(1));
      final ackedMsg = updatedMessages.first;
      expect(ackedMsg.status, equals(MessageDeliveryStatus.delivered));
      expect(ackedMsg.securityStatus, equals(QdsSecurityStatus.trusted));
      expect(ackedMsg.verificationAccuracy, equals(0.99));
      expect(ackedMsg.errorRate, equals(0.01));

      await sub.cancel();
      await service.dispose();
    });

    test('ACK with receiver_offline sets status to sent', () async {
      final fakeSocket = FakeWebSocket();
      final client = WebSocketClient(
        connector: (url) async => fakeSocket,
        autoReconnect: false,
      );
      final service = MessagingService(client: client);
      await service.connect();

      await service.sendMessage(
        conversationId: 'conv_y',
        content: 'Queued message',
        senderRole: UserRole.sender,
        senderName: 'Sender X',
      );

      final updatedMessages = <MessageModel>[];
      final sub = service.onMessageUpdated.listen(updatedMessages.add);

      fakeSocket.feedIncoming({
        'type': 'ack',
        'message_id': 'offline_msg_456',
        'status': 'receiver_offline',
      });

      await Future.delayed(const Duration(milliseconds: 20));

      expect(updatedMessages, hasLength(1));
      expect(updatedMessages.first.status, equals(MessageDeliveryStatus.sent));

      await sub.cancel();
      await service.dispose();
    });
  });

  group('ChatProvider WebSocket Integration', () {
    test('ChatProvider reacts to incoming messages and updates currentMessages', () async {
      final fakeSocket = FakeWebSocket();
      final client = WebSocketClient(
        connector: (url) async => fakeSocket,
        autoReconnect: false,
      );
      final service = MessagingService(client: client);
      await service.connect();

      final provider = ChatProvider(service: service);
      final conv = const ConversationModel(
        id: 'conv_x',
        peerName: 'Sender X',
        peerRole: UserRole.sender,
      );
      await provider.openConversation(conv);

      expect(provider.currentMessages, isEmpty);

      fakeSocket.feedIncoming({
        'type': 'message_result',
        'message_id': 'incoming_prov_01',
        'sender_id': 'X',
        'receiver_id': 'Y',
        'message': 'Real-time test message',
      });

      await Future.delayed(const Duration(milliseconds: 30));

      expect(provider.currentMessages, hasLength(1));
      expect(provider.currentMessages.first.content, equals('Real-time test message'));

      provider.dispose();
      await service.dispose();
    });
  });
}
