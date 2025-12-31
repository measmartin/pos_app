import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../services/database_service.dart';

class SettingsViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  AppSettings? _settings;
  bool _isLoading = false;
  String? _error;

  AppSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final settingsMap = await _databaseService.getSettings();
      if (settingsMap != null) {
        _settings = AppSettings.fromMap(settingsMap);
      } else {
        _settings = AppSettings(); // Default settings
      }
    } catch (e) {
      _error = 'Failed to load settings: $e';
      _settings = AppSettings(); // Fallback to defaults
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveSettings(AppSettings newSettings) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _databaseService.updateSettings(newSettings.toMap());
      _settings = newSettings;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to save settings: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
