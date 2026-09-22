import 'package:flutter/material.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';

/// Destination entry point for user login.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'User Login Entry Point',
              style: AppTypography.sectionHeading.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
