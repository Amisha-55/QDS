/// Text field validators for the QDS application.
abstract final class Validators {
  static String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a display name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }
}
