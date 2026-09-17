import 'package:flutter/material.dart';
import 'package:qds/app/routes.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/models/security_event_model.dart';
import 'package:qds/core/utils/date_utils.dart';
import 'package:qds/features/security/providers/security_provider.dart';
import 'package:qds/features/security/widgets/current_verification_card.dart';
import 'package:qds/features/security/widgets/security_event_tile.dart';
import 'package:qds/features/security/widgets/verification_activity_card.dart';

enum SecurityEventFilter {
  all(label: 'All'),
  verified(label: 'Verified'),
  warnings(label: 'Warnings'),
  threats(label: 'Threats');

  const SecurityEventFilter({required this.label});
  final String label;
}

/// Central Security Center console displaying live cryptographic telemetry,
/// verification audits, and evidence-based threat classifications.
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({
    super.key,
    this.provider,
  });

  final SecurityProvider? provider;

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  late final SecurityProvider _securityProvider;
  SecurityEventFilter _selectedFilter = SecurityEventFilter.all;

  @override
  void initState() {
    super.initState();
    _securityProvider = widget.provider ?? SecurityProvider();
    _securityProvider.addListener(_onProviderUpdate);
  }

  void _onProviderUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _securityProvider.removeListener(_onProviderUpdate);
    super.dispose();
  }

  List<SecurityEventModel> _getFilteredEvents(List<SecurityEventModel> events) {
    switch (_selectedFilter) {
      case SecurityEventFilter.all:
        return events;
      case SecurityEventFilter.verified:
        return events
            .where((e) => e.status == QdsSecurityStatus.trusted || e.status == QdsSecurityStatus.verified)
            .toList();
      case SecurityEventFilter.warnings:
        return events
            .where((e) => e.status == QdsSecurityStatus.warning || e.status == QdsSecurityStatus.suspicious)
            .toList();
      case SecurityEventFilter.threats:
        return events
            .where((e) => e.status == QdsSecurityStatus.threatDetected || e.status == QdsSecurityStatus.verificationFailed)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final securityColors = context.securityColors;

    final status = _securityProvider.currentStatus;
    final latestTelemetry = _securityProvider.latestTelemetry;
    final allEvents = _securityProvider.recentEvents;
    final filteredEvents = _getFilteredEvents(allEvents);

    final statusColor = securityColors.colorForStatus(status);
    final statusContainer = securityColors.containerForStatus(status);
    final statusBorder = securityColors.borderForStatus(status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QDS Security'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: statusContainer,
                  borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                  border: Border.all(
                    color: statusBorder,
                    width: AppDimensions.borderWidthThin,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        status.icon,
                        color: statusColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      status.label.toUpperCase(),
                      style: AppTypography.cardTitle.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _getStatusExplanation(status),
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CurrentVerificationCard(
                telemetry: latestTelemetry,
                status: status,
                onViewDetails: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.verificationDetails,
                    arguments: latestTelemetry,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              if (allEvents.isNotEmpty) ...[
                VerificationActivityCard(events: allEvents),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text(
                'Recent Activity',
                style: AppTypography.sectionHeading.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (allEvents.isNotEmpty) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: SecurityEventFilter.values.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: ChoiceChip(
                          label: Text(filter.label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedFilter = filter);
                            }
                          },
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          selectedColor: theme.colorScheme.primary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (allEvents.isEmpty)
                _buildEmptyState(context)
              else if (filteredEvents.isEmpty)
                _buildEmptyFilterState(context)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredEvents.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    final attackTypeLabel = event.attackType != 'NONE' && event.attackType != 'LEGITIMATE'
                        ? ' (${event.attackType})'
                        : '';

                    return SecurityEventTile(
                      title: event.summary,
                      timestamp: AppDateUtils.formatTime(event.timestamp),
                      status: event.status,
                      description: 'Signer: ${event.signerId ?? "X"}$attackTypeLabel',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.verificationDetails,
                          arguments: event.telemetry,
                        );
                      },
                    );
                  },
                ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: AppDimensions.borderWidthThin,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 28,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Security monitoring is ready',
            style: AppTypography.cardTitle.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Verified communication activity will appear here as messages are exchanged.',
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState(BuildContext context) {
    final theme = Theme.of(context);
    final isThreat = _selectedFilter == SecurityEventFilter.threats;
    final title = isThreat
        ? 'No threats detected'
        : 'No ${_selectedFilter.label.toLowerCase()} events recorded.';
    final subtitle = isThreat
        ? 'No threat events have been recorded during this session.'
        : 'Filtered events will appear here as messages are exchanged.';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: Column(
          children: [
            Text(
              title,
              style: AppTypography.cardTitle.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusExplanation(QdsSecurityStatus status) {
    switch (status) {
      case QdsSecurityStatus.trusted:
      case QdsSecurityStatus.verified:
        return 'Recent communication passed cryptographic and QDS verification.';
      case QdsSecurityStatus.threatDetected:
        return 'Critical: Quantum-inspired security violation or signature replay detected.';
      case QdsSecurityStatus.suspicious:
        return 'Warning: Mathematical verification discrepancy or channel anomaly detected.';
      case QdsSecurityStatus.verificationFailed:
        return 'Digital signature could not be verified by the cryptographic verification engine.';
      case QdsSecurityStatus.warning:
        return 'Minor signature anomaly detected. Channel telemetry is under active monitoring.';
      case QdsSecurityStatus.monitoring:
        return 'Security monitoring is ready. Digital signatures will be verified in real time.';
    }
  }
}
