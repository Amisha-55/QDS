import 'package:flutter/material.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/models/security_telemetry.dart';

/// Reusable presentation helper for mapping backend attack classifications,
/// evidence types, icons, and factual descriptions.
abstract final class AttackPresentationHelper {
  /// Maps raw backend attack classification strings to user-facing labels.
  /// Converts unknown future values cleanly without losing raw values or crashing.
  static String formatAttackType(String? rawAttackType) {
    if (rawAttackType == null || rawAttackType.trim().isEmpty) {
      return 'Unknown Activity';
    }

    final normalized = rawAttackType.trim().toUpperCase();

    switch (normalized) {
      case 'NONE':
      case 'LEGITIMATE':
        return 'Legitimate';
      case 'REPLAY':
        return 'Replay Attack';
      case 'CHANNEL_ATTACK':
        return 'Channel Attack';
      case 'FORGERY_OR_IMPERSONATION':
        return 'Forgery / Impersonation';
      case 'FORGERY':
        return 'Signature Forgery';
      case 'IMPERSONATION':
        return 'Impersonation Attack';
      case 'UNKNOWN':
        return 'Unknown Activity';
      default:
        // Safely format unknown strings: replace underscores with spaces and capitalize words
        return rawAttackType
            .split('_')
            .where((segment) => segment.isNotEmpty)
            .map((word) => word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : ''))
            .join(' ');
    }
  }

  /// Maps an attack category and security status to a standard Material icon.
  static IconData getAttackIcon(String? rawAttackType, QdsSecurityStatus status) {
    final normalized = rawAttackType?.trim().toUpperCase() ?? '';

    if (normalized.contains('REPLAY')) {
      return Icons.replay_rounded;
    }
    if (normalized.contains('CHANNEL')) {
      return Icons.swap_horiz_rounded;
    }
    if (normalized.contains('FORGERY') || normalized.contains('IMPERSONATION')) {
      return Icons.person_off_rounded;
    }

    switch (status) {
      case QdsSecurityStatus.threatDetected:
        return Icons.gpp_bad_rounded;
      case QdsSecurityStatus.verificationFailed:
        return Icons.error_outline_rounded;
      case QdsSecurityStatus.suspicious:
      case QdsSecurityStatus.warning:
        return Icons.warning_amber_rounded;
      case QdsSecurityStatus.trusted:
      case QdsSecurityStatus.verified:
        return Icons.verified_user_rounded;
      case QdsSecurityStatus.monitoring:
        return Icons.radar_rounded;
    }
  }

  /// Returns a concise, factual explanation based solely on verifiable telemetry evidence.
  /// Strictly avoids unsupported speculation (e.g. claiming an attacker intercepted traffic).
  static String getFactualExplanation(SecurityTelemetry? telemetry, QdsSecurityStatus status) {
    if (telemetry == null || telemetry.isEmpty) {
      return 'Security monitoring initialized. Waiting for message verification data.';
    }

    if (telemetry.replayDetected == true) {
      return 'Replay detection flagged this message. Nonce or signature hash was previously registered in the session registry.';
    }

    final attackType = telemetry.likelyAttackType?.toUpperCase() ?? '';

    if (attackType == 'REPLAY') {
      return 'Replay detection flagged this message.';
    }

    if (attackType == 'FORGERY_OR_IMPERSONATION' || attackType == 'FORGERY' || attackType == 'IMPERSONATION') {
      return 'Forgery or impersonation classification was returned by the verification pipeline. Classical digital signature failed validation.';
    }

    if (attackType == 'CHANNEL_ATTACK') {
      final acc = telemetry.verificationAccuracy != null
          ? ' (accuracy ${(telemetry.verificationAccuracy! * 100).toStringAsFixed(1)}%)'
          : '';
      return 'Channel attack classification was returned by the verification pipeline$acc. Quantum measurement fidelity fell below threshold.';
    }

    if (telemetry.classicalSignatureValid == false) {
      return 'Classical signature verification failed.';
    }

    if (telemetry.qdsValid == false || telemetry.qdsDecision == 'INVALID' || telemetry.qdsDecision == 'REJECT') {
      return 'QDS verification failed.';
    }

    if (status == QdsSecurityStatus.trusted || status == QdsSecurityStatus.verified) {
      return 'Message verification passed all cryptographic and quantum validation checks.';
    }

    if (status == QdsSecurityStatus.suspicious || status == QdsSecurityStatus.warning) {
      return 'Signature discrepancy or channel noise was detected during verification.';
    }

    return 'Verification produced an unrecognized security result.';
  }

  /// Returns a short banner alert message for in-chat or top-level notification cards.
  static String getAlertHeadline(SecurityTelemetry? telemetry, QdsSecurityStatus status) {
    if (telemetry?.replayDetected == true || telemetry?.likelyAttackType?.toUpperCase() == 'REPLAY') {
      return 'Replay Detected';
    }

    final attackType = telemetry?.likelyAttackType?.toUpperCase() ?? '';

    if (attackType == 'FORGERY_OR_IMPERSONATION' || attackType == 'FORGERY') {
      return 'Signature Forgery Detected';
    }
    if (attackType == 'IMPERSONATION') {
      return 'Impersonation Detected';
    }
    if (attackType == 'CHANNEL_ATTACK') {
      return 'Channel Manipulation Detected';
    }
    if (telemetry?.classicalSignatureValid == false) {
      return 'Classical Signature Invalid';
    }
    if (telemetry?.qdsValid == false) {
      return 'QDS Quantum Verification Failed';
    }

    switch (status) {
      case QdsSecurityStatus.threatDetected:
        return 'Security Threat Detected';
      case QdsSecurityStatus.verificationFailed:
        return 'Verification Failed';
      case QdsSecurityStatus.suspicious:
        return 'Suspicious Telemetry Detected';
      case QdsSecurityStatus.warning:
        return 'Security Anomaly Detected';
      default:
        return 'Security Alert';
    }
  }
}
