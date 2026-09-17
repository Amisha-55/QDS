import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qds/app/routes.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/models/message_model.dart';
import 'package:qds/core/models/security_event_model.dart';
import 'package:qds/core/models/security_telemetry.dart';
import 'package:qds/core/models/user_model.dart';
import 'package:qds/core/services/messaging_service.dart';
import 'package:qds/core/services/security_service.dart';
import 'package:qds/core/storage/local_storage.dart';
import 'package:qds/features/security/providers/security_provider.dart';
import 'package:qds/features/security/screens/security_screen.dart';
import 'package:qds/features/security/screens/verification_screen.dart';
import 'package:qds/features/security/widgets/message_security_details_sheet.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await LocalStorage.instance.init();
    await LocalStorage.instance.clear();
    MessagingService.instance.clear();
    SecurityService.instance.clear();
  });

  Widget buildTestApp({
    required Widget home,
    RouteFactory? onGenerateRoute,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      onGenerateRoute: onGenerateRoute ?? AppRoutes.onGenerateRoute,
      home: home,
    );
  }

  group('Security Center Screen', () {
    testWidgets('Displays ready empty state when no telemetry or events exist', (WidgetTester tester) async {
      final provider = SecurityProvider();

      await tester.pumpWidget(
        buildTestApp(
          home: SecurityScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Overall status banner shows monitoring/ready state
      expect(find.text('MONITORING'), findsOneWidget);
      expect(find.text('Security monitoring is ready. Digital signatures will be verified in real time.'), findsOneWidget);

      // Current verification card shows clean empty state
      expect(find.text('No verified messages yet'), findsOneWidget);
      expect(find.text('Cryptographic verification telemetry will appear here once messages are exchanged.'), findsOneWidget);

      // Main empty state illustration
      expect(find.text('Security monitoring is ready'), findsOneWidget);
      expect(find.text('Verified communication activity will appear here as messages are exchanged.'), findsOneWidget);

      // Verify no fake scores exist
      expect(find.textContaining('100/100'), findsNothing);
      expect(find.textContaining('Risk Score'), findsNothing);
      expect(find.textContaining('Threat Level: Low'), findsNothing);

      provider.dispose();
    });

    testWidgets('Displays trusted telemetry and verification activity when telemetry is received', (WidgetTester tester) async {
      final provider = SecurityProvider();

      // Inject trusted message
      final msg = MessageModel(
        id: 'msg-001',
        conversationId: 'conv_1',
        senderRole: UserRole.sender,
        senderName: 'Sender X',
        content: 'Secure Hello',
        timestamp: DateTime.now(),
        securityData: {
          'final_decision': 'TRUSTED',
          'likely_attack_type': 'LEGITIMATE',
          'classical_signature_valid': true,
          'qds_valid': true,
          'replay_detected': false,
          'verification_accuracy': 0.992,
          'error_rate': 0.008,
          'total_shots': 1024,
          'correct_shots': 1016,
          'threshold': 0.85,
          'qds_decision': 'ACCEPT',
          'signer_id': 'X',
        },
      );

      SecurityService.instance.processMessageSecurity(msg);

      await tester.pumpWidget(
        buildTestApp(
          home: SecurityScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Overall status banner
      expect(find.text('TRUSTED'), findsWidgets);
      expect(find.text('Recent communication passed cryptographic and QDS verification.'), findsOneWidget);

      // Current Verification Card displays real telemetry metrics
      expect(find.text('Classical Signature'), findsOneWidget);
      expect(find.text('Valid'), findsWidgets);
      expect(find.text('QDS Verification'), findsOneWidget);
      expect(find.text('Replay Detection'), findsOneWidget);
      expect(find.text('Not detected'), findsOneWidget);
      expect(find.text('Verification Accuracy'), findsOneWidget);
      expect(find.text('99.2%'), findsOneWidget);
      expect(find.text('View verification details'), findsOneWidget);

      // Aggregate verification activity card
      expect(find.text('Verification Activity'), findsOneWidget);

      // Filter chips are present
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Verified'), findsWidgets);

      provider.dispose();
    });

    testWidgets('Displays warning / suspicious banner when attack telemetry is received', (WidgetTester tester) async {
      final provider = SecurityProvider();

      // Inject replay attack message
      final msg = MessageModel(
        id: 'msg-attack-001',
        conversationId: 'conv_1',
        senderRole: UserRole.sender,
        senderName: 'Attacker X',
        content: 'Replayed message',
        timestamp: DateTime.now(),
        securityData: {
          'final_decision': 'INVALID / SUSPICIOUS',
          'likely_attack_type': 'REPLAY',
          'classical_signature_valid': true,
          'qds_valid': false,
          'replay_detected': true,
          'verification_accuracy': 0.620,
          'error_rate': 0.380,
          'total_shots': 1024,
          'correct_shots': 635,
          'threshold': 0.85,
          'qds_decision': 'INVALID',
          'signer_id': 'X',
        },
      );

      SecurityService.instance.processMessageSecurity(msg);

      await tester.pumpWidget(
        buildTestApp(
          home: SecurityScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Status banner shows threat detected for replay attack
      expect(find.text('THREAT DETECTED'), findsWidgets);
      expect(find.text('Critical: Quantum-inspired security violation or signature replay detected.'), findsOneWidget);

      // Current Verification Card displays replay detected and invalid QDS
      expect(find.text('Replay detected'), findsOneWidget);
      expect(find.text('Invalid'), findsWidgets); // QDS Invalid
      expect(find.text('62.0%'), findsOneWidget); // Accuracy

      provider.dispose();
    });

    testWidgets('Filter chips toggle event list correctly', (WidgetTester tester) async {
      final provider = SecurityProvider();

      // Inject 1 trusted message and 1 replay message
      final trustedMsg = MessageModel(
        id: 'msg-trusted',
        conversationId: 'conv_1',
        senderRole: UserRole.sender,
        senderName: 'Sender X',
        content: 'Trusted Content',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        securityData: {
          'final_decision': 'TRUSTED',
          'likely_attack_type': 'LEGITIMATE',
          'classical_signature_valid': true,
          'qds_valid': true,
          'replay_detected': false,
          'verification_accuracy': 0.99,
          'signer_id': 'X',
        },
      );
      final threatMsg = MessageModel(
        id: 'msg-threat',
        conversationId: 'conv_1',
        senderRole: UserRole.sender,
        senderName: 'Eve X',
        content: 'Threat Content',
        timestamp: DateTime.now(),
        securityData: {
          'final_decision': 'INVALID / SUSPICIOUS',
          'likely_attack_type': 'REPLAY',
          'classical_signature_valid': true,
          'qds_valid': false,
          'replay_detected': true,
          'verification_accuracy': 0.60,
          'signer_id': 'X',
        },
      );

      SecurityService.instance.processMessageSecurity(trustedMsg);
      SecurityService.instance.processMessageSecurity(threatMsg);

      await tester.pumpWidget(
        buildTestApp(
          home: SecurityScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Filter chips show labels
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Verified'), findsWidgets);
      expect(find.text('Threats'), findsWidgets);

      // Scroll chip into view and tap 'Threats' filter chip
      final threatsChip = find.widgetWithText(ChoiceChip, 'Threats');
      await tester.ensureVisible(threatsChip);
      await tester.tap(threatsChip);
      await tester.pumpAndSettle();

      // Replay attack event is visible
      final eventTile = find.text('Cryptographic signature replay detected for packet.');
      await tester.ensureVisible(eventTile);
      expect(eventTile, findsOneWidget);

      provider.dispose();
    });
  });

  group('Verification Details Screen', () {
    testWidgets('Renders all real telemetry fields accurately', (WidgetTester tester) async {
      const telemetry = SecurityTelemetry(
        finalDecision: 'TRUSTED',
        likelyAttackType: 'LEGITIMATE',
        classicalSignatureValid: true,
        qdsValid: true,
        replayDetected: false,
        verificationAccuracy: 0.984,
        errorRate: 0.016,
        quantumBitCount: 64,
        totalShots: 1024,
        correctShots: 1008,
        threshold: 0.85,
        qdsDecision: 'ACCEPT',
        signerId: 'X',
      );

      final event = SecurityEventModel(
        id: 'evt-test-1',
        messageId: 'msg-evidence-001',
        timestamp: DateTime(2026, 9, 17, 14, 30),
        status: QdsSecurityStatus.trusted,
        summary: 'Cryptographic signature and quantum verification successful',
        telemetry: telemetry,
        signerId: 'X',
        attackType: 'LEGITIMATE',
      );

      await tester.pumpWidget(
        buildTestApp(
          home: VerificationScreen(
            telemetry: telemetry,
            event: event,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Screen title and headers
      expect(find.text('Verification Details'), findsOneWidget);
      expect(find.text('Security Verification'), findsOneWidget);
      expect(find.text('Message Information'), findsOneWidget);
      expect(find.text('msg-evidence-001'), findsOneWidget);

      // Classical signature
      expect(find.text('Classical Signature'), findsOneWidget);
      expect(find.text('Valid'), findsWidgets);

      // QDS verification
      expect(find.text('QDS Verification'), findsOneWidget);

      // Replay check
      expect(find.text('Replay Protection'), findsOneWidget);
      expect(find.text('Not detected'), findsOneWidget);

      // Attack classification
      expect(find.text('Attack Classification'), findsOneWidget);
      expect(find.text('Legitimate (None)'), findsOneWidget);

      // Quantum Telemetry section
      expect(find.text('Quantum Telemetry'), findsOneWidget);
      expect(find.text('98.4%'), findsOneWidget);
      expect(find.text('1.6%'), findsOneWidget);
      expect(find.text('1008 / 1024 correct'), findsOneWidget);
      expect(find.text('64 qubits'), findsOneWidget);
      expect(find.text('0.85'), findsOneWidget);
    });

    testWidgets('Handles missing / null telemetry gracefully without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          home: const VerificationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verification Details'), findsOneWidget);
      expect(find.text('Unavailable'), findsWidgets);
    });
  });

  group('Navigation to Verification Details', () {
    testWidgets('Tapping "View verification details" on Security Center navigates to VerificationScreen', (WidgetTester tester) async {
      final provider = SecurityProvider();

      final msg = MessageModel(
        id: 'msg-nav-test',
        conversationId: 'conv_1',
        senderRole: UserRole.sender,
        senderName: 'Sender X',
        content: 'Test Nav',
        timestamp: DateTime.now(),
        securityData: {
          'final_decision': 'TRUSTED',
          'likely_attack_type': 'LEGITIMATE',
          'classical_signature_valid': true,
          'qds_valid': true,
          'replay_detected': false,
          'verification_accuracy': 0.995,
          'signer_id': 'X',
        },
      );

      SecurityService.instance.processMessageSecurity(msg);

      await tester.pumpWidget(
        buildTestApp(
          home: SecurityScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Tap View verification details
      await tester.tap(find.text('View verification details'));
      await tester.pumpAndSettle();

      // Verifies we reached VerificationScreen
      expect(find.byType(VerificationScreen), findsOneWidget);
      expect(find.text('Verification Details'), findsOneWidget);
      expect(find.text('Classical Signature'), findsOneWidget);

      provider.dispose();
    });

    testWidgets('Tapping "View Full Verification Details" in MessageSecurityDetailsSheet navigates to VerificationScreen', (WidgetTester tester) async {
      const telemetry = SecurityTelemetry(
        finalDecision: 'TRUSTED',
        likelyAttackType: 'LEGITIMATE',
        classicalSignatureValid: true,
        qdsValid: true,
        replayDetected: false,
        verificationAccuracy: 0.99,
        signerId: 'X',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const MessageSecurityDetailsSheet(
                          telemetry: telemetry,
                          messageSnippet: 'msg-sheet-test',
                        ),
                      );
                    },
                    child: const Text('Open Sheet'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('View Full Verification Details'), findsOneWidget);

      // Tap full verification details button
      await tester.tap(find.text('View Full Verification Details'));
      await tester.pumpAndSettle();

      // Verifies navigation to VerificationScreen
      expect(find.byType(VerificationScreen), findsOneWidget);
      expect(find.text('Verification Details'), findsOneWidget);
    });
  });
}
