import 'package:flutter/material.dart';

/// Semantic security states across the QDS application.
enum QdsSecurityStatus {
  trusted(
    label: 'Trusted',
    icon: Icons.shield_rounded,
    description: 'Cryptographic signature is verified and quantum integrity is intact.',
    isThreat: false,
  ),
  verified(
    label: 'Verified',
    icon: Icons.check_circle_rounded,
    description: 'Digital signature has passed cryptographic verification.',
    isThreat: false,
  ),
  monitoring(
    label: 'Monitoring',
    icon: Icons.radar_rounded,
    description: 'Real-time telemetry and entropy analysis are actively running.',
    isThreat: false,
  ),
  warning(
    label: 'Warning',
    icon: Icons.warning_amber_rounded,
    description: 'Minor anomaly detected in signature entropy or latency.',
    isThreat: false,
  ),
  suspicious(
    label: 'Suspicious',
    icon: Icons.report_problem_rounded,
    description: 'Signature characteristics deviate significantly from standard baseline.',
    isThreat: true,
  ),
  threatDetected(
    label: 'Threat Detected',
    icon: Icons.gpp_bad_rounded,
    description: 'Critical quantum-inspired forgery attempt or key compromise detected.',
    isThreat: true,
  ),
  verificationFailed(
    label: 'Verification Failed',
    icon: Icons.cancel_rounded,
    description: 'Digital signature could not be mathematically validated.',
    isThreat: true,
  );

  const QdsSecurityStatus({
    required this.label,
    required this.icon,
    required this.description,
    required this.isThreat,
  });

  final String label;
  final IconData icon;
  final String description;
  final bool isThreat;
}

/// Numerical threat severity levels for threat scoring.
enum ThreatSeverity {
  none(label: 'None', minScore: 0.0, maxScore: 0.15),
  low(label: 'Low', minScore: 0.15, maxScore: 0.40),
  medium(label: 'Medium', minScore: 0.40, maxScore: 0.70),
  high(label: 'High', minScore: 0.70, maxScore: 0.90),
  critical(label: 'Critical', minScore: 0.90, maxScore: 1.0);

  const ThreatSeverity({
    required this.label,
    required this.minScore,
    required this.maxScore,
  });

  final String label;
  final double minScore;
  final double maxScore;

  static ThreatSeverity fromScore(double score) {
    final clamped = score.clamp(0.0, 1.0);
    if (clamped >= 0.90) return ThreatSeverity.critical;
    if (clamped >= 0.70) return ThreatSeverity.high;
    if (clamped >= 0.40) return ThreatSeverity.medium;
    if (clamped >= 0.15) return ThreatSeverity.low;
    return ThreatSeverity.none;
  }
}
