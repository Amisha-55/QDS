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
import 'package:qds/features/messaging/widgets/message_bubble.dart';
import 'package:qds/features/security/providers/security_provider.dart';
import 'package:qds/features/security/screens/security_screen.dart';
import 'package:qds/features/security/screens/verification_screen.dart';
import 'package:qds/features/security/utils/attack_presentation_helper.dart';
import 'package:qds/features/security/widgets/threat_alert_banner.dart';
import 'package:qds/features/security/widgets/threat_detection_card.dart';

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
      home: Scaffold(body: home),
    );
  }

  group('Prompt 12 — Threat Detection & Attack Evidence Tests', () {
    testWidgets('1. Legitimate message displays verified state in MessageBubble', (WidgetTester tester) async {
      final msg = MessageModel(
        id: 'msg_legit_1',
        conversationId: 'conv_1',
        senderRole: UserRole.sender,
        senderName: 'Alice',
        content: 'Normal message',
        timestamp: DateTime.now(),
        securityStatus: QdsSecurityStatus.trusted,
        securityData: const {
          'final_decision': 'TRUSTED',
          'likely_attack_type': 'LEGITIMATE',
          'classical_signature_valid': true,
          'qds_valid': true,
          'replay_detected': false,
        },
      );

      await tester.pumpWidget(
        buildTestApp(
          home: MessageBubble(message: msg, isMe: false),
        ),
      );
      await tester.pumpAndSettle();

      // Clean normal message: Shows "Verified" with check icon, no large threat banners
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Normal message'), findsOneWidget);
      expect(find.text('Security warning'), findsNothing);
      expect(find.text('Verification failed'), findsNothing);
    });

    testWidgets('2. Replay telemetry displays replay threat', (WidgetTester tester) async {
      const telemetry = SecurityTelemetry(
        finalDecision: 'INVALID / SUSPICIOUS',
        likelyAttackType: 'REPLAY',
        classicalSignatureValid: true,
        qdsValid: false,
        replayDetected: true,
        signerId: 'X',
      );

      final status = SecurityService.mapTelemetryToSecurityStatus(telemetry);
      expect(status, equals(QdsSecurityStatus.threatDetected));

      await tester.pumpWidget(
        buildTestApp(
          home: const ThreatDetectionCard(
            telemetry: telemetry,
            status: QdsSecurityStatus.threatDetected,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('THREAT DETECTED'), findsOneWidget);
      expect(find.text('Replay Attack'), findsOneWidget);
      expect(find.textContaining('Replay detection flagged this message'), findsOneWidget);
      expect(find.text('Detected'), findsOneWidget);
      expect(find.text('INVALID / SUSPICIOUS'), findsOneWidget);
    });

    testWidgets('3. Forgery/impersonation telemetry displays threat', (WidgetTester tester) async {
      const telemetry = SecurityTelemetry(
        finalDecision: 'INVALID / SUSPICIOUS',
        likelyAttackType: 'FORGERY_OR_IMPERSONATION',
        classicalSignatureValid: false,
        qdsValid: true,
        replayDetected: false,
        signerId: 'Mallory',
      );

      final status = SecurityService.mapTelemetryToSecurityStatus(telemetry);
      expect(status, equals(QdsSecurityStatus.threatDetected));

      await tester.pumpWidget(
        buildTestApp(
          home: const ThreatDetectionCard(
            telemetry: telemetry,
            status: QdsSecurityStatus.threatDetected,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('THREAT DETECTED'), findsOneWidget);
      expect(find.text('Forgery / Impersonation'), findsOneWidget);
      expect(find.text('Mallory'), findsOneWidget);
      expect(find.text('Invalid'), findsOneWidget); // Classical signature invalid
    });

    testWidgets('4. Channel attack telemetry displays suspicious state with quantum evidence', (WidgetTester tester) async {
      const telemetry = SecurityTelemetry(
        finalDecision: 'INVALID / SUSPICIOUS',
        likelyAttackType: 'CHANNEL_ATTACK',
        classicalSignatureValid: true,
        qdsValid: false,
        replayDetected: false,
        verificationAccuracy: 0.612,
        errorRate: 0.388,
        threshold: 0.85,
        signerId: 'X',
      );

      final status = SecurityService.mapTelemetryToSecurityStatus(telemetry);
      expect(status, equals(QdsSecurityStatus.suspicious));

      await tester.pumpWidget(
        buildTestApp(
          home: const ThreatDetectionCard(
            telemetry: telemetry,
            status: QdsSecurityStatus.suspicious,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SUSPICIOUS'), findsOneWidget);
      expect(find.text('Channel Attack'), findsOneWidget);
      expect(find.text('61.2%'), findsOneWidget); // Accuracy
      expect(find.text('38.8%'), findsOneWidget); // Error rate
      expect(find.text('0.85'), findsOneWidget); // Threshold
      expect(find.text('Valid'), findsOneWidget); // Classical signature valid while QDS failed
    });

    testWidgets('5. Invalid classical signature displays appropriate warning/threat state', (WidgetTester tester) async {
      const telemetry = SecurityTelemetry(
        finalDecision: 'INVALID',
        classicalSignatureValid: false,
        qdsValid: true,
        replayDetected: false,
      );

      final status = SecurityService.mapTelemetryToSecurityStatus(telemetry);
      expect(status, equals(QdsSecurityStatus.suspicious));

      final explanation = AttackPresentationHelper.getFactualExplanation(telemetry, status);
      expect(explanation, contains('Classical signature verification failed.'));
    });

    testWidgets('6. Invalid QDS displays verification failure in MessageBubble', (WidgetTester tester) async {
      const telemetry = SecurityTelemetry(
        finalDecision: 'INVALID',
        classicalSignatureValid: true,
        qdsValid: false,
        qdsDecision: 'INVALID',
        replayDetected: false,
      );

      final status = SecurityService.mapTelemetryToSecurityStatus(telemetry);
      expect(status, equals(QdsSecurityStatus.verificationFailed));

      final msg = MessageModel(
        id: 'msg_fail_1',
        conversationId: 'conv_1',
        senderRole: UserRole.sender,
        senderName: 'Alice',
        content: 'Corrupted quantum packet',
        timestamp: DateTime.now(),
        securityStatus: status,
        securityData: const {
          'final_decision': 'INVALID',
          'classical_signature_valid': true,
          'qds_valid': false,
          'qds_decision': 'INVALID',
        },
      );

      await tester.pumpWidget(
        buildTestApp(
          home: MessageBubble(message: msg, isMe: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verification failed'), findsOneWidget);
    });

    testWidgets('7. Unknown attack type renders safely without crashing', (WidgetTester tester) async {
      const telemetry = SecurityTelemetry(
        likelyAttackType: 'FUTURE_QUANTUM_SIDE_CHANNEL',
        finalDecision: 'UNKNOWN_DECISION',
      );

      final formatted = AttackPresentationHelper.formatAttackType(telemetry.likelyAttackType);
      expect(formatted, equals('Future Quantum Side Channel'));

      await tester.pumpWidget(
        buildTestApp(
          home: const ThreatDetectionCard(
            telemetry: telemetry,
            status: QdsSecurityStatus.warning,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Future Quantum Side Channel'), findsOneWidget);
      expect(find.text('FUTURE_QUANTUM_SIDE_CHANNEL'), findsOneWidget);
    });

    testWidgets('8. ThreatDetectionCard displays actual evidence', (WidgetTester tester) async {
      const telemetry = SecurityTelemetry(
        finalDecision: 'INVALID / SUSPICIOUS',
        likelyAttackType: 'REPLAY',
        classicalSignatureValid: true,
        qdsValid: false,
        replayDetected: true,
        signerId: 'Sender_Alice',
      );

      await tester.pumpWidget(
        buildTestApp(
          home: const ThreatDetectionCard(
            telemetry: telemetry,
            status: QdsSecurityStatus.threatDetected,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Attack Classification'), findsOneWidget);
      expect(find.text('REPLAY'), findsOneWidget);
      expect(find.text('Replay Detection'), findsOneWidget);
      expect(find.text('Detected'), findsOneWidget);
      expect(find.text('Signer'), findsOneWidget);
      expect(find.text('Sender_Alice'), findsOneWidget);
    });

    testWidgets('9. Threat alert banner appears for a new event', (WidgetTester tester) async {
      final provider = SecurityProvider();

      final msg = MessageModel(
        id: 'msg_threat_alert',
        conversationId: 'conv_1',
        senderRole: UserRole.sender,
        senderName: 'Eve',
        content: 'Attack packet',
        timestamp: DateTime.now(),
        securityData: const {
          'final_decision': 'INVALID / SUSPICIOUS',
          'likely_attack_type': 'REPLAY',
          'replay_detected': true,
        },
      );

      SecurityService.instance.processMessageSecurity(msg);

      expect(provider.activeThreatAlert, isNotNull);
      expect(provider.activeThreatAlert!.attackType, equals('REPLAY'));

      await tester.pumpWidget(
        buildTestApp(
          home: ThreatAlertBanner(
            event: provider.activeThreatAlert!,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Replay Detected'), findsOneWidget);
      expect(find.text('View Details'), findsOneWidget);

      provider.dispose();
    });

    testWidgets('10. Same event does not repeatedly trigger alerts after dismissal', (WidgetTester tester) async {
      final provider = SecurityProvider();

      final msg = MessageModel(
        id: 'msg_threat_single',
        conversationId: 'conv_1',
        senderRole: UserRole.sender,
        senderName: 'Eve',
        content: 'Attack packet',
        timestamp: DateTime.now(),
        securityData: const {
          'final_decision': 'INVALID / SUSPICIOUS',
          'likely_attack_type': 'REPLAY',
          'replay_detected': true,
        },
      );

      SecurityService.instance.processMessageSecurity(msg);

      expect(provider.activeThreatAlert, isNotNull);

      // Dismiss the threat alert
      provider.dismissThreatAlert();

      // activeThreatAlert is now null for this same event ID
      expect(provider.activeThreatAlert, isNull);

      provider.dispose();
    });

    testWidgets('11. Security event navigates to VerificationScreen on tap', (WidgetTester tester) async {
      const telemetry = SecurityTelemetry(
        finalDecision: 'INVALID / SUSPICIOUS',
        likelyAttackType: 'REPLAY',
        replayDetected: true,
      );

      final event = SecurityEventModel(
        id: 'evt_nav_test',
        messageId: 'msg_nav_test',
        timestamp: DateTime.now(),
        status: QdsSecurityStatus.threatDetected,
        attackType: 'REPLAY',
        summary: 'Replay detected',
        telemetry: telemetry,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: Scaffold(
            body: ThreatAlertBanner(
              event: event,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Details'));
      await tester.pumpAndSettle();

      expect(find.byType(VerificationScreen), findsOneWidget);
      expect(find.text('Verification Details'), findsOneWidget);
    });

    testWidgets('12. Empty threat history displays correct session-scoped empty state', (WidgetTester tester) async {
      final provider = SecurityProvider();

      // Ingest only a legitimate message so total events > 0, but threat events = 0
      final legitMsg = MessageModel(
        id: 'msg_legit_empty_test',
        conversationId: 'conv_1',
        senderRole: UserRole.sender,
        senderName: 'Alice',
        content: 'Legit',
        timestamp: DateTime.now(),
        securityData: const {
          'final_decision': 'TRUSTED',
          'likely_attack_type': 'LEGITIMATE',
          'classical_signature_valid': true,
          'qds_valid': true,
          'replay_detected': false,
        },
      );

      SecurityService.instance.processMessageSecurity(legitMsg);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: SecurityScreen(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      // Select 'Threats' filter
      final threatsChip = find.widgetWithText(ChoiceChip, 'Threats');
      await tester.ensureVisible(threatsChip);
      await tester.tap(threatsChip);
      await tester.pumpAndSettle();

      // Displays session-scoped empty state
      expect(find.text('No threats detected'), findsOneWidget);
      expect(find.text('No threat events have been recorded during this session.'), findsOneWidget);

      provider.dispose();
    });

    testWidgets('13. Long attack type does not overflow', (WidgetTester tester) async {
      const telemetry = SecurityTelemetry(
        likelyAttackType: 'VERY_LONG_COMPLEX_DISTRIBUTED_QUANTUM_SIDE_CHANNEL_ATTACK_CLASSIFICATION_VERSION_4',
        finalDecision: 'INVALID / SUSPICIOUS',
        verificationAccuracy: 0.421,
      );

      await tester.pumpWidget(
        buildTestApp(
          home: const ThreatDetectionCard(
            telemetry: telemetry,
            status: QdsSecurityStatus.threatDetected,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('14. Missing telemetry fields display "Unavailable"', (WidgetTester tester) async {
      const telemetry = SecurityTelemetry();

      await tester.pumpWidget(
        buildTestApp(
          home: const ThreatDetectionCard(
            telemetry: telemetry,
            status: QdsSecurityStatus.warning,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unavailable'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
