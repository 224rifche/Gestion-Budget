/// Modèle de paramètres utilisateur complet
class UserSettings {
  // Général
  String currency;
  String language;
  int firstDayOfWeek; // 0 = Dimanche, 1 = Lundi

  // Apparence
  String theme; // 'light', 'dark', 'system'
  bool useSystemTheme;
  String primaryColor;
  bool showAnimations;

  // Transactions
  String defaultTransactionType; // 'income' ou 'expense'
  bool requireConfirmation;
  bool autoCategories;
  int? defaultCategoryId;

  // Budgets
  bool budgetNotifications;
  double budgetWarningThreshold; // Pourcentage (ex: 80.0)
  bool showBudgetSummary;
  String defaultBudgetPeriod; // 'monthly', 'weekly', etc.

  // Sécurité
  bool biometricAuth;
  bool requireAuthOnStart;
  bool requireAuthForTransactions;
  int autoLockMinutes; // 0 = désactivé
  bool dataEncryption;

  // Sauvegarde
  bool autoBackup;
  int backupInterval; // en jours
  String backupLocation;
  DateTime? lastBackupDate;

  // Notifications
  bool notificationsEnabled;
  bool budgetAlerts;
  bool recurringReminders;
  bool goalAchievements;
  String notificationSound;

  // Confidentialité
  bool hideAmounts;
  bool requirePinForExport;
  bool anonymousAnalytics;

  // Avancé
  bool developerMode;
  bool showDebugInfo;
  String dateFormat; // 'dd/MM/yyyy', 'MM/dd/yyyy', etc.
  String timeFormat; // '24h', '12h'

  UserSettings({
    // Général
    this.currency = 'EUR',
    this.language = 'fr',
    this.firstDayOfWeek = 1,

    // Apparence
    this.theme = 'light',
    this.useSystemTheme = false,
    this.primaryColor = '#1E3A8A',
    this.showAnimations = true,

    // Transactions
    this.defaultTransactionType = 'expense',
    this.requireConfirmation = false,
    this.autoCategories = true,
    this.defaultCategoryId,

    // Budgets
    this.budgetNotifications = true,
    this.budgetWarningThreshold = 80.0,
    this.showBudgetSummary = true,
    this.defaultBudgetPeriod = 'monthly',

    // Sécurité
    this.biometricAuth = false,
    this.requireAuthOnStart = false,
    this.requireAuthForTransactions = false,
    this.autoLockMinutes = 0,
    this.dataEncryption = false,

    // Sauvegarde
    this.autoBackup = true,
    this.backupInterval = 7,
    this.backupLocation = 'local',
    this.lastBackupDate,

    // Notifications
    this.notificationsEnabled = true,
    this.budgetAlerts = true,
    this.recurringReminders = true,
    this.goalAchievements = true,
    this.notificationSound = 'default',

    // Confidentialité
    this.hideAmounts = false,
    this.requirePinForExport = false,
    this.anonymousAnalytics = true,

    // Avancé
    this.developerMode = false,
    this.showDebugInfo = false,
    this.dateFormat = 'dd/MM/yyyy',
    this.timeFormat = '24h',
  });

  // Convertir en Map pour SharedPreferences
  Map<String, dynamic> toMap() {
    return {
      // Général
      'currency': currency,
      'language': language,
      'first_day_of_week': firstDayOfWeek,

      // Apparence
      'theme': theme,
      'use_system_theme': useSystemTheme,
      'primary_color': primaryColor,
      'show_animations': showAnimations,

      // Transactions
      'default_transaction_type': defaultTransactionType,
      'require_confirmation': requireConfirmation,
      'auto_categories': autoCategories,
      'default_category_id': defaultCategoryId,

      // Budgets
      'budget_notifications': budgetNotifications,
      'budget_warning_threshold': budgetWarningThreshold,
      'show_budget_summary': showBudgetSummary,
      'default_budget_period': defaultBudgetPeriod,

      // Sécurité
      'biometric_auth': biometricAuth,
      'require_auth_on_start': requireAuthOnStart,
      'require_auth_for_transactions': requireAuthForTransactions,
      'auto_lock_minutes': autoLockMinutes,
      'data_encryption': dataEncryption,

      // Sauvegarde
      'auto_backup': autoBackup,
      'backup_interval': backupInterval,
      'backup_location': backupLocation,
      'last_backup_date': lastBackupDate?.toIso8601String(),

      // Notifications
      'notifications_enabled': notificationsEnabled,
      'budget_alerts': budgetAlerts,
      'recurring_reminders': recurringReminders,
      'goal_achievements': goalAchievements,
      'notification_sound': notificationSound,

      // Confidentialité
      'hide_amounts': hideAmounts,
      'require_pin_for_export': requirePinForExport,
      'anonymous_analytics': anonymousAnalytics,

      // Avancé
      'developer_mode': developerMode,
      'show_debug_info': showDebugInfo,
      'date_format': dateFormat,
      'time_format': timeFormat,
    };
  }

  // Créer depuis Map
  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      // Général
      currency: map['currency'] ?? 'EUR',
      language: map['language'] ?? 'fr',
      firstDayOfWeek: map['first_day_of_week'] ?? 1,

      // Apparence
      theme: map['theme'] ?? 'light',
      useSystemTheme: map['use_system_theme'] ?? false,
      primaryColor: map['primary_color'] ?? '#1E3A8A',
      showAnimations: map['show_animations'] ?? true,

      // Transactions
      defaultTransactionType: map['default_transaction_type'] ?? 'expense',
      requireConfirmation: map['require_confirmation'] ?? false,
      autoCategories: map['auto_categories'] ?? true,
      defaultCategoryId: map['default_category_id'],

      // Budgets
      budgetNotifications: map['budget_notifications'] ?? true,
      budgetWarningThreshold: map['budget_warning_threshold'] ?? 80.0,
      showBudgetSummary: map['show_budget_summary'] ?? true,
      defaultBudgetPeriod: map['default_budget_period'] ?? 'monthly',

      // Sécurité
      biometricAuth: map['biometric_auth'] ?? false,
      requireAuthOnStart: map['require_auth_on_start'] ?? false,
      requireAuthForTransactions: map['require_auth_for_transactions'] ?? false,
      autoLockMinutes: map['auto_lock_minutes'] ?? 0,
      dataEncryption: map['data_encryption'] ?? false,

      // Sauvegarde
      autoBackup: map['auto_backup'] ?? true,
      backupInterval: map['backup_interval'] ?? 7,
      backupLocation: map['backup_location'] ?? 'local',
      lastBackupDate: map['last_backup_date'] != null
          ? DateTime.parse(map['last_backup_date'])
          : null,

      // Notifications
      notificationsEnabled: map['notifications_enabled'] ?? true,
      budgetAlerts: map['budget_alerts'] ?? true,
      recurringReminders: map['recurring_reminders'] ?? true,
      goalAchievements: map['goal_achievements'] ?? true,
      notificationSound: map['notification_sound'] ?? 'default',

      // Confidentialité
      hideAmounts: map['hide_amounts'] ?? false,
      requirePinForExport: map['require_pin_for_export'] ?? false,
      anonymousAnalytics: map['anonymous_analytics'] ?? true,

      // Avancé
      developerMode: map['developer_mode'] ?? false,
      showDebugInfo: map['show_debug_info'] ?? false,
      dateFormat: map['date_format'] ?? 'dd/MM/yyyy',
      timeFormat: map['time_format'] ?? '24h',
    );
  }

  // Copier avec modifications
  UserSettings copyWith({
    String? currency,
    String? language,
    int? firstDayOfWeek,
    String? theme,
    bool? useSystemTheme,
    String? primaryColor,
    bool? showAnimations,
    String? defaultTransactionType,
    bool? requireConfirmation,
    bool? autoCategories,
    int? defaultCategoryId,
    bool? budgetNotifications,
    double? budgetWarningThreshold,
    bool? showBudgetSummary,
    String? defaultBudgetPeriod,
    bool? biometricAuth,
    bool? requireAuthOnStart,
    bool? requireAuthForTransactions,
    int? autoLockMinutes,
    bool? dataEncryption,
    bool? autoBackup,
    int? backupInterval,
    String? backupLocation,
    DateTime? lastBackupDate,
    bool? notificationsEnabled,
    bool? budgetAlerts,
    bool? recurringReminders,
    bool? goalAchievements,
    String? notificationSound,
    bool? hideAmounts,
    bool? requirePinForExport,
    bool? anonymousAnalytics,
    bool? developerMode,
    bool? showDebugInfo,
    String? dateFormat,
    String? timeFormat,
  }) {
    return UserSettings(
      currency: currency ?? this.currency,
      language: language ?? this.language,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      theme: theme ?? this.theme,
      useSystemTheme: useSystemTheme ?? this.useSystemTheme,
      primaryColor: primaryColor ?? this.primaryColor,
      showAnimations: showAnimations ?? this.showAnimations,
      defaultTransactionType:
          defaultTransactionType ?? this.defaultTransactionType,
      requireConfirmation: requireConfirmation ?? this.requireConfirmation,
      autoCategories: autoCategories ?? this.autoCategories,
      defaultCategoryId: defaultCategoryId ?? this.defaultCategoryId,
      budgetNotifications: budgetNotifications ?? this.budgetNotifications,
      budgetWarningThreshold:
          budgetWarningThreshold ?? this.budgetWarningThreshold,
      showBudgetSummary: showBudgetSummary ?? this.showBudgetSummary,
      defaultBudgetPeriod: defaultBudgetPeriod ?? this.defaultBudgetPeriod,
      biometricAuth: biometricAuth ?? this.biometricAuth,
      requireAuthOnStart: requireAuthOnStart ?? this.requireAuthOnStart,
      requireAuthForTransactions:
          requireAuthForTransactions ?? this.requireAuthForTransactions,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      dataEncryption: dataEncryption ?? this.dataEncryption,
      autoBackup: autoBackup ?? this.autoBackup,
      backupInterval: backupInterval ?? this.backupInterval,
      backupLocation: backupLocation ?? this.backupLocation,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      budgetAlerts: budgetAlerts ?? this.budgetAlerts,
      recurringReminders: recurringReminders ?? this.recurringReminders,
      goalAchievements: goalAchievements ?? this.goalAchievements,
      notificationSound: notificationSound ?? this.notificationSound,
      hideAmounts: hideAmounts ?? this.hideAmounts,
      requirePinForExport: requirePinForExport ?? this.requirePinForExport,
      anonymousAnalytics: anonymousAnalytics ?? this.anonymousAnalytics,
      developerMode: developerMode ?? this.developerMode,
      showDebugInfo: showDebugInfo ?? this.showDebugInfo,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
    );
  }
}
