import 'dart:convert';
import 'dart:io';
import 'package:qds/core/models/user_model.dart';

class LocalStorage {
  LocalStorage._();
  static final LocalStorage instance = LocalStorage._();

  static const String _onboardingKey = 'has_completed_onboarding';
  static const String _setupKey = 'has_completed_setup';
  static const String _userRoleKey = 'user_role';
  static const String _displayNameKey = 'display_name';

  final Map<String, dynamic> _cache = {};
  File? _file;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      final tempDir = Directory.systemTemp;
      _file = File('${tempDir.path}/qds_app_preferences.json');

      if (await _file!.exists()) {
        final content = await _file!.readAsString();
        if (content.trim().isNotEmpty) {
          final decoded = jsonDecode(content);
          if (decoded is Map<String, dynamic>) {
            _cache.addAll(decoded);
          }
        }
      }
    } catch (_) {}

    _initialized = true;
  }

  bool get isOnboardingCompleted => _cache[_onboardingKey] == true;

  Future<void> setOnboardingCompleted(bool completed) async {
    _cache[_onboardingKey] = completed;
    _save();
  }

  bool get isSetupCompleted => _cache[_setupKey] == true;

  Future<void> setSetupCompleted(bool completed) async {
    _cache[_setupKey] = completed;
    _save();
  }

  String? get userRole => _cache[_userRoleKey] as String?;

  UserRole? get role => UserRole.fromCode(userRole);

  Future<void> setUserRole(String roleCode) async {
    _cache[_userRoleKey] = roleCode;
    _save();
  }

  String? get displayName => _cache[_displayNameKey] as String?;

  Future<void> setDisplayName(String name) async {
    _cache[_displayNameKey] = name;
    _save();
  }

  Future<void> saveIdentity({
    required String name,
    required String role,
  }) async {
    _cache[_displayNameKey] = name.trim();
    _cache[_userRoleKey] = role;
    _cache[_setupKey] = true;
    _save();
  }

  Future<void> clearIdentity() async {
    _cache.remove(_displayNameKey);
    _cache.remove(_userRoleKey);
    _cache[_setupKey] = false;
    _save();
  }

  Future<void> clear() async {
    _cache.clear();
    try {
      if (_file != null && await _file!.exists()) {
        await _file!.delete();
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      if (_file != null) {
        await _file!.writeAsString(jsonEncode(_cache), flush: true);
      }
    } catch (_) {}
  }
}
