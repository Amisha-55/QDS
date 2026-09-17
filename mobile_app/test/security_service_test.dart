import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/models/message_model.dart';
import 'package:qds/core/models/security_telemetry.dart';
import 'package:qds/core/models/user_model.dart';
import 'package:qds/core/services/messaging_service.dart';
import 'package:qds/core/services/security_service.dart';
import 'package:qds/core/storage/local_storage.dart';
import 'package:qds/features/security/providers/security_provider.dart';
import 'package:qds/features/security/widgets/message_security_details_sheet.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await LocalStorage.instance.init();
    await LocalStorage.instance.clear();
    MessagingService.instance.clear();
    SecurityService.instance.clear();
  });

  group('SecurityTelemetry Model Parsing & Robustness', () {
    test('Correctly parses all 12 backend telemetry fields', () {
      final json = {
        'final_decision': 'TRUSTED',
        'likely_attack_type': 'LEGITIMATE',
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
      };

      final telemetry = SecurityTelemetry.fromJson(json);

      expect(telemetry.finalDecision, equals('TRUSTED'));
      expect(telemetry.likelyAttackType, equals('LEGITIMATE'));
      expect(telemetry.classicalSignatureValid, isTrue);
      expect(telemetry.qdsValid, isTrue);
      expect(telemetry.replayDetected, isFalse);
      expect(telemetry.verificationAccuracy, equals(0.995));
      expect(telemetry.errorRate, equals(0.005));
      expect(telemetry.quantumBitCount, equals(64));
      expect(telemetry.totalShots, equals(1024));
      expect(telemetry.correctShots, equals(1018));
      expect(telemetry.threshold, equals(0.85));
      expect(telemetry.qdsDecision, equals('ACCEPT'));
      expect(telemetry.signerId, equals('X'));

      // Display helpers
      expect(telemetry.displayVerificationAccuracy, equals('99.5%'));
      expect(telemetry.displayErrorRate, equals('0.5%'));
      expect(telemetry.displayShots, equals('1018 / 1024'));
      expect(telemetry.displayClassicalSignature, equals('Valid'));
      expect(telemetry.displayQdsVerification, equals('Valid'));
      expect(telemetry.displayReplayDetection, equals('Not detected'));
      expect(telemetry.displaySigner, equals('X'));
    });

    test('Robustly handles numeric types arriving as int, double, or string', () {
      final json = {
        'verification_accuracy': 1, // integer 1 instead of 1.0
        'error_rate': '0.02', // string numeric
        'quantum_bit_count': 8.0, // double instead of int
        'total_shots': '500', // string integer
        'classical_signature_valid': 'true', // string boolean
        'qds_valid': 'false', // string boolean
      };

      final telemetry = SecurityTelemetry.fromJson(json);

      expect(telemetry.verificationAccuracy, equals(1.0));
      expect(telemetry.errorRate, equals(0.02));
      expect(telemetry.quantumBitCount, equals(8));
      expect(telemetry.totalShots, equals(500));
      expect(telemetry.classicalSignatureValid, isTrue);
      expect(telemetry.qdsValid, isFalse);
    });

    test('Handles empty or null json gracefully without throwing', () {
      final telemetryNull = SecurityTelemetry.fromJson(null);
      expect(telemetryNull.isEmpty, isTrue);
      expect(telemetryNull.displayVerificationAccuracy, equals('Unavailable'));
      expect(telemetryNull.displayShots, equals('Unavailable'));
      expect(telemetryNull.displayClassicalSignature, equals('Unavailable'));

      final telemetryEmpty = SecurityTelemetry.fromJson({});
      expect(telemetryEmpty.isEmpty, isTrue);
    });
  });

  group('Evidence-Based Security Status Mapping', () {
    test('1. Valid / Trusted telemetry maps to QdsSecurityStatus.trusted', () {
      final telemetry = SecurityTelemetry.fromJson({
        'final_decision': 'TRUSTED',
        'likely_attack_type': 'LEGITIMATE',
        'classical_signature_valid': true,
        'qds_valid': true,
        'replay_detected': false,
        'qds_decision': 'VALID',
      });

      expect(
        SecurityService.mapTelemetryToSecurityStatus(telemetry),
        equals(QdsSecurityStatus.trusted),
      );
    });

    test('2. Invalid classical signature maps to QdsSecurityStatus.suspicious', () {
      final telemetry = SecurityTelemetry.fromJson({
        'final_decision': 'INVALID / SUSPICIOUS',
        'likely_attack_type': 'NONE',
        'classical_signature_valid': false,
        'qds_valid': true,
      });

      expect(
        SecurityService.mapTelemetryToSecurityStatus(telemetry),
        equals(QdsSecurityStatus.suspicious),
      );
    });

    test('3. Invalid QDS verification maps to QdsSecurityStatus.verificationFailed', () {
      final telemetry = SecurityTelemetry.fromJson({
        'final_decision': 'INVALID / SUSPICIOUS',
        'likely_attack_type': 'NONE',
        'classical_signature_valid': true,
        'qds_valid': false,
        'qds_decision': 'INVALID',
      });

      expect(
        SecurityService.mapTelemetryToSecurityStatus(telemetry),
        equals(QdsSecurityStatus.verificationFailed),
      );
    });

    test('4. Replay detected maps to QdsSecurityStatus.threatDetected', () {
      final telemetryFlag = SecurityTelemetry.fromJson({
        'replay_detected': true,
        'likely_attack_type': 'REPLAY',
        'classical_signature_valid': true,
        'qds_valid': false,
      });

      expect(
        SecurityService.mapTelemetryToSecurityStatus(telemetryFlag),
        equals(QdsSecurityStatus.threatDetected),
      );

      final telemetryAttackType = SecurityTelemetry.fromJson({
        'likely_attack_type': 'REPLAY',
      });

      expect(
        SecurityService.mapTelemetryToSecurityStatus(telemetryAttackType),
        equals(QdsSecurityStatus.threatDetected),
      );
    });

    test('5. Channel attack maps to QdsSecurityStatus.suspicious', () {
      final telemetry = SecurityTelemetry.fromJson({
        'likely_attack_type': 'CHANNEL_ATTACK',
        'classical_signature_valid': true,
        'qds_valid': true,
        'final_decision': 'SUSPICIOUS',
      });

      expect(
        SecurityService.mapTelemetryToSecurityStatus(telemetry),
        equals(QdsSecurityStatus.suspicious),
      );
    });

    test('6. Forgery or impersonation maps to QdsSecurityStatus.threatDetected', () {
      final telemetry = SecurityTelemetry.fromJson({
        'likely_attack_type': 'FORGERY_OR_IMPERSONATION',
        'classical_signature_valid': false,
        'final_decision': 'INVALID / SUSPICIOUS',
      });

      expect(
        SecurityService.mapTelemetryToSecurityStatus(telemetry),
        equals(QdsSecurityStatus.threatDetected),
      );
    });

    test('7. Unknown/unrecognized attack type maps conservatively to warning', () {
      final telemetry = SecurityTelemetry.fromJson({
        'likely_attack_type': 'FUTURE_QUANTUM_ATTACK',
        'final_decision': 'UNKNOWN_STATE',
      });

      expect(
        SecurityService.mapTelemetryToSecurityStatus(telemetry),
        equals(QdsSecurityStatus.warning),
      );
    });

    test('8. Missing telemetry maps to monitoring', () {
      expect(
        SecurityService.mapTelemetryToSecurityStatus(null),
        equals(QdsSecurityStatus.monitoring),
      );
      expect(
        SecurityService.mapTelemetryToSecurityStatus(const SecurityTelemetry()),
        equals(QdsSecurityStatus.monitoring),
      );
    });
  });

  group('SecurityService Processing and Deduplication', () {
    test('Processes message security and stores telemetry by message ID', () {
      final service = SecurityService.instance;

      final msg = MessageModel(
        id: 'msg_sec_001',
        conversationId: 'conv_1',
        senderRole: UserRole.sender,
        senderName: 'Sender X',
        content: 'Verified transaction',
        timestamp: DateTime.now(),
        securityData: {
          'final_decision': 'TRUSTED',
          'likely_attack_type': 'LEGITIMATE',
          'classical_signature_valid': true,
          'qds_valid': true,
          'verification_accuracy': 0.99,
          'signer_id': 'X',
        },
      );

      final event = service.processMessageSecurity(msg);

      expect(event, isNotNull);
      expect(event!.messageId, equals('msg_sec_001'));
      expect(event.status, equals(QdsSecurityStatus.trusted));
      expect(service.latestTelemetry?.verificationAccuracy, equals(0.99));
      expect(service.currentStatus, equals(QdsSecurityStatus.trusted));
      expect(service.getTelemetryForMessage('msg_sec_001'), isNotNull);
      expect(service.events, hasLength(1));
    });

    test('Prevents duplicate security events for the same message ID', () {
      final service = SecurityService.instance;

      final msg = MessageModel(
        id: 'msg_dup_100',
        conversationId: 'conv_1',
        senderRole: UserRole.sender,
        senderName: 'Sender X',
        content: 'Original dispatch',
        timestamp: DateTime.now(),
        securityData: {
          'final_decision': 'TRUSTED',
          'classical_signature_valid': true,
          'qds_valid': true,
        },
      );

      // First time creates event
      final event1 = service.processMessageSecurity(msg);
      expect(event1, isNotNull);
      expect(service.events, hasLength(1));

      // Second time (e.g. ACK or update) does not create duplicate event
      final event2 = service.processMessageSecurity(msg);
      expect(event2, isNull);
      expect(service.events, hasLength(1));
    });
  });

  group('SecurityProvider State Tracking', () {
    test('Tracks latest telemetry, recent events, and selected inspection state', () {
      final provider = SecurityProvider();

      expect(provider.currentStatus, equals(QdsSecurityStatus.monitoring));
      expect(provider.recentEvents, isEmpty);
      expect(provider.selectedTelemetry, isNull);

      final msg = MessageModel(
        id: 'msg_prov_001',
        conversationId: 'conv_1',
        senderRole: UserRole.sender,
        senderName: 'Sender X',
        content: 'Replay attempt test',
        timestamp: DateTime.now(),
        securityData: {
          'final_decision': 'INVALID / SUSPICIOUS',
          'replay_detected': true,
          'likely_attack_type': 'REPLAY',
        },
      );

      provider.consumeMessage(msg);

      expect(provider.currentStatus, equals(QdsSecurityStatus.threatDetected));
      expect(provider.recentEvents, hasLength(1));
      expect(provider.latestTelemetry?.replayDetected, isTrue);

      // Selection test
      provider.selectTelemetry(provider.latestTelemetry);
      expect(provider.selectedTelemetry, isNotNull);

      provider.dispose();
    });
  });

  group('MessageSecurityDetailsSheet Widget Test', () {
    testWidgets('Renders all real telemetry fields with no fake data', (WidgetTester tester) async {
      final telemetry = SecurityTelemetry.fromJson({
        'final_decision': 'TRUSTED',
        'likely_attack_type': 'LEGITIMATE',
        'classical_signature_valid': true,
        'qds_valid': true,
        'replay_detected': false,
        'verification_accuracy': 0.984,
        'error_rate': 0.016,
        'quantum_bit_count': 64,
        'total_shots': 1000,
        'correct_shots': 984,
        'threshold': 0.85,
        'signer_id': 'X',
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MessageSecurityDetailsSheet(
              telemetry: telemetry,
              messageSnippet: 'Confidential message',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verification Details'), findsOneWidget);
      expect(find.text('"Confidential message"'), findsOneWidget);
      expect(find.text('Security Status'), findsOneWidget);
      expect(find.text('Trusted'), findsWidgets);
      expect(find.text('Attack Type'), findsOneWidget);
      expect(find.text('Legitimate (None)'), findsOneWidget);
      expect(find.text('Classical Signature'), findsOneWidget);
      expect(find.text('Valid'), findsWidgets);
      expect(find.text('QDS Verification'), findsOneWidget);
      expect(find.text('Replay Detection'), findsOneWidget);
      expect(find.text('Not detected'), findsOneWidget);
      expect(find.text('Verification Accuracy'), findsOneWidget);
      expect(find.text('98.4%'), findsOneWidget);
      expect(find.text('Error Rate'), findsOneWidget);
      expect(find.text('1.6%'), findsOneWidget);
      expect(find.text('Quantum Verification'), findsOneWidget);
      expect(find.text('984 / 1000 correct'), findsOneWidget);
      expect(find.text('Threshold'), findsOneWidget);
      expect(find.text('0.85'), findsOneWidget);
      expect(find.text('Signer'), findsOneWidget);
      expect(find.text('X'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });
}
