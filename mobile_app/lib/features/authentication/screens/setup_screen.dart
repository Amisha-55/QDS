import 'package:flutter/material.dart';
import 'package:qds/app/routes.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/models/user_model.dart';
import 'package:qds/core/storage/local_storage.dart';
import 'package:qds/core/utils/validators.dart';
import 'package:qds/shared/widgets/app_button.dart';

/// Screen allowing selection of demonstration identity (Role X or Role Y) and display name.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  UserRole? _selectedRole;
  bool _isSaving = false;

  bool get _isFormValid {
    final nameValid = Validators.validateDisplayName(_nameController.text) == null;
    return _selectedRole != null && nameValid;
  }

  @override
  void initState() {
    super.initState();
    final existingRole = LocalStorage.instance.role;
    final existingName = LocalStorage.instance.displayName;
    if (existingRole != null) _selectedRole = existingRole;
    if (existingName != null) _nameController.text = existingName;

    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (!_isFormValid || _selectedRole == null) return;

    setState(() => _isSaving = true);

    await LocalStorage.instance.saveIdentity(
      name: _nameController.text.trim(),
      role: _selectedRole!.code,
    );

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Set up your QDS identity',
                          style: AppTypography.pageHeading.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Choose whether this device represents sender X or receiver Y for the prototype demonstration.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Choose role',
                          style: AppTypography.label.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildRoleCard(UserRole.sender),
                        const SizedBox(height: AppSpacing.md),
                        _buildRoleCard(UserRole.receiver),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Display name',
                          style: AppTypography.label.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: 'Enter your name',
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              size: AppDimensions.iconSm,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          validator: Validators.validateDisplayName,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),
                        const Spacer(),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          text: 'Continue',
                          isLoading: _isSaving,
                          onPressed: _isFormValid && !_isSaving ? _handleContinue : null,
                        ),
                        const SizedBox(height: AppDimensions.screenPadding),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoleCard(UserRole role) {
    final theme = Theme.of(context);
    final isSelected = _selectedRole == role;
    final isDark = context.isDarkMode;

    final Color borderColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;

    final Color bgColor = isSelected
        ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.16 : 0.06)
        : theme.colorScheme.surface;

    return Semantics(
      selected: isSelected,
      label: '${role.code} ${role.label}',
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
        },
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            border: Border.all(
              color: borderColor,
              width: isSelected
                  ? AppDimensions.borderWidthFocus
                  : AppDimensions.borderWidthThin,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    role.code,
                    style: AppTypography.cardTitle.copyWith(
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${role.code} • ${role.label}',
                      style: AppTypography.cardTitle.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                size: AppDimensions.iconMd,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
