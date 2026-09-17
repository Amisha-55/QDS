import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qds/app/routes.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/models/conversation_model.dart';
import 'package:qds/core/models/security_telemetry.dart';
import 'package:qds/core/models/user_model.dart';
import 'package:qds/core/network/websocket_client.dart';
import 'package:qds/core/services/messaging_service.dart';
import 'package:qds/core/storage/local_storage.dart';
import 'package:qds/features/authentication/screens/setup_screen.dart';
import 'package:qds/features/home/screens/home_screen.dart';
import 'package:qds/features/home/widgets/conversation_tile.dart';
import 'package:qds/features/messaging/providers/chat_provider.dart';
import 'package:qds/features/messaging/screens/chat_screen.dart';
import 'package:qds/features/messaging/widgets/message_input.dart';
import 'package:qds/features/profile/screens/profile_screen.dart';
import 'package:qds/features/security/screens/verification_screen.dart';

class MockWebSocketClient extends WebSocketClient {
  MockWebSocketClient({this.initialState = WebSocketConnectionState.disconnected})
      : super(autoReconnect: false);

  WebSocketConnectionState initialState;
  int connectCallCount = 0;

  @override
  WebSocketConnectionState get state => initialState;

  @override
  Future<void> connect({String? url}) async {
    connectCallCount++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalStorage.instance.init();
    await LocalStorage.instance.saveIdentity(name: 'Alice', role: 'X');
  });

  tearDown(() async {
    await LocalStorage.instance.clearIdentity();
  });

  group('Prompt 14 — UX Polish: Connection Indicator & Banner', () {
    testWidgets('Home screen connection status displays Online when connected', (tester) async {
      final mockClient = MockWebSocketClient(initialState: WebSocketConnectionState.connected);
      final service = MessagingService(client: mockClient);
      final provider = ChatProvider(service: service);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: HomeScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Online'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
    });

    testWidgets('Home screen connection status displays Connecting with spinner', (tester) async {
      final mockClient = MockWebSocketClient(initialState: WebSocketConnectionState.connecting);
      final service = MessagingService(client: mockClient);
      final provider = ChatProvider(service: service);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: HomeScreen(provider: provider),
        ),
      );
      await tester.pump();

      expect(find.text('Connecting'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Home screen connection status displays Reconnecting with spinner', (tester) async {
      final mockClient = MockWebSocketClient(initialState: WebSocketConnectionState.reconnecting);
      final service = MessagingService(client: mockClient);
      final provider = ChatProvider(service: service);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: HomeScreen(provider: provider),
        ),
      );
      await tester.pump();

      expect(find.text('Reconnecting'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Home screen connection status displays Offline when disconnected and triggers connect on tap', (tester) async {
      final mockClient = MockWebSocketClient(initialState: WebSocketConnectionState.disconnected);
      final service = MessagingService(client: mockClient);
      final provider = ChatProvider(service: service);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: HomeScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offline'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);

      await tester.tap(find.text('Offline'));
      await tester.pumpAndSettle();

      expect(mockClient.connectCallCount, greaterThanOrEqualTo(1));
    });

    testWidgets('Home screen connection status displays Retry when failed and triggers connect on tap', (tester) async {
      final mockClient = MockWebSocketClient(initialState: WebSocketConnectionState.failed);
      final service = MessagingService(client: mockClient);
      final provider = ChatProvider(service: service);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: HomeScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(mockClient.connectCallCount, greaterThanOrEqualTo(1));
    });

    testWidgets('Chat screen shows connection banner when offline and retries on tap', (tester) async {
      final mockClient = MockWebSocketClient(initialState: WebSocketConnectionState.disconnected);
      final service = MessagingService(client: mockClient);
      final provider = ChatProvider(service: service);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChatScreen(
            conversation: const ConversationModel(
              id: 'test_c',
              peerName: 'Receiver Y',
              peerRole: UserRole.receiver,
            ),
            provider: provider,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('QDS gateway is offline'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(mockClient.connectCallCount, greaterThanOrEqualTo(1));
    });

    testWidgets('Chat screen hides connection banner when connected', (tester) async {
      final mockClient = MockWebSocketClient(initialState: WebSocketConnectionState.connected);
      final service = MessagingService(client: mockClient);
      final provider = ChatProvider(service: service);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChatScreen(
            conversation: const ConversationModel(
              id: 'test_c',
              peerName: 'Receiver Y',
              peerRole: UserRole.receiver,
            ),
            provider: provider,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('QDS gateway is offline'), findsNothing);
      expect(find.text('Connecting to QDS gateway...'), findsNothing);
    });
  });

  group('Prompt 14 — UX Polish: Message Composer & Send Behavior', () {
    testWidgets('Send button disables and shows progress during send', (tester) async {
      final completer = Completer<void>();
      int sendCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MessageInput(
              onSend: (text) async {
                sendCount++;
                await completer.future;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Quantum test message');
      await tester.pumpAndSettle();

      // Tap send
      await tester.tap(find.byTooltip('Send'));
      await tester.pump(); // Frame during submission

      expect(sendCount, 1);
      // While submitting, progress indicator appears inside button
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Tap again while in progress - should not invoke onSend again
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();

      expect(sendCount, 1);

      // Complete submission
      completer.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('Prompt 14 — UX Polish: Profile Identity Reset Confirmation', () {
    testWidgets('Cancelling reset dialog retains identity', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          routes: {
            AppRoutes.setup: (context) => const SetupScreen(),
          },
          home: const ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Change Role / Reset Identity'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Reset Identity & Role?'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(LocalStorage.instance.displayName, 'Alice');
      expect(LocalStorage.instance.role, UserRole.sender);
    });
  });

  group('Prompt 14 — UX Polish: Responsive Layout Checks', () {
    testWidgets('ConversationTile renders without overflow on narrow 320dp width', (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 600 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const longConv = ConversationModel(
        id: 'long_c',
        peerName: 'Receiver Y with very long research participant identity title',
        peerRole: UserRole.receiver,
        lastMessage: 'Extremely long last message snippet verifying quantum digital signature fidelity measurements',
        unreadCount: 3,
        securityStatus: QdsSecurityStatus.verified,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: ConversationTile(
                  conversation: longConv,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('VerificationScreen renders without overflow on narrow 320dp width', (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 700 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const telemetry = SecurityTelemetry(
        signerId: 'X',
        classicalSignatureValid: true,
        qdsValid: true,
        finalDecision: 'TRUSTED',
        likelyAttackType: 'LEGITIMATE',
        replayDetected: false,
        verificationAccuracy: 0.985,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const VerificationScreen(telemetry: telemetry),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Security Verification'), findsOneWidget);
    });
  });
}
