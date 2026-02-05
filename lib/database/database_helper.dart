import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';
import 'db_constants.dart';

/// Classe singleton pour gérer la base de données SQLite
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Getter pour accéder à la base de données
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(DbConstants.databaseName);
    return _database!;
  }

  /// Initialiser la base de données
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: DbConstants.databaseVersion,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  /// Configurer les contraintes de clés étrangères
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Créer toutes les tables
  Future<void> _createDB(Database db, int version) async {
    // Table Categories (doit être créée en premier car référencée par transactions)
    await db.execute('''
      CREATE TABLE ${DbConstants.tableCategories} (
        ${DbConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.columnName} TEXT NOT NULL UNIQUE,
        ${DbConstants.columnIcon} TEXT NOT NULL,
        ${DbConstants.columnColor} TEXT NOT NULL,
        ${DbConstants.columnCategoryType} TEXT NOT NULL CHECK(${DbConstants.columnCategoryType} IN ('income', 'expense')),
        ${DbConstants.columnIsDefault} INTEGER DEFAULT 1,
        ${DbConstants.columnIsActive} INTEGER DEFAULT 1,
        ${DbConstants.columnSortOrder} INTEGER DEFAULT 0,
        ${DbConstants.columnCreatedAt} TEXT NOT NULL
      )
    ''');

    // Index pour améliorer les performances
    await db.execute('''
      CREATE INDEX idx_categories_type 
      ON ${DbConstants.tableCategories}(${DbConstants.columnCategoryType})
    ''');

    // Table Transactions
    await db.execute('''
      CREATE TABLE ${DbConstants.tableTransactions} (
        ${DbConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.columnTitle} TEXT NOT NULL,
        ${DbConstants.columnAmount} REAL NOT NULL CHECK(${DbConstants.columnAmount} >= 0),
        ${DbConstants.columnDate} TEXT NOT NULL,
        ${DbConstants.columnCategoryId} INTEGER NOT NULL,
        ${DbConstants.columnTransactionType} TEXT NOT NULL CHECK(${DbConstants.columnTransactionType} IN ('income', 'expense')),
        ${DbConstants.columnPaymentMethod} TEXT,
        ${DbConstants.columnDescription} TEXT,
        ${DbConstants.columnLocation} TEXT,
        ${DbConstants.columnIsRecurring} INTEGER DEFAULT 0,
        ${DbConstants.columnRecurringPattern} TEXT,
        ${DbConstants.columnNextOccurrence} TEXT,
        ${DbConstants.columnCreatedAt} TEXT NOT NULL,
        ${DbConstants.columnUpdatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DbConstants.columnCategoryId}) 
          REFERENCES ${DbConstants.tableCategories}(${DbConstants.columnId}) 
          ON DELETE RESTRICT
      )
    ''');

    // Index pour optimiser les requêtes fréquentes
    await db.execute('''
      CREATE INDEX idx_transactions_date 
      ON ${DbConstants.tableTransactions}(${DbConstants.columnDate} DESC)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_transactions_category 
      ON ${DbConstants.tableTransactions}(${DbConstants.columnCategoryId})
    ''');
    
    await db.execute('''
      CREATE INDEX idx_transactions_type 
      ON ${DbConstants.tableTransactions}(${DbConstants.columnTransactionType})
    ''');

    // Table Budgets
    await db.execute('''
      CREATE TABLE ${DbConstants.tableBudgets} (
        ${DbConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.columnCategoryId} INTEGER NOT NULL,
        ${DbConstants.columnAmountLimit} REAL NOT NULL CHECK(${DbConstants.columnAmountLimit} >= 0),
        ${DbConstants.columnPeriodType} TEXT NOT NULL CHECK(${DbConstants.columnPeriodType} IN ('daily', 'weekly', 'monthly', 'yearly')),
        ${DbConstants.columnStartDate} TEXT NOT NULL,
        ${DbConstants.columnEndDate} TEXT,
        ${DbConstants.columnCurrentSpent} REAL DEFAULT 0,
        ${DbConstants.columnIsActive} INTEGER DEFAULT 1,
        ${DbConstants.columnNotificationsEnabled} INTEGER DEFAULT 1,
        ${DbConstants.columnNotificationThreshold} REAL DEFAULT 80,
        ${DbConstants.columnCreatedAt} TEXT NOT NULL,
        ${DbConstants.columnUpdatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DbConstants.columnCategoryId}) 
          REFERENCES ${DbConstants.tableCategories}(${DbConstants.columnId}) 
          ON DELETE CASCADE
      )
    ''');

    // Table Savings Goals
    await db.execute('''
      CREATE TABLE ${DbConstants.tableSavingsGoals} (
        ${DbConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.columnName} TEXT NOT NULL,
        ${DbConstants.columnTargetAmount} REAL NOT NULL CHECK(${DbConstants.columnTargetAmount} > 0),
        ${DbConstants.columnCurrentAmount} REAL DEFAULT 0,
        ${DbConstants.columnTargetDate} TEXT,
        ${DbConstants.columnIcon} TEXT,
        ${DbConstants.columnColor} TEXT,
        ${DbConstants.columnIsCompleted} INTEGER DEFAULT 0,
        ${DbConstants.columnCreatedAt} TEXT NOT NULL,
        ${DbConstants.columnUpdatedAt} TEXT NOT NULL
      )
    ''');

    // Insérer les données initiales (catégories par défaut)
    await _seedInitialData(db);
  }

  /// Insérer les données initiales (catégories prédéfinies)
  Future<void> _seedInitialData(Database db) async {
    // Catégories de dépenses
    final expenseCategories = [
      "('Alimentation', '🍔', '#FF6B6B', 'expense', 1, 1, 1, '${DateTime.now().toIso8601String()}')",
      "('Transport', '🚗', '#4ECDC4', 'expense', 1, 1, 2, '${DateTime.now().toIso8601String()}')",
      "('Logement', '🏠', '#45B7D1', 'expense', 1, 1, 3, '${DateTime.now().toIso8601String()}')",
      "('Services', '💡', '#96CEB4', 'expense', 1, 1, 4, '${DateTime.now().toIso8601String()}')",
      "('Shopping', '🛍️', '#FFEAA7', 'expense', 1, 1, 5, '${DateTime.now().toIso8601String()}')",
      "('Loisirs', '🎬', '#DDA0DD', 'expense', 1, 1, 6, '${DateTime.now().toIso8601String()}')",
      "('Santé', '🏥', '#F7DC6F', 'expense', 1, 1, 7, '${DateTime.now().toIso8601String()}')",
      "('Éducation', '📚', '#BB8FCE', 'expense', 1, 1, 8, '${DateTime.now().toIso8601String()}')",
      "('Autres dépenses', '📦', '#AAB7B8', 'expense', 1, 1, 9, '${DateTime.now().toIso8601String()}')",
    ];

    // Catégories de revenus
    final incomeCategories = [
      "('Salaire', '💰', '#2ECC71', 'income', 1, 1, 10, '${DateTime.now().toIso8601String()}')",
      "('Freelance', '💼', '#3498DB', 'income', 1, 1, 11, '${DateTime.now().toIso8601String()}')",
      "('Investissements', '📈', '#9B59B6', 'income', 1, 1, 12, '${DateTime.now().toIso8601String()}')",
      "('Cadeaux', '🎁', '#E74C3C', 'income', 1, 1, 13, '${DateTime.now().toIso8601String()}')",
      "('Remboursements', '↪️', '#F39C12', 'income', 1, 1, 14, '${DateTime.now().toIso8601String()}')",
      "('Autres revenus', '📥', '#95A5A6', 'income', 1, 1, 15, '${DateTime.now().toIso8601String()}')",
    ];

    // Insertion en batch
    await db.execute('''
      INSERT INTO ${DbConstants.tableCategories} 
      (name, icon, color, category_type, is_default, is_active, sort_order, created_at) 
      VALUES ${expenseCategories.join(',')}, ${incomeCategories.join(',')}
    ''');
  }

  /// Fermer la base de données
  Future<void> close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }

  /// Réinitialiser la base de données (pour debug/tests)
  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DbConstants.databaseName);
    await deleteDatabase(path);
    _database = null;
  }
}
