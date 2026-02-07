import 'package:flutter/foundation.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../database/database_helper.dart';
import '../database/db_constants.dart';

/// Provider pour la gestion des budgets
class BudgetProvider with ChangeNotifier {
  List<BudgetModel> _budgets = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<BudgetModel> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Obtenir les budgets actifs
  List<BudgetModel> get activeBudgets {
    return _budgets.where((b) => b.isActive).toList()
      ..sort((a, b) => a.percentageUsed.compareTo(b.percentageUsed));
  }

  /// Obtenir les budgets dépassés
  List<BudgetModel> get exceededBudgets {
    return activeBudgets.where((b) => b.isExceeded).toList();
  }

  /// Obtenir les budgets proches du seuil
  List<BudgetModel> get budgetsNearThreshold {
    return activeBudgets.where((b) => b.isNearThreshold && !b.isExceeded).toList();
  }

  /// Initialiser et charger les budgets
  Future<void> initialize() async {
    await loadBudgets();
  }

  /// Charger tous les budgets
  Future<void> loadBudgets() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DbConstants.tableBudgets,
        orderBy: '${DbConstants.columnCreatedAt} DESC',
      );

      _budgets = maps.map((map) => BudgetModel.fromMap(map)).toList();

      // Mettre à jour les dépenses courantes
      await _updateAllBudgetSpent();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Erreur loadBudgets: $e');
    }
  }

  /// Ajouter un budget
  Future<bool> addBudget(BudgetModel budget) async {
    try {
      // Vérifier qu'il n'existe pas déjà un budget pour cette catégorie et période
      final existing = _budgets.where((b) =>
          b.categoryId == budget.categoryId &&
          b.periodType == budget.periodType &&
          b.isActive);

      if (existing.isNotEmpty) {
        _errorMessage = 'Un budget existe déjà pour cette catégorie et période';
        notifyListeners();
        return false;
      }

      final db = await DatabaseHelper.instance.database;
      final id = await db.insert(
        DbConstants.tableBudgets,
        budget.toMap(),
      );

      final newBudget = budget.copyWith(id: id);
      _budgets.add(newBudget);

      // Calculer les dépenses actuelles
      await _updateBudgetSpent(newBudget);

      notifyListeners();
      debugPrint('✅ Budget ajouté: Catégorie ${newBudget.categoryId}');
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'ajout: $e';
      notifyListeners();
      debugPrint('❌ Erreur addBudget: $e');
      return false;
    }
  }

  /// Mettre à jour un budget
  Future<bool> updateBudget(BudgetModel budget) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Mettre à jour la date de modification
      final updatedBudget = budget.copyWith(updatedAt: DateTime.now());
      
      await db.update(
        DbConstants.tableBudgets,
        updatedBudget.toMap(),
        where: '${DbConstants.columnId} = ?',
        whereArgs: [budget.id],
      );

      final index = _budgets.indexWhere((b) => b.id == budget.id);
      if (index != -1) {
        _budgets[index] = updatedBudget;
      }

      notifyListeners();
      debugPrint('✅ Budget mis à jour: ID ${updatedBudget.id}');
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour: $e';
      notifyListeners();
      debugPrint('❌ Erreur updateBudget: $e');
      return false;
    }
  }

  /// Supprimer un budget
  Future<bool> deleteBudget(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        DbConstants.tableBudgets,
        where: '${DbConstants.columnId} = ?',
        whereArgs: [id],
      );

      _budgets.removeWhere((b) => b.id == id);

      notifyListeners();
      debugPrint('✅ Budget supprimé: ID $id');
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression: $e';
      notifyListeners();
      debugPrint('❌ Erreur deleteBudget: $e');
      return false;
    }
  }

  /// Activer/Désactiver un budget
  Future<bool> toggleBudgetActive(int id) async {
    try {
      final budget = _budgets.firstWhere((b) => b.id == id);
      return await updateBudget(budget.copyWith(isActive: !budget.isActive));
    } catch (e) {
      _errorMessage = 'Erreur lors du changement d\'état: $e';
      notifyListeners();
      debugPrint('❌ Erreur toggleBudgetActive: $e');
      return false;
    }
  }

  /// Mettre à jour les dépenses d'un budget spécifique
  Future<void> _updateBudgetSpent([BudgetModel? specificBudget]) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      for (var budget in _budgets) {
        if (specificBudget != null && budget.id != specificBudget.id) continue;
        
        // Calculer les dates de début et fin selon le type de période
        final period = _getPeriodDates(budget.periodType, budget.startDate);
        
        // Récupérer les transactions de dépenses pour cette catégorie dans la période
        final result = await db.rawQuery('''
          SELECT COALESCE(SUM(${DbConstants.columnAmount}), 0) as total
          FROM ${DbConstants.tableTransactions}
          WHERE ${DbConstants.columnCategoryId} = ?
            AND ${DbConstants.columnTransactionType} = 'expense'
            AND ${DbConstants.columnDate} >= ?
            AND ${DbConstants.columnDate} <= ?
      ''', [budget.categoryId, period['start'], period['end']]);

        final spent = (result.first['total'] as num).toDouble();

        // Mettre à jour le budget
        if (budget.currentSpent != spent) {
          final updatedBudget = budget.copyWith(currentSpent: spent);
          
          final index = _budgets.indexWhere((b) => b.id == budget.id);
          if (index != -1) {
            _budgets[index] = updatedBudget;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur _updateBudgetSpent: $e');
    }
  }

  /// Mettre à jour toutes les dépenses des budgets
  Future<void> _updateAllBudgetSpent() async {
    for (var budget in _budgets) {
      await _updateBudgetSpent(budget);
    }
  }

  /// Recalculer les dépenses après une transaction
  Future<void> recalculateAfterTransaction(TransactionModel transaction) async {
    if (transaction.transactionType != 'expense') return;

    final budgetsToUpdate = _budgets.where(
      (b) => b.categoryId == transaction.categoryId && b.isActive,
    );

    for (var budget in budgetsToUpdate) {
      await _updateBudgetSpent(budget);
    }

    notifyListeners();
  }

  /// Obtenir les dates de période selon le type
  Map<String, String> _getPeriodDates(String periodType, DateTime startDate) {
    DateTime start;
    DateTime end;

    switch (periodType) {
      case 'daily':
        start = DateTime(startDate.year, startDate.month, startDate.day);
        end = start.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
        break;
      case 'weekly':
        start = startDate.subtract(Duration(days: startDate.weekday - 1));
        end = start.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
        break;
      case 'monthly':
        start = DateTime(startDate.year, startDate.month, 1);
        end = DateTime(startDate.year, startDate.month + 1, 0, 23, 59, 59);
        break;
      case 'yearly':
        start = DateTime(startDate.year, 1, 1);
        end = DateTime(startDate.year, 12, 31, 23, 59, 59);
        break;
      default:
        start = startDate;
        end = DateTime.now();
    }

    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    };
  }

  /// Obtenir un budget par ID
  BudgetModel? getBudgetById(int id) {
    try {
      return _budgets.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtenir les budgets pour une catégorie
  List<BudgetModel> getBudgetsByCategory(int categoryId) {
    return _budgets.where((b) => b.categoryId == categoryId).toList();
  }

  /// Vérifier si une dépense dépasserait le budget
  bool wouldExceedBudget(int categoryId, double amount) {
    final budget = activeBudgets.firstWhere(
      (b) => b.categoryId == categoryId,
      orElse: () => BudgetModel(
        categoryId: -1,
        amountLimit: 0,
        periodType: 'monthly',
        startDate: DateTime.now(),
      ),
    );

    if (budget.categoryId == -1) return false;

    return (budget.currentSpent + amount) > budget.amountLimit;
  }

  /// Obtenir le montant disponible pour une catégorie
  double getAvailableAmount(int categoryId) {
    final budget = activeBudgets.firstWhere(
      (b) => b.categoryId == categoryId,
      orElse: () => BudgetModel(
        categoryId: -1,
        amountLimit: 0,
        periodType: 'monthly',
        startDate: DateTime.now(),
      ),
    );

    if (budget.categoryId == -1) return double.infinity;

    return budget.remainingAmount;
  }

  /// Statistiques globales des budgets
  Map<String, dynamic> getBudgetStats() {
    final active = activeBudgets;
    
    if (active.isEmpty) {
      return {
        'totalLimit': 0.0,
        'totalSpent': 0.0,
        'totalRemaining': 0.0,
        'averageUsage': 0.0,
        'budgetsCount': 0,
        'exceededCount': 0,
      };
    }

    final totalLimit = active.fold(0.0, (sum, b) => sum + b.amountLimit);
    final totalSpent = active.fold(0.0, (sum, b) => sum + b.currentSpent);
    final totalRemaining = active.fold(0.0, (sum, b) => sum + b.remainingAmount);
    final averageUsage = active.fold(0.0, (sum, b) => sum + b.percentageUsed) / active.length;

    return {
      'totalLimit': totalLimit,
      'totalSpent': totalSpent,
      'totalRemaining': totalRemaining,
      'averageUsage': averageUsage,
      'budgetsCount': active.length,
      'exceededCount': exceededBudgets.length,
    };
  }

  /// Réinitialiser les erreurs
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
