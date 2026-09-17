import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qds/app/app.dart';
import 'package:qds/app/routes.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/models/conversation_model.dart';
import 'package:qds/core/models/message_model.dart';
import 'package:qds/core/models/user_model.dart';
import 'package:qds/core/services/messaging_service.dart';
import 'package:qds/core/storage/local_storage.dart';
import 'package:qds/features/authentication/screens/setup_screen.dart';
import 'package:qds/features/home/screens/home_screen.dart';
import 'package:qds/features/messaging/screens/chat_screen.dart';
import 'package:qds/features/messaging/screens/conversation_info_screen.dart';
import 'package:qds/features/messaging/widgets/chat_app_bar.dart';
import 'package:qds/features/messaging/widgets/message_bubble.dart';
import 'package:qds/features/messaging/widgets/message_input.dart';
import 'package:qds/features/messaging/widgets/message_status.dart';
import 'package:qds/features/onboarding/screens/onboarding_screen.dart';
import 'package:qds/features/onboarding/screens/splash_screen.dart';
import 'package:qds/features/profile/screens/profile_screen.dart';
import 'package:qds/shared/widgets/app_button.dart';
import 'package:qds/shared/widgets/security_badge.dart';

void main() {
  setUp(() async {
    await LocalStorage.instance.init();
    await LocalStorage.instance.clear();
    MessagingService.instance.clear();
  });

  group('Splash & Onboarding Tests', () {
    testWidgets('Splash screen renders QDS branding and tagline', (WidgetTester tester) async {
      await tester.pumpWidget(const QdsApp());
      await tester.pump();

      expect(find.text('QDS'), findsOneWidget);
      expect(find.text('Secure communication. Verified by design.'), findsOneWidget);
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('Onboarding screen renders and steps through pages', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Private conversations'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Tap Continue to go to Page 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Verified communication'), findsOneWidget);

      // Tap Continue to go to Page 3
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Security when it matters'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('Onboarding skip persists completion and navigates to setup', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          initialRoute: AppRoutes.onboarding,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      );
      await tester.pumpAndSettle();

      expect(LocalStorage.instance.isOnboardingCompleted, isFalse);

      // Tap Skip
      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(LocalStorage.instance.isOnboardingCompleted, isTrue);
      expect(find.byType(SetupScreen), findsOneWidget);
    });
  });

  group('Identity Setup (X/Y) Tests', () {
    testWidgets('Setup screen renders title, role options, and display name input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SetupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Set up your QDS identity'), findsOneWidget);
      expect(find.text('X • Sender'), findsOneWidget);
      expect(find.text('Y • Receiver'), findsOneWidget);
      expect(find.text('Enter your name'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('Roles X and Y can be selected and only one is active at a time', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SetupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Initially neither card is selected (radio button is off)
      expect(find.byIcon(Icons.radio_button_checked_rounded), findsNothing);

      // Select X
      await tester.tap(find.text('X • Sender'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);

      // Select Y
      await tester.tap(find.text('Y • Receiver'));
      await tester.pumpAndSettle();

      // Still only one active radio button
      expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
    });

    testWidgets('Empty display name prevents continuation even if role is selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          routes: {
            '/': (context) => const SetupScreen(),
            AppRoutes.home: (context) => const HomeScreen(),
          },
        ),
      );
      await tester.pumpAndSettle();

      // Select role X
      await tester.tap(find.text('X • Sender'));
      await tester.pumpAndSettle();

      // Continue button should be disabled
      final appButton = tester.widget<AppButton>(find.byType(AppButton));
      expect(appButton.onPressed, isNull);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Setup screen still active, home not navigated to
      expect(find.byType(SetupScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('Valid display name and role allow continuation and persist identity', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          initialRoute: AppRoutes.setup,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      );
      await tester.pumpAndSettle();

      // Select role X
      await tester.tap(find.text('X • Sender'));
      await tester.pumpAndSettle();

      // Enter display name
      await tester.enterText(find.byType(TextFormField), 'Alice');
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Assert persistence
      expect(LocalStorage.instance.isSetupCompleted, isTrue);
      expect(LocalStorage.instance.userRole, 'X');
      expect(LocalStorage.instance.displayName, 'Alice');

      // Assert navigated to Home
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('Home & Returning User Routing Tests', () {
    testWidgets('Home screen displays the stored identity, role, and security status', (WidgetTester tester) async {
      await LocalStorage.instance.saveIdentity(name: 'Bob', role: 'Y');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome, Bob'), findsOneWidget);
      expect(find.text('Role: Y (Receiver)'), findsOneWidget);
      expect(find.text('Security ready'), findsOneWidget);
      expect(find.text('No conversations yet'), findsOneWidget);
      expect(find.text('Start a secure conversation to begin.'), findsOneWidget);
    });

    testWidgets('Returning user with completed setup bypasses onboarding and setup', (WidgetTester tester) async {
      await LocalStorage.instance.setOnboardingCompleted(true);
      await LocalStorage.instance.saveIdentity(name: 'Carol', role: 'X');

      await tester.pumpWidget(const QdsApp());
      await tester.pump();

      // Advance past splash timer (1800ms) and route transition (250ms)
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Welcome, Carol'), findsOneWidget);
    });

    testWidgets('Profile screen displays identity and allows resetting', (WidgetTester tester) async {
      await LocalStorage.instance.saveIdentity(name: 'Dave', role: 'X');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          initialRoute: AppRoutes.profile,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Dave'), findsOneWidget);
      expect(find.text('X • Sender'), findsOneWidget);
      expect(find.text('Change Role / Reset Identity'), findsOneWidget);

      // Tap Reset
      // Tap Reset - shows confirmation dialog
      await tester.tap(find.text('Change Role / Reset Identity'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Reset Identity & Role?'), findsOneWidget);

      // Confirm reset
      await tester.tap(find.text('Reset Identity'));
      await tester.pumpAndSettle();

      expect(LocalStorage.instance.isSetupCompleted, isFalse);
      expect(find.byType(SetupScreen), findsOneWidget);
    });
  });

  group('Messaging UI Tests', () {
    testWidgets('Chat screen renders with app bar and message composer', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ChatScreen(
            conversation: ConversationModel(
              id: 'test_conv',
              peerName: 'Receiver Y',
              peerRole: UserRole.receiver,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.byType(ChatAppBar), findsOneWidget);
      expect(find.byType(MessageInput), findsOneWidget);
    });

    testWidgets('Empty conversation state renders when there are no messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ChatScreen(
            conversation: ConversationModel(
              id: 'empty_conv',
              peerName: 'Receiver Y',
              peerRole: UserRole.receiver,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No messages yet'), findsOneWidget);
      expect(
        find.text('Send a message to start communicating with Receiver Y.'),
        findsOneWidget,
      );
    });

    testWidgets('Message bubbles correctly distinguish local and remote messages', (WidgetTester tester) async {
      final msg = MessageModel(
        id: 'msg_1',
        conversationId: 'conv_1',
        senderRole: UserRole.sender,
        senderName: 'Alice',
        content: 'Hello secure world',
        timestamp: DateTime(2026, 9, 17, 10, 0),
        status: MessageDeliveryStatus.sent,
      );

      // Local message
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MessageBubble(message: msg, isMe: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final localAlign = tester.widget<Align>(
        find.ancestor(of: find.text('Hello secure world'), matching: find.byType(Align)),
      );
      expect(localAlign.alignment, Alignment.centerRight);
      expect(find.byType(MessageStatusWidget), findsOneWidget);

      // Remote message
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MessageBubble(message: msg, isMe: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final remoteAlign = tester.widget<Align>(
        find.ancestor(of: find.text('Hello secure world'), matching: find.byType(Align)),
      );
      expect(remoteAlign.alignment, Alignment.centerLeft);
      expect(find.byType(MessageStatusWidget), findsNothing);
    });

    testWidgets('Message text renders correctly', (WidgetTester tester) async {
      final msg = MessageModel(
        id: 'msg_2',
        conversationId: 'conv_1',
        senderRole: UserRole.sender,
        senderName: 'Alice',
        content: 'Payload: 0xDEADBEEF signature verification check',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MessageBubble(message: msg, isMe: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payload: 0xDEADBEEF signature verification check'), findsOneWidget);
    });

    testWidgets('Message timestamp renders when provided', (WidgetTester tester) async {
      final testTime = DateTime(2026, 9, 17, 14, 30);
      final msg = MessageModel(
        id: 'msg_3',
        conversationId: 'conv_1',
        senderRole: UserRole.receiver,
        senderName: 'Bob',
        content: 'Timestamped packet',
        timestamp: testTime,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MessageBubble(message: msg, isMe: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2:30 PM'), findsOneWidget);
    });

    testWidgets('Composer renders with text field and hint', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MessageInput(onSend: (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Type a message...'), findsOneWidget);
      expect(find.byTooltip('Send'), findsOneWidget);
    });

    testWidgets('Empty/whitespace message cannot be sent', (WidgetTester tester) async {
      String? sentText;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MessageInput(onSend: (text) => sentText = text),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially empty: button disabled
      final initialButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(initialButton.onPressed, isNull);

      // Enter whitespace only
      await tester.enterText(find.byType(TextField), '    ');
      await tester.pumpAndSettle();

      final whitespaceButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(whitespaceButton.onPressed, isNull);

      // Try tapping send anyway
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(sentText, isNull);
    });

    testWidgets('Send action is exposed correctly for later integration', (WidgetTester tester) async {
      String? sentText;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MessageInput(onSend: (text) => sentText = text),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter valid message
      await tester.enterText(find.byType(TextField), 'QDS Quantum Key Exchange Test');
      await tester.pumpAndSettle();

      final activeSendButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(activeSendButton.onPressed, isNotNull);

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(sentText, 'QDS Quantum Key Exchange Test');
      expect(find.text('QDS Quantum Key Exchange Test'), findsNothing); // Text field cleared
    });

    // 9. Chat app bar renders peer information
    testWidgets('Chat app bar renders peer information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            appBar: ChatAppBar(
              peerName: 'Receiver Y',
              peerRole: UserRole.receiver,
              securityStatus: QdsSecurityStatus.trusted,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Receiver Y'), findsOneWidget);
      expect(find.text('Y • Receiver'), findsOneWidget);
      expect(find.byType(SecurityBadge), findsOneWidget);
    });

    // 10. Conversation information screen renders
    testWidgets('Conversation information screen renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ConversationInfoScreen(
            conversation: ConversationModel(
              id: 'conv_info_test',
              peerName: 'Receiver Y',
              peerRole: UserRole.receiver,
              securityStatus: QdsSecurityStatus.trusted,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Conversation Info'), findsOneWidget);
      expect(find.text('Receiver Y'), findsOneWidget);
      expect(find.text('Demonstration Role: Receiver (Y)'), findsOneWidget);
      expect(find.text('Security Layer Status'), findsOneWidget);
      expect(find.text('Signature Verification'), findsOneWidget);
    });

    // 11. Home empty conversation state remains correct when there are no conversations
    testWidgets('Home empty conversation state remains correct when there are no conversations', (WidgetTester tester) async {
      await LocalStorage.instance.saveIdentity(name: 'Sender Alice', role: 'X');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No conversations yet'), findsOneWidget);
      expect(find.text('Start a secure conversation to begin.'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    });
  });
}
