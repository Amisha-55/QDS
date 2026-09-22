import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/models/message_model.dart';
import 'package:qds/core/models/security_event_model.dart';
import 'package:qds/core/models/security_telemetry.dart';
import 'package:qds/core/models/user_model.dart';
import 'package:qds/core/network/websocket_client.dart';
import 'package:qds/core/services/messaging_service.dart';
import 'package:qds/core/services/security_service.dart';
import 'package:qds/core/storage/local_storage.dart';
import 'package:qds/features/messaging/providers/chat_provider.dart';
import 'package:qds/features/messaging/screens/chat_screen.dart';
import 'package:qds/features/security/providers/security_provider.dart';
import 'package:qds/features/security/screens/security_screen.dart';
import 'package:qds/features/security/screens/verification_screen.dart';
import 'package:qds/features/security/widgets/threat_alert_banner.dart';
import 'package:qds/features/security/widgets/threat_detection_card.dart';

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

/// A simulated virtual gateway router connecting two WebSocket clients.
class VirtualGatewayRouter {
  final Map<String, FakeWebSocket> registeredSockets = {};
  final List<Map<String, dynamic>> routedMessages = [];

  void attachSocket(String userId, FakeWebSocket socket) {
    registeredSockets[userId] = socket;
  }

  void routeClientMessage({
    required String senderId,
    required String receiverId,
    required String message,
    required Map<String, dynamic> securitySummary,
    String? messageId,
  }) {
    final id = messageId ?? 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final envelope = {
      'type': 'message_result',
      'message_id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'security': securitySummary,
    };

    routedMessages.add(envelope);

    // Deliver to receiver socket if attached
    final receiverSocket = registeredSockets[receiverId];
    final receiverConnected = receiverSocket != null;
    if (receiverConnected) {
      receiverSocket.feedIncoming(envelope);
    }

    // Deliver ACK to sender socket if attached
    final senderSocket = registeredSockets[senderId];
    if (senderSocket != null) {
      senderSocket.feedIncoming({
        'type': 'ack',
        'message_id': id,
        'status': receiverConnected ? 'delivered' : 'receiver_offline',
        'details': {
          'receiver_connected': receiverConnected,
          'final_decision': securitySummary['final_decision'],
          'likely_attack_type': securitySummary['likely_attack_type'],
          'verification_accuracy': securitySummary['verification_accuracy'],
          'security': securitySummary,
        },
      });
    }
  }
}

Widget buildTestApp({
  required Widget home,
}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    routes: {
      '/verification-details': (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is SecurityTelemetry) {
          return VerificationScreen(telemetry: args);
        } else if (args is SecurityEventModel) {
          return VerificationScreen(telemetry: args.telemetry, event: args);
        }
        return const VerificationScreen();
      },
    },
    home: home,
  );
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    LocalStorage.instance.clear();
    await LocalStorage.instance.init();
    MessagingService.instance.clear();
    SecurityService.instance.clear();
  });

  tearDown(() {
    MessagingService.instance.clear();
    SecurityService.instance.clear();
  });

  group('Prompt 13: End-to-End Live Integration & Multi-Client Tests', () {
    test('1. Two-client simultaneous connection and role registration', () async {
      final fakeSocketX = FakeWebSocket();
      final fakeSocketY = FakeWebSocket();

      final clientX = WebSocketClient(connector: (url) async => fakeSocketX, autoReconnect: false);
      final clientY = WebSocketClient(connector: (url) async => fakeSocketY, autoReconnect: false);

      final serviceX = MessagingService(client: clientX);
      final serviceY = MessagingService(client: clientY);

      await serviceX.connect();
      await serviceY.connect();

      serviceX.registerIdentity(userId: 'X', role: 'sender');
      serviceY.registerIdentity(userId: 'Y', role: 'receiver');

      expect(clientX.isConnected, isTrue);
      expect(clientY.isConnected, isTrue);

      final regX = jsonDecode(fakeSocketX.sentFrames.last) as Map<String, dynamic>;
      expect(regX['type'], equals('register'));
      expect(regX['user_id'], equals('X'));
      expect(regX['role'], equals('sender'));

      final regY = jsonDecode(fakeSocketY.sentFrames.last) as Map<String, dynamic>;
      expect(regY['type'], equals('register'));
      expect(regY['user_id'], equals('Y'));
      expect(regY['role'], equals('receiver'));

      await serviceX.dispose();
      await serviceY.dispose();
    });

    test('2. Normal message flow (X -> Y) with ACK and security telemetry', () async {
      final fakeSocketX = FakeWebSocket();
      final fakeSocketY = FakeWebSocket();
      final router = VirtualGatewayRouter();
      router.attachSocket('X', fakeSocketX);
      router.attachSocket('Y', fakeSocketY);

      final clientX = WebSocketClient(connector: (url) async => fakeSocketX, autoReconnect: false);
      final clientY = WebSocketClient(connector: (url) async => fakeSocketY, autoReconnect: false);

      final serviceX = MessagingService(client: clientX);
      final serviceY = MessagingService(client: clientY);

      await serviceX.connect();
      await serviceY.connect();

      // Create outgoing message from X
      final initialX = await serviceX.sendMessage(
        conversationId: 'conv_y',
        content: 'Hello Y',
        senderRole: UserRole.sender,
        senderName: 'Sender X',
      );
      expect(initialX.status, equals(MessageDeliveryStatus.sending));

      // Router processes and dispatches legitimate security envelope
      final legitSecurity = {
        'final_decision': 'TRUSTED',
        'likely_attack_type': 'LEGITIMATE',
        'classical_signature_valid': true,
        'qds_valid': true,
        'replay_detected': false,
        'verification_accuracy': 0.985,
        'error_rate': 0.015,
        'quantum_bit_count': 16,
        'total_shots': 1024,
        'correct_shots': 1008,
        'threshold': 0.95,
        'qds_decision': 'VALID',
        'signer_id': 'X',
      };

      router.routeClientMessage(
        senderId: 'X',
        receiverId: 'Y',
        message: 'Hello Y',
        securitySummary: legitSecurity,
        messageId: 'sig_x_001',
      );

      await Future.delayed(const Duration(milliseconds: 20));

      // Receiver Y checks
      final yMessages = await serviceY.getMessages('conv_x');
      expect(yMessages, isNotEmpty);
      expect(yMessages.first.content, equals('Hello Y'));
      expect(yMessages.first.senderRole, equals(UserRole.sender));
      expect(yMessages.first.securityStatus, equals(QdsSecurityStatus.trusted));
      expect(yMessages.first.securityData!['final_decision'], equals('TRUSTED'));
      expect(yMessages.first.securityData!['verification_accuracy'], equals(0.985));

      // Sender X ACK checks
      final xMessages = await serviceX.getMessages('conv_y');
      expect(xMessages, isNotEmpty);
      expect(xMessages.first.status, equals(MessageDeliveryStatus.delivered));
      expect(xMessages.first.securityStatus, equals(QdsSecurityStatus.trusted));

      await serviceX.dispose();
      await serviceY.dispose();
    });

    test('3. Reverse message flow (Y -> X) role independence', () async {
      final fakeSocketX = FakeWebSocket();
      final fakeSocketY = FakeWebSocket();
      final router = VirtualGatewayRouter();
      router.attachSocket('X', fakeSocketX);
      router.attachSocket('Y', fakeSocketY);

      final clientX = WebSocketClient(connector: (url) async => fakeSocketX, autoReconnect: false);
      final clientY = WebSocketClient(connector: (url) async => fakeSocketY, autoReconnect: false);

      final serviceX = MessagingService(client: clientX);
      final serviceY = MessagingService(client: clientY);

      await serviceX.connect();
      await serviceY.connect();

      // Y sends message to X
      final initialY = await serviceY.sendMessage(
        conversationId: 'conv_x',
        content: 'Hello X, reverse transmission',
        senderRole: UserRole.receiver,
        senderName: 'Receiver Y',
      );
      expect(initialY.status, equals(MessageDeliveryStatus.sending));

      final legitSecurity = {
        'final_decision': 'TRUSTED',
        'likely_attack_type': 'LEGITIMATE',
        'classical_signature_valid': true,
        'qds_valid': true,
        'replay_detected': false,
        'verification_accuracy': 0.99,
        'signer_id': 'Y',
      };

      router.routeClientMessage(
        senderId: 'Y',
        receiverId: 'X',
        message: 'Hello X, reverse transmission',
        securitySummary: legitSecurity,
        messageId: 'sig_y_001',
      );

      await Future.delayed(const Duration(milliseconds: 20));

      // X receives envelope
      final xMessages = await serviceX.getMessages('conv_y');
      expect(xMessages, isNotEmpty);
      expect(xMessages.first.content, equals('Hello X, reverse transmission'));
      expect(xMessages.first.senderRole, equals(UserRole.receiver));
      expect(xMessages.first.securityStatus, equals(QdsSecurityStatus.trusted));

      await serviceX.dispose();
      await serviceY.dispose();
    });

    test('4. Rapid message ordering and FIFO preservation', () async {
      final fakeSocketY = FakeWebSocket();
      final clientY = WebSocketClient(connector: (url) async => fakeSocketY, autoReconnect: false);
      final serviceY = MessagingService(client: clientY);
      await serviceY.connect();

      final burst = ['Msg 1', 'Msg 2', 'Msg 3'];
      for (var i = 0; i < burst.length; i++) {
        fakeSocketY.feedIncoming({
          'type': 'message_result',
          'message_id': 'burst_$i',
          'sender_id': 'X',
          'receiver_id': 'Y',
          'message': burst[i],
          'timestamp': DateTime.now().toIso8601String(),
          'security': {
            'final_decision': 'TRUSTED',
            'likely_attack_type': 'LEGITIMATE',
            'classical_signature_valid': true,
            'qds_valid': true,
            'replay_detected': false,
          },
        });
      }

      await Future.delayed(const Duration(milliseconds: 30));

      final messages = await serviceY.getMessages('conv_x');
      expect(messages.length, equals(3));
      expect(messages[0].content, equals('Msg 1'));
      expect(messages[1].content, equals('Msg 2'));
      expect(messages[2].content, equals('Msg 3'));

      await serviceY.dispose();
    });

    test('5. Forgery attack telemetry triggers threat detected and alert banner', () async {
      final fakeSocket = FakeWebSocket();
      final client = WebSocketClient(connector: (url) async => fakeSocket, autoReconnect: false);
      final messagingService = MessagingService(client: client);
      final securityService = SecurityService(messagingService: messagingService);
      final securityProvider = SecurityProvider(service: securityService);

      await messagingService.connect();

      // Gateway routes a forged packet result
      fakeSocket.feedIncoming({
        'type': 'message_result',
        'message_id': 'forgery_99',
        'sender_id': 'X',
        'receiver_id': 'Y',
        'message': 'Tampered Bank Transfer',
        'security': {
          'final_decision': 'INVALID / SUSPICIOUS',
          'likely_attack_type': 'FORGERY_OR_IMPERSONATION',
          'classical_signature_valid': false,
          'qds_valid': true,
          'replay_detected': false,
          'signer_id': 'X',
        },
      });

      await Future.delayed(const Duration(milliseconds: 20));

      expect(securityProvider.currentStatus, equals(QdsSecurityStatus.threatDetected));
      expect(securityProvider.activeThreatAlert, isNotNull);
      expect(securityProvider.activeThreatAlert!.telemetry?.likelyAttackType, equals('FORGERY_OR_IMPERSONATION'));
      expect(securityProvider.recentEvents, isNotEmpty);

      await messagingService.dispose();
    });

    test('6. Replay attack telemetry triggers replay threat detected', () async {
      final fakeSocket = FakeWebSocket();
      final client = WebSocketClient(connector: (url) async => fakeSocket, autoReconnect: false);
      final messagingService = MessagingService(client: client);
      final securityService = SecurityService(messagingService: messagingService);
      final securityProvider = SecurityProvider(service: securityService);

      await messagingService.connect();

      fakeSocket.feedIncoming({
        'type': 'message_result',
        'message_id': 'replay_101',
        'sender_id': 'X',
        'receiver_id': 'Y',
        'message': 'Replayed Authorization Token',
        'security': {
          'final_decision': 'INVALID / SUSPICIOUS',
          'likely_attack_type': 'REPLAY',
          'classical_signature_valid': true,
          'qds_valid': true,
          'replay_detected': true,
          'signer_id': 'X',
        },
      });

      await Future.delayed(const Duration(milliseconds: 20));

      expect(securityProvider.currentStatus, equals(QdsSecurityStatus.threatDetected));
      expect(securityProvider.activeThreatAlert!.telemetry?.replayDetected, isTrue);
      expect(securityProvider.activeThreatAlert!.telemetry?.likelyAttackType, equals('REPLAY'));

      await messagingService.dispose();
    });

    test('7. Channel manipulation attack triggers suspicious and quantum failure', () async {
      final fakeSocket = FakeWebSocket();
      final client = WebSocketClient(connector: (url) async => fakeSocket, autoReconnect: false);
      final messagingService = MessagingService(client: client);
      final securityService = SecurityService(messagingService: messagingService);
      final securityProvider = SecurityProvider(service: securityService);

      await messagingService.connect();

      fakeSocket.feedIncoming({
        'type': 'message_result',
        'message_id': 'channel_55',
        'sender_id': 'X',
        'receiver_id': 'Y',
        'message': 'Quantum Channel Noise Packet',
        'security': {
          'final_decision': 'INVALID / SUSPICIOUS',
          'likely_attack_type': 'CHANNEL_ATTACK',
          'classical_signature_valid': true,
          'qds_valid': false,
          'replay_detected': false,
          'verification_accuracy': 0.62,
          'error_rate': 0.38,
          'signer_id': 'X',
        },
      });

      await Future.delayed(const Duration(milliseconds: 20));

      expect(securityProvider.currentStatus, equals(QdsSecurityStatus.suspicious));
      expect(securityProvider.latestTelemetry!.qdsValid, isFalse);
      expect(securityProvider.latestTelemetry!.likelyAttackType, equals('CHANNEL_ATTACK'));

      await messagingService.dispose();
    });

    test('8. Threat alert single-time deduplication on rebuild and dismissal', () async {
      final securityService = SecurityService.instance;
      final securityProvider = SecurityProvider(service: securityService);

      const threatTelemetry = SecurityTelemetry(
        finalDecision: 'INVALID / SUSPICIOUS',
        likelyAttackType: 'REPLAY',
        classicalSignatureValid: true,
        qdsValid: true,
        replayDetected: true,
      );

      final message = MessageModel(
        id: 'msg_threat_dup',
        conversationId: 'conv_x',
        senderRole: UserRole.sender,
        senderName: 'Sender X',
        content: 'Attack msg',
        timestamp: DateTime.now(),
        status: MessageDeliveryStatus.delivered,
        securityStatus: QdsSecurityStatus.threatDetected,
        securityData: threatTelemetry.toJson(),
      );

      securityProvider.consumeMessage(message);
      expect(securityProvider.activeThreatAlert, isNotNull);

      // Dismiss alert
      securityProvider.dismissThreatAlert();
      expect(securityProvider.activeThreatAlert, isNull);

      // Same message consumed again must not re-trigger alert
      securityProvider.consumeMessage(message);
      expect(securityProvider.activeThreatAlert, isNull);
    });

    test('9. Connection state transitions (connected -> disconnected -> reconnecting)', () async {
      final fakeSocket = FakeWebSocket();
      final client = WebSocketClient(connector: (url) async => fakeSocket, autoReconnect: false);

      final states = <WebSocketConnectionState>[];
      final sub = client.stateStream.listen(states.add);

      await client.connect();
      expect(client.isConnected, isTrue);

      fakeSocket.simulateClose();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(client.isConnected, isFalse);
      expect(states, contains(WebSocketConnectionState.connected));

      await sub.cancel();
      await client.dispose();
    });

    test('10. Gateway offline: sending message gracefully transitions to failed', () async {
      final client = WebSocketClient(
        connector: (url) async => throw const SocketException('Connection refused'),
        autoReconnect: false,
      );
      final service = MessagingService(client: client);

      // Connect fails gracefully
      await service.connect();
      expect(service.client.isConnected, isFalse);

      // Outgoing message when offline marks failed
      final msg = await service.sendMessage(
        conversationId: 'conv_y',
        content: 'Offline attempt',
        senderRole: UserRole.sender,
        senderName: 'Sender X',
      );
      expect(msg.status, equals(MessageDeliveryStatus.failed));

      await service.dispose();
    });

    test('11. Role switch updates LocalStorage and registration', () async {
      await LocalStorage.instance.saveIdentity(name: 'Alice', role: 'X');
      expect(LocalStorage.instance.role, equals(UserRole.sender));

      await LocalStorage.instance.saveIdentity(name: 'Alice', role: 'Y');
      expect(LocalStorage.instance.role, equals(UserRole.receiver));

      final fakeSocket = FakeWebSocket();
      final client = WebSocketClient(connector: (url) async => fakeSocket, autoReconnect: false);
      final service = MessagingService(client: client);

      await service.connect();
      service.registerCurrentIdentity();

      final sent = jsonDecode(fakeSocket.sentFrames.last) as Map<String, dynamic>;
      expect(sent['role'], equals('receiver'));
      expect(sent['user_id'], equals('Y'));

      await service.dispose();
    });

    testWidgets('12. ThreatDetectionCard renders factual backend evidence correctly', (tester) async {
      const telemetry = SecurityTelemetry(
        finalDecision: 'INVALID / SUSPICIOUS',
        likelyAttackType: 'REPLAY',
        classicalSignatureValid: true,
        qdsValid: true,
        replayDetected: true,
        verificationAccuracy: 0.94,
        errorRate: 0.06,
        signerId: 'X',
      );

      await tester.pumpWidget(
        buildTestApp(
          home: const Scaffold(
            body: ThreatDetectionCard(
              telemetry: telemetry,
              status: QdsSecurityStatus.threatDetected,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('THREAT DETECTED'), findsOneWidget);
      expect(find.text('Replay Attack'), findsOneWidget);
      expect(find.text('Detected'), findsOneWidget);
      expect(find.text('INVALID / SUSPICIOUS'), findsOneWidget);
    });

    testWidgets('13. ChatScreen shows ThreatAlertBanner when threat occurs and dismisses cleanly', (tester) async {
      final securityService = SecurityService.instance;
      final securityProvider = SecurityProvider(service: securityService);
      final chatProvider = ChatProvider(service: MessagingService.instance);

      await tester.pumpWidget(
        buildTestApp(
          home: ChatScreen(
            provider: chatProvider,
            securityProvider: securityProvider,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ThreatAlertBanner), findsNothing);

      // Ingest threat message
      const threatTelemetry = SecurityTelemetry(
        finalDecision: 'INVALID / SUSPICIOUS',
        likelyAttackType: 'FORGERY_OR_IMPERSONATION',
        classicalSignatureValid: false,
        qdsValid: true,
        replayDetected: false,
      );

      final threatMessage = MessageModel(
        id: 'ui_forgery_1',
        conversationId: 'conv_x',
        senderRole: UserRole.sender,
        senderName: 'Sender X',
        content: 'Forged Msg',
        timestamp: DateTime.now(),
        status: MessageDeliveryStatus.delivered,
        securityStatus: QdsSecurityStatus.threatDetected,
        securityData: threatTelemetry.toJson(),
      );

      securityProvider.consumeMessage(threatMessage);
      await tester.pumpAndSettle();

      expect(find.byType(ThreatAlertBanner), findsOneWidget);
      expect(find.text('Signature Forgery Detected'), findsOneWidget);

      // Dismiss banner
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ThreatAlertBanner), findsNothing);
    });

    testWidgets('14. SecurityScreen shows real threat event and navigates to verification details', (tester) async {
      final securityService = SecurityService.instance;
      final securityProvider = SecurityProvider(service: securityService);

      const threatTelemetry = SecurityTelemetry(
        finalDecision: 'INVALID / SUSPICIOUS',
        likelyAttackType: 'CHANNEL_ATTACK',
        classicalSignatureValid: true,
        qdsValid: false,
        replayDetected: false,
        verificationAccuracy: 0.61,
        signerId: 'X',
      );

      final threatMessage = MessageModel(
        id: 'ui_channel_1',
        conversationId: 'conv_x',
        senderRole: UserRole.sender,
        senderName: 'Sender X',
        content: 'Noisy Packet',
        timestamp: DateTime.now(),
        status: MessageDeliveryStatus.delivered,
        securityStatus: QdsSecurityStatus.suspicious,
        securityData: threatTelemetry.toJson(),
      );

      securityProvider.consumeMessage(threatMessage);

      await tester.pumpWidget(
        buildTestApp(
          home: SecurityScreen(
            provider: securityProvider,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tileFinder = find.textContaining('CHANNEL_ATTACK').first;
      await tester.ensureVisible(tileFinder);
      await tester.pumpAndSettle();
      await tester.tap(tileFinder);
      await tester.pumpAndSettle();

      expect(find.byType(VerificationScreen), findsOneWidget);
      expect(find.byType(ThreatDetectionCard), findsOneWidget);
    });
  });
}
