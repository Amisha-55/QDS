import 'package:flutter/material.dart';
import 'package:qds/app/routes.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/storage/local_storage.dart';
import 'package:qds/core/network/websocket_client.dart';
import 'package:qds/features/home/widgets/conversation_tile.dart';
import 'package:qds/features/home/widgets/security_status_card.dart';
import 'package:qds/features/messaging/providers/chat_provider.dart';
import 'package:qds/features/security/providers/security_provider.dart';
import 'package:qds/features/security/widgets/threat_alert_banner.dart';

/// The central Home screen providing the primary application shell and conversation list for QDS.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.provider,
  });

  final ChatProvider? provider;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ChatProvider _chatProvider;
  late final SecurityProvider _securityProvider;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _chatProvider = widget.provider ?? ChatProvider();
    _chatProvider.loadConversations();
    _chatProvider.addListener(_onProviderUpdate);
    _securityProvider = SecurityProvider();
    _securityProvider.addListener(_onProviderUpdate);
    if (LocalStorage.instance.role != null) {
      _chatProvider.connectGateway();
    }
  }

  void _onProviderUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _chatProvider.removeListener(_onProviderUpdate);
    _securityProvider.removeListener(_onProviderUpdate);
    _securityProvider.dispose();
    super.dispose();
  }

  Future<void> _safeNavigate(Future<dynamic> Function() action) async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      await action();
    } finally {
      if (mounted) {
        _isNavigating = false;
      }
    }
  }

  Future<void> _handleStartConversation() async {
    await _safeNavigate(() async {
      final conv = await _chatProvider.startConversationWithCounterpart();
      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        AppRoutes.chat,
        arguments: conv,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = LocalStorage.instance.displayName ?? 'User';
    final role = LocalStorage.instance.role;
    final roleBadgeText = role != null ? 'Role: ${role.code} (${role.label})' : 'Role: Unassigned';
    final conversations = _chatProvider.conversations;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'QDS',
              style: AppTypography.sectionHeading.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          _buildConnectionStatus(context),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Semantics(
              label: 'Identity Profile',
              child: IconButton(
                tooltip: 'Identity Profile',
                onPressed: () {
                  _safeNavigate(() => Navigator.pushNamed(context, AppRoutes.profile));
                },
                icon: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      width: AppDimensions.borderWidthThin,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      role?.code ?? 'U',
                      style: AppTypography.cardTitle.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $displayName',
                          style: AppTypography.pageHeading.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          roleBadgeText,
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_securityProvider.activeThreatAlert != null) ...[
                ThreatAlertBanner(
                  event: _securityProvider.activeThreatAlert!,
                  onDismiss: () => _securityProvider.dismissThreatAlert(),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              SecurityStatusCard(
                status: _securityProvider.latestTelemetry == null
                    ? QdsSecurityStatus.trusted
                    : _securityProvider.currentStatus,
                title: _securityProvider.latestTelemetry == null
                    ? 'Security ready'
                    : 'Security: ${_securityProvider.currentStatus.label}',
                subtitle: _securityProvider.latestTelemetry == null
                    ? 'Device verified and ready for secure digital signature transmission.'
                    : 'Real-time cryptographic and QDS quantum telemetry active.',
                onTap: () {
                  _safeNavigate(() => Navigator.pushNamed(context, AppRoutes.securityCenter));
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Conversations',
                style: AppTypography.sectionHeading.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: conversations.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                          final conv = conversations[index];
                          return ConversationTile(
                            conversation: conv,
                            onTap: () {
                              _safeNavigate(() => Navigator.pushNamed(
                                    context,
                                    AppRoutes.chat,
                                    arguments: conv,
                                  ));
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New Conversation',
        onPressed: _handleStartConversation,
        child: const Icon(Icons.add_comment_rounded),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 28,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No conversations yet',
              style: AppTypography.cardTitle.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Start a secure conversation to begin.',
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

  Widget _buildConnectionStatus(BuildContext context) {
    final state = _chatProvider.connectionState;
    Color color;
    String label;
    String badgeText;
    Widget leadingWidget;

    switch (state) {
      case WebSocketConnectionState.connected:
        color = const Color(0xFF10B981);
        label = 'Gateway Online';
        badgeText = 'Online';
        leadingWidget = Icon(Icons.cloud_done_rounded, size: 14, color: color);
        break;
      case WebSocketConnectionState.connecting:
        color = const Color(0xFFF59E0B);
        label = 'Connecting to gateway...';
        badgeText = 'Connecting';
        leadingWidget = SizedBox(
          width: 11,
          height: 11,
          child: CircularProgressIndicator(
            strokeWidth: 1.8,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
        break;
      case WebSocketConnectionState.reconnecting:
        color = const Color(0xFFF59E0B);
        label = 'Reconnecting to gateway...';
        badgeText = 'Reconnecting';
        leadingWidget = SizedBox(
          width: 11,
          height: 11,
          child: CircularProgressIndicator(
            strokeWidth: 1.8,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
        break;
      case WebSocketConnectionState.disconnected:
        color = const Color(0xFF94A3B8);
        label = 'Gateway Offline — tap to connect';
        badgeText = 'Offline';
        leadingWidget = Icon(Icons.cloud_off_rounded, size: 14, color: color);
        break;
      case WebSocketConnectionState.failed:
        color = const Color(0xFFEF4444);
        label = 'Gateway connection failed — tap to retry';
        badgeText = 'Retry';
        leadingWidget = Icon(Icons.refresh_rounded, size: 14, color: color);
        break;
    }

    final canRetry = state != WebSocketConnectionState.connected &&
        state != WebSocketConnectionState.connecting &&
        state != WebSocketConnectionState.reconnecting;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Semantics(
        label: 'Gateway status: $badgeText',
        button: canRetry,
        hint: canRetry ? 'Tap to reconnect to QDS gateway' : null,
        child: Tooltip(
          message: label,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: canRetry ? () => _chatProvider.connectGateway() : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  leadingWidget,
                  const SizedBox(width: 4),
                  Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
