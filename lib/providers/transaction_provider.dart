import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../database/database_helper.dart';
import '../services/budget_monitor_service.dart';

class TransactionProvider with ChangeNotifier {
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filtres actuels
  String? _selectedType; // 'income' ou 'expense'
  int? _selectedCategoryId;
  DateTime? _startDate;
  DateTime? _endDate;

  // Services pour les notifications
  BudgetMonitorService? _budgetMonitorService;

  // Getters
  List<TransactionModel> get transactions => _filteredTransactions;
  List<TransactionModel> get allTransactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedType => _selectedType;
  int? get selectedCategoryId => _selectedCategoryId;

  /// Définir le service de surveillance (injecté par HomeScreen)
  void setBudgetMonitorService(BudgetMonitorService service) {
    _budgetMonitorService = service;
  }

  /// Initialiser et charger les transactions
  Future<void> initialize() async {
    await loadTransactions();
  }

  /// Charger toutes les transactions
  Future<void> loadTransactions() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        orderBy: 'date DESC',
      );

      _transactions = maps.map((map) => TransactionModel.fromMap(map)).toList();
      _applyFilters();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ajouter une transaction
  Future<bool> addTransaction(TransactionModel transaction) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final id = await db.insert('transactions', transaction.toMap());

      // Ajouter à la liste locale
      final newTransaction = transaction.copyWith(id: id);
      _transactions.insert(0, newTransaction);
      _applyFilters();

      // Vérifier les budgets après ajout de transaction (dépenses uniquement)
      if (transaction.transactionType == 'expense' &&
          _budgetMonitorService != null) {
        // Note: Cette méthode nécessitera les autres providers
        // Pour l'instant, nous allons juste logger
        debugPrint(
          '🔍 Surveillance budgets après transaction: ${transaction.title}',
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'ajout: $e';
      notifyListeners();
      return false;
    }
  }

  /// Mettre à jour une transaction
  Future<bool> updateTransaction(TransactionModel transaction) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      // Mettre à jour dans la liste locale
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
        _applyFilters();
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour: $e';
      notifyListeners();
      return false;
    }
  }

  /// Supprimer une transaction
  Future<bool> deleteTransaction(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('transactions', where: 'id = ?', whereArgs: [id]);

      // Supprimer de la liste locale
      _transactions.removeWhere((t) => t.id == id);
      _applyFilters();

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression: $e';
      notifyListeners();
      return false;
    }
  }

  /// Filtrer par type
  void filterByType(String? type) {
    _selectedType = type;
    _applyFilters();
    notifyListeners();
  }

  /// Filtrer par catégorie
  void filterByCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters();
    notifyListeners();
  }

  /// Filtrer par période
  void filterByDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _applyFilters();
    notifyListeners();
  }

  /// Réinitialiser les filtres
  void resetFilters() {
    _selectedType = null;
    _selectedCategoryId = null;
    _startDate = null;
    _endDate = null;
    _applyFilters();
    notifyListeners();
  }

  /// Appliquer les filtres
  void _applyFilters() {
    _filteredTransactions = _transactions.where((transaction) {
      // Filtre par type
      if (_selectedType != null &&
          transaction.transactionType != _selectedType) {
        return false;
      }

      // Filtre par catégorie
      if (_selectedCategoryId != null &&
          transaction.categoryId != _selectedCategoryId) {
        return false;
      }

      // Filtre par date
      if (_startDate != null && transaction.date.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && transaction.date.isAfter(_endDate!)) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Obtenir les transactions d'un mois spécifique
  List<TransactionModel> getTransactionsByMonth(DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return _transactions.where((transaction) {
      return transaction.date.isAfter(startOfMonth) &&
          transaction.date.isBefore(endOfMonth);
    }).toList();
  }

  /// Obtenir le total des revenus pour une période
  double getTotalIncome({DateTime? start, DateTime? end}) {
    return _getTransactionsByPeriod(start, end)
        .where((t) => t.transactionType == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Obtenir le total des dépenses pour une période
  double getTotalExpense({DateTime? start, DateTime? end}) {
    return _getTransactionsByPeriod(start, end)
        .where((t) => t.transactionType == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Obtenir le solde pour une période
  double getBalance({DateTime? start, DateTime? end}) {
    return getTotalIncome(start: start, end: end) -
        getTotalExpense(start: start, end: end);
  }

  /// Obtenir les transactions d'une période (méthode publique)
  List<TransactionModel> getTransactionsByPeriod(
    DateTime? start,
    DateTime? end,
  ) {
    return _getTransactionsByPeriod(start, end);
  }

  /// Helper pour obtenir les transactions d'une période
  List<TransactionModel> _getTransactionsByPeriod(
    DateTime? start,
    DateTime? end,
  ) {
    return _transactions.where((transaction) {
      if (start != null && transaction.date.isBefore(start)) {
        return false;
      }
      if (end != null && transaction.date.isAfter(end)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Grouper les transactions par catégorie
  Map<int, double> getExpensesByCategory({DateTime? start, DateTime? end}) {
    final expenses = _getTransactionsByPeriod(
      start,
      end,
    ).where((t) => t.transactionType == 'expense');

    final Map<int, double> result = {};
    for (var transaction in expenses) {
      result[transaction.categoryId] =
          (result[transaction.categoryId] ?? 0) + transaction.amount;
    }
    return result;
  }
}
