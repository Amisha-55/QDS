import 'package:flutter/material.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/models/conversation_model.dart';
import 'package:qds/core/models/security_event_model.dart';
import 'package:qds/core/models/security_telemetry.dart';
import 'package:qds/features/authentication/screens/login_screen.dart';
import 'package:qds/features/authentication/screens/setup_screen.dart';
import 'package:qds/features/home/screens/home_screen.dart';
import 'package:qds/features/messaging/screens/chat_screen.dart';
import 'package:qds/features/messaging/screens/conversation_info_screen.dart';
import 'package:qds/features/onboarding/screens/onboarding_screen.dart';
import 'package:qds/features/onboarding/screens/splash_screen.dart';
import 'package:qds/features/profile/screens/profile_screen.dart';
import 'package:qds/features/security/screens/security_screen.dart';
import 'package:qds/features/security/screens/verification_screen.dart';

/// Central routing configuration for the QDS mobile application.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String setup = '/setup';
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String chat = '/chat';
  static const String conversationInfo = '/conversation-info';
  static const String securityCenter = '/security';
  static const String verificationDetails = '/verification-details';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);
      case onboarding:
        return _buildRoute(const OnboardingScreen(), settings);
      case setup:
        return _buildRoute(const SetupScreen(), settings);
      case home:
        return _buildRoute(const HomeScreen(), settings);
      case profile:
        return _buildRoute(const ProfileScreen(), settings);
      case securityCenter:
        return _buildRoute(const SecurityScreen(), settings);
      case verificationDetails:
        if (settings.arguments is SecurityTelemetry) {
          return _buildRoute(VerificationScreen(telemetry: settings.arguments as SecurityTelemetry), settings);
        } else if (settings.arguments is SecurityEventModel) {
          final event = settings.arguments as SecurityEventModel;
          return _buildRoute(VerificationScreen(telemetry: event.telemetry, event: event), settings);
        }
        return _buildRoute(const VerificationScreen(), settings);
      case chat:
        final conversation = settings.arguments as ConversationModel?;
        return _buildRoute(ChatScreen(conversation: conversation), settings);
      case conversationInfo:
        final conversation = settings.arguments as ConversationModel?;
        return _buildRoute(ConversationInfoScreen(conversation: conversation), settings);
      case login:
        return _buildRoute(const LoginScreen(), settings);
      default:
        return _buildRoute(const SplashScreen(), settings);
    }
  }

  static PageRouteBuilder<dynamic> _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      transitionDuration: AppDurations.normal,
      reverseTransitionDuration: AppDurations.normal,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        );
      },
    );
  }
}
