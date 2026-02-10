/// Constantes pour la base de données SQLite
class DbConstants {
  // Nom de la base de données
  static const String databaseName = 'budget_buddy.db';
  static const int databaseVersion = 1;

  // Tables
  static const String tableTransactions = 'transactions';
  static const String tableCategories = 'categories';
  static const String tableBudgets = 'budgets';
  static const String tableSavingsGoals = 'savings_goals';
  static const String tableAccounts = 'accounts';
  static const String tableTransactionAccounts = 'transaction_accounts';
  static const String tableReports = 'reports';
  static const String tableUserSettings = 'user_settings';
  static const String tableAuditLog = 'audit_log';

  // Colonnes communes
  static const String columnId = 'id';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  // Colonnes transactions
  static const String columnTitle = 'title';
  static const String columnAmount = 'amount';
  static const String columnDate = 'date';
  static const String columnCategoryId = 'category_id';
  static const String columnTransactionType = 'transaction_type';
  static const String columnPaymentMethod = 'payment_method';
  static const String columnDescription = 'description';
  static const String columnLocation = 'location';
  static const String columnIsRecurring = 'is_recurring';
  static const String columnRecurringPattern = 'recurring_pattern';
  static const String columnNextOccurrence = 'next_occurrence';

  // Colonnes catégories
  static const String columnName = 'name';
  static const String columnIcon = 'icon';
  static const String columnColor = 'color';
  static const String columnCategoryType = 'category_type';
  static const String columnIsDefault = 'is_default';
  static const String columnIsActive = 'is_active';
  static const String columnSortOrder = 'sort_order';

  // Colonnes budgets
  static const String columnAmountLimit = 'amount_limit';
  static const String columnPeriodType = 'period_type';
  static const String columnStartDate = 'start_date';
  static const String columnEndDate = 'end_date';
  static const String columnCurrentSpent = 'current_spent';
  static const String columnNotificationsEnabled = 'notifications_enabled';
  static const String columnNotificationThreshold = 'notification_threshold';

  // Colonnes savings goals
  static const String columnTargetAmount = 'target_amount';
  static const String columnCurrentAmount = 'current_amount';
  static const String columnTargetDate = 'target_date';
  static const String columnIsCompleted = 'is_completed';

  // Colonnes comptes
  static const String columnAccountName = 'name';
  static const String columnAccountType = 'account_type';
  static const String columnInitialBalance = 'initial_balance';
  static const String columnCurrentBalance = 'current_balance';
  static const String columnCurrency = 'currency';
  static const String columnAccountIcon = 'icon';
  static const String columnAccountColor = 'color';

  // Types de transactions
  static const String transactionTypeIncome = 'income';
  static const String transactionTypeExpense = 'expense';

  // Types de périodes
  static const String periodDaily = 'daily';
  static const String periodWeekly = 'weekly';
  static const String periodMonthly = 'monthly';
  static const String periodYearly = 'yearly';
}
