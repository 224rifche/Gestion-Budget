import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings.dart';
import '../services/biometric_auth_service.dart';
import '../services/notification_service.dart';

/// Provider pour la gestion des paramètres utilisateur
class SettingsProvider with ChangeNotifier {
  UserSettings _settings = UserSettings();
  bool _isLoading = false;

  UserSettings get settings => _settings;
  bool get isLoading => _isLoading;

  /// Initialiser et charger les paramètres
  Future<void> initialize() async {
    await loadSettings();
  }

  /// Charger les paramètres depuis SharedPreferences
  Future<void> loadSettings() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();

      // Charger tous les paramètres
      final Map<String, dynamic> settingsMap = {};

      for (String key in prefs.getKeys()) {
        final value = prefs.get(key);
        settingsMap[key] = value;
      }

      if (settingsMap.isNotEmpty) {
        _settings = UserSettings.fromMap(settingsMap);
      }

      _isLoading = false;
      notifyListeners();
      debugPrint('✅ Paramètres chargés');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Erreur loadSettings: $e');
    }
  }

  /// Sauvegarder les paramètres
  Future<bool> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _settings.toMap();

      for (var entry in map.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value == null) {
          await prefs.remove(key);
        } else if (value is String) {
          await prefs.setString(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        }
      }

      notifyListeners();
      debugPrint('✅ Paramètres sauvegardés');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur saveSettings: $e');
      return false;
    }
  }

  /// Mettre à jour un paramètre spécifique
  Future<void> updateSetting<T>(String key, T value) async {
    // Utiliser copyWith selon le paramètre modifié
    switch (key) {
      // Général
      case 'currency':
        _settings = _settings.copyWith(currency: value as String);
        break;
      case 'language':
        _settings = _settings.copyWith(language: value as String);
        break;
      case 'first_day_of_week':
        _settings = _settings.copyWith(firstDayOfWeek: value as int);
        break;

      // Apparence
      case 'theme':
        _settings = _settings.copyWith(theme: value as String);
        break;
      case 'use_system_theme':
        _settings = _settings.copyWith(useSystemTheme: value as bool);
        break;
      case 'primary_color':
        _settings = _settings.copyWith(primaryColor: value as String);
        break;
      case 'show_animations':
        _settings = _settings.copyWith(showAnimations: value as bool);
        break;

      // Transactions
      case 'default_transaction_type':
        _settings = _settings.copyWith(defaultTransactionType: value as String);
        break;
      case 'require_confirmation':
        _settings = _settings.copyWith(requireConfirmation: value as bool);
        break;
      case 'auto_categories':
        _settings = _settings.copyWith(autoCategories: value as bool);
        break;

      // Budgets
      case 'budget_notifications':
        _settings = _settings.copyWith(budgetNotifications: value as bool);
        break;
      case 'budget_warning_threshold':
        _settings = _settings.copyWith(budgetWarningThreshold: value as double);
        break;
      case 'show_budget_summary':
        _settings = _settings.copyWith(showBudgetSummary: value as bool);
        break;
      case 'default_budget_period':
        _settings = _settings.copyWith(defaultBudgetPeriod: value as String);
        break;

      // Sécurité
      case 'biometric_auth':
        _settings = _settings.copyWith(biometricAuth: value as bool);
        break;
      case 'require_auth_on_start':
        _settings = _settings.copyWith(requireAuthOnStart: value as bool);
        break;
      case 'auto_lock_minutes':
        _settings = _settings.copyWith(autoLockMinutes: value as int);
        break;

      // Notifications
      case 'notifications_enabled':
        _settings = _settings.copyWith(notificationsEnabled: value as bool);
        break;
      case 'budget_alerts':
        _settings = _settings.copyWith(budgetAlerts: value as bool);
        break;
      case 'recurring_reminders':
        _settings = _settings.copyWith(recurringReminders: value as bool);
        break;
      case 'goal_achievements':
        _settings = _settings.copyWith(goalAchievements: value as bool);
        break;

      // Confidentialité
      case 'hide_amounts':
        _settings = _settings.copyWith(hideAmounts: value as bool);
        break;
      case 'anonymous_analytics':
        _settings = _settings.copyWith(anonymousAnalytics: value as bool);
        break;

      // Avancé
      case 'developer_mode':
        _settings = _settings.copyWith(developerMode: value as bool);
        break;
    }

    await saveSettings();
  }

  /// Activer/Désactiver la biométrie
  Future<bool> toggleBiometricAuth(bool enable) async {
    if (enable) {
      // Vérifier si la biométrie est disponible
      final canUse = await BiometricAuthService.instance.canEnableBiometric();

      if (!canUse) {
        debugPrint('⚠️ Biométrie non disponible');
        return false;
      }

      // Demander l'authentification pour activer
      final authenticated = await BiometricAuthService.instance.authenticate(
        reason: 'Authentifiez-vous pour activer la protection biométrique',
      );

      if (!authenticated) {
        debugPrint('⚠️ Authentification échouée');
        return false;
      }

      await BiometricAuthService.instance.setBiometricEnabled(true);
      await updateSetting('biometric_auth', true);
      debugPrint('✅ Biométrie activée');
      return true;
    } else {
      await BiometricAuthService.instance.setBiometricEnabled(false);
      await updateSetting('biometric_auth', false);
      debugPrint('🔓 Biométrie désactivée');
      return true;
    }
  }

  /// Activer/Désactiver les notifications
  Future<void> toggleNotifications(bool enable) async {
    if (enable) {
      final granted = await NotificationService.instance.requestPermissions();
      if (granted) {
        await updateSetting('notifications_enabled', true);
        debugPrint('✅ Notifications activées');
      } else {
        debugPrint('⚠️ Permission de notification refusée');
      }
    } else {
      await updateSetting('notifications_enabled', false);
      await NotificationService.instance.cancelAll();
      debugPrint('🔕 Notifications désactivées');
    }
  }

  /// Réinitialiser tous les paramètres
  Future<void> resetSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _settings = UserSettings();
      await saveSettings();
      notifyListeners();
      debugPrint('♻️ Paramètres réinitialisés');
    } catch (e) {
      debugPrint('❌ Erreur resetSettings: $e');
    }
  }

  /// Réinitialiser aux valeurs par défaut (alias pour resetSettings)
  Future<void> resetToDefaults() async {
    await resetSettings();
  }

  /// Mettre à jour la devise
  Future<void> updateCurrency(String currency) async {
    await updateSetting('currency', currency);
    debugPrint('💱 Devise mise à jour: $currency');
  }

  /// Mettre à jour la langue
  Future<void> updateLanguage(String language) async {
    await updateSetting('language', language);
    debugPrint('🌐 Langue mise à jour: $language');
  }

  /// Mettre à jour le premier jour du mois
  Future<void> updateFirstDayOfMonth(int day) async {
    await updateSetting('first_day_of_month', day);
    debugPrint('📅 Premier jour du mois mis à jour: $day');
  }

  /// Mettre à jour le seuil d'avertissement de budget
  Future<void> updateBudgetWarningThreshold(double threshold) async {
    await updateSetting('budget_warning_threshold', threshold);
    debugPrint('⚠️ Seuil de budget mis à jour: $threshold%');
  }

  /// Mettre à jour la période de budget par défaut
  Future<void> updateDefaultBudgetPeriod(String period) async {
    await updateSetting('default_budget_period', period);
    debugPrint('📊 Période de budget par défaut mise à jour: $period');
  }

  /// Mettre à jour le délai de verrouillage automatique
  Future<void> updateAutoLockTimeout(int timeout) async {
    await updateSetting('auto_lock_timeout', timeout);
    debugPrint('🔒 Délai de verrouillage auto mis à jour: $timeout minutes');
  }

  /// Exporter les paramètres
  Map<String, dynamic> exportSettings() {
    return _settings.toMap();
  }

  /// Importer les paramètres
  Future<bool> importSettings(Map<String, dynamic> settingsMap) async {
    try {
      _settings = UserSettings.fromMap(settingsMap);
      await saveSettings();
      debugPrint('✅ Paramètres importés');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur importSettings: $e');
      return false;
    }
  }

  /// Obtenir la devise formatée
  String getFormattedCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} ${_settings.currency}';
  }

  /// Vérifier si une fonctionnalité est activée
  bool isFeatureEnabled(String feature) {
    switch (feature) {
      case 'biometric':
        return _settings.biometricAuth;
      case 'notifications':
        return _settings.notificationsEnabled;
      case 'auto_backup':
        return _settings.autoBackup;
      case 'animations':
        return _settings.showAnimations;
      case 'developer':
        return _settings.developerMode;
      default:
        return false;
    }
  }
}
