import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qds/app/routes.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/models/security_event_model.dart';
import 'package:qds/core/models/security_telemetry.dart';
import 'package:qds/features/security/utils/attack_presentation_helper.dart';

/// A noticeable, non-disruptive security alert banner displayed at the top of
/// messaging or home screens when an active threat or suspicious event occurs.
///
/// Features a subtle one-time slide/fade entrance, factual description,
/// a "View Details" action button, and a dismiss action.
class ThreatAlertBanner extends StatefulWidget {
  const ThreatAlertBanner({
    super.key,
    required this.event,
    this.onDismiss,
    this.onViewDetails,
  });

  final SecurityEventModel event;
  final VoidCallback? onDismiss;
  final VoidCallback? onViewDetails;

  @override
  State<ThreatAlertBanner> createState() => _ThreatAlertBannerState();
}

class _ThreatAlertBannerState extends State<ThreatAlertBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final securityColors = context.securityColors;
    final status = widget.event.status;
    final statusColor = securityColors.colorForStatus(status);
    final containerColor = securityColors.containerForStatus(status);
    final borderColor = securityColors.borderForStatus(status);

    final telemetry = widget.event.telemetry ?? const SecurityTelemetry();
    final headline = AttackPresentationHelper.getAlertHeadline(telemetry, status);
    final explanation = widget.event.summary.isNotEmpty
        ? widget.event.summary
        : AttackPresentationHelper.getFactualExplanation(telemetry, status);
    final icon = AttackPresentationHelper.getAttackIcon(widget.event.attackType, status);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            border: Border.all(
              color: borderColor,
              width: AppDimensions.borderWidthThin,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: statusColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headline,
                          style: AppTypography.cardTitle.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          explanation,
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onDismiss != null)
                    Semantics(
                      label: 'Dismiss Alert',
                      button: true,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        tooltip: 'Dismiss Alert',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          widget.onDismiss?.call();
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Semantics(
                    label: 'View security verification details',
                    button: true,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(44, 32),
                      ),
                      icon: Icon(Icons.arrow_forward_rounded, size: 14, color: statusColor),
                      label: Text(
                        'View Details',
                        style: AppTypography.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: widget.onViewDetails ??
                          () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.verificationDetails,
                              arguments: widget.event,
                            );
                          },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
