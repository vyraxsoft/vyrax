/// In-memory file selection used by CLI contextual analysis scopes.
final class AnalysisFileSelection {
  static List<String>? _selectedDartFiles;

  /// Sets selected Dart files for the current analysis execution.
  static void setSelectedDartFiles(List<String> files) {
    _selectedDartFiles = List<String>.from(files, growable: false);
  }

  /// Clears selected Dart files, restoring full-project discovery mode.
  static void clearSelectedDartFiles() {
    _selectedDartFiles = null;
  }

  /// Returns selected files for current execution, or null for full-project mode.
  static List<String>? get selectedDartFiles => _selectedDartFiles;
}
