import 'package:flutter/foundation.dart';
import '../models/savings_goal.dart';
import '../database/database_helper.dart';
import '../database/db_constants.dart';

/// Provider pour la gestion des objectifs d'épargne
class SavingsGoalProvider with ChangeNotifier {
  List<SavingsGoalModel> _goals = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<SavingsGoalModel> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Obtenir les objectifs actifs (non complétés)
  List<SavingsGoalModel> get activeGoals {
    return _goals.where((g) => !g.isCompleted).toList()..sort((a, b) {
      // Trier par date cible (les plus proches en premier)
      if (a.targetDate == null && b.targetDate == null) return 0;
      if (a.targetDate == null) return 1;
      if (b.targetDate == null) return -1;
      return a.targetDate!.compareTo(b.targetDate!);
    });
  }

  /// Obtenir les objectifs complétés
  List<SavingsGoalModel> get completedGoals {
    return _goals.where((g) => g.isCompleted).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Montant total économisé
  double get totalSaved {
    return _goals.fold(0.0, (sum, goal) => sum + goal.currentAmount);
  }

  /// Montant total visé
  double get totalTarget {
    return _goals.fold(0.0, (sum, goal) => sum + goal.targetAmount);
  }

  /// Pourcentage global d'atteinte des objectifs
  double get overallProgress {
    if (totalTarget == 0) return 0;
    return (totalSaved / totalTarget * 100).clamp(0, 100);
  }

  /// Initialiser et charger les objectifs
  Future<void> initialize() async {
    await loadGoals();
  }

  /// Charger tous les objectifs
  Future<void> loadGoals() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DbConstants.tableSavingsGoals,
        orderBy: '${DbConstants.columnTargetDate} ASC',
      );

      _goals = maps.map((map) => SavingsGoalModel.fromMap(map)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Erreur loadGoals: $e');
    }
  }

  /// Ajouter un objectif d'épargne
  Future<bool> addGoal(SavingsGoalModel goal) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final id = await db.insert(DbConstants.tableSavingsGoals, goal.toMap());

      final newGoal = goal.copyWith(id: id);
      _goals.add(newGoal);

      notifyListeners();
      debugPrint('✅ Objectif ajouté: ${newGoal.name}');
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'ajout: $e';
      notifyListeners();
      debugPrint('❌ Erreur addGoal: $e');
      return false;
    }
  }

  /// Mettre à jour un objectif
  Future<bool> updateGoal(SavingsGoalModel goal) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Mettre à jour la date de modification
      final updatedGoal = goal.copyWith(updatedAt: DateTime.now());

      await db.update(
        DbConstants.tableSavingsGoals,
        updatedGoal.toMap(),
        where: '${DbConstants.columnId} = ?',
        whereArgs: [goal.id],
      );

      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _goals[index] = updatedGoal;
      }

      notifyListeners();
      debugPrint('✅ Objectif mis à jour: ${updatedGoal.name}');
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour: $e';
      notifyListeners();
      debugPrint('❌ Erreur updateGoal: $e');
      return false;
    }
  }

  /// Ajouter un montant à l'objectif
  Future<bool> addAmountToGoal(int goalId, double amount) async {
    try {
      final goal = _goals.firstWhere((g) => g.id == goalId);
      final newAmount = goal.currentAmount + amount;

      // Vérifier si l'objectif est atteint
      final isCompleted = newAmount >= goal.targetAmount;

      final updatedGoal = goal.copyWith(
        currentAmount: newAmount,
        isCompleted: isCompleted,
        updatedAt: DateTime.now(),
      );

      return await updateGoal(updatedGoal);
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'ajout du montant: $e';
      notifyListeners();
      debugPrint('❌ Erreur addAmountToGoal: $e');
      return false;
    }
  }

  /// Retirer un montant de l'objectif
  Future<bool> removeAmountFromGoal(int goalId, double amount) async {
    try {
      final goal = _goals.firstWhere((g) => g.id == goalId);
      final newAmount = (goal.currentAmount - amount).clamp(
        0.0,
        double.infinity,
      );

      final updatedGoal = goal.copyWith(
        currentAmount: newAmount,
        isCompleted: false,
        updatedAt: DateTime.now(),
      );

      return await updateGoal(updatedGoal);
    } catch (e) {
      _errorMessage = 'Erreur lors du retrait du montant: $e';
      notifyListeners();
      debugPrint('❌ Erreur removeAmountFromGoal: $e');
      return false;
    }
  }

  /// Marquer un objectif comme complété
  Future<bool> completeGoal(int goalId) async {
    try {
      final goal = _goals.firstWhere((g) => g.id == goalId);
      final updatedGoal = goal.copyWith(
        isCompleted: true,
        updatedAt: DateTime.now(),
      );

      return await updateGoal(updatedGoal);
    } catch (e) {
      _errorMessage = 'Erreur lors de la complétion: $e';
      notifyListeners();
      debugPrint('❌ Erreur completeGoal: $e');
      return false;
    }
  }

  /// Supprimer un objectif
  Future<bool> deleteGoal(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        DbConstants.tableSavingsGoals,
        where: '${DbConstants.columnId} = ?',
        whereArgs: [id],
      );

      _goals.removeWhere((g) => g.id == id);

      notifyListeners();
      debugPrint('✅ Objectif supprimé: ID $id');
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression: $e';
      notifyListeners();
      debugPrint('❌ Erreur deleteGoal: $e');
      return false;
    }
  }

  /// Obtenir un objectif par ID
  SavingsGoalModel? getGoalById(int id) {
    try {
      return _goals.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Calculer le montant nécessaire par jour pour atteindre l'objectif
  double dailySavingsNeeded(SavingsGoalModel goal) {
    if (goal.targetDate == null || goal.isAchieved) return 0;

    final daysRemaining = goal.daysRemaining ?? 0;
    if (daysRemaining <= 0) return 0;

    return goal.remainingAmount / daysRemaining;
  }

  /// Obtenir les objectifs en retard
  List<SavingsGoalModel> get overdueGoals {
    final now = DateTime.now();
    return _goals.where((goal) {
      return goal.targetDate != null &&
          goal.targetDate!.isBefore(now) &&
          !goal.isCompleted;
    }).toList();
  }

  /// Obtenir les objectifs proches de la date limite
  List<SavingsGoalModel> getGoalsNearDeadline({int daysThreshold = 30}) {
    final now = DateTime.now();
    final threshold = now.add(Duration(days: daysThreshold));

    return _goals.where((goal) {
      return goal.targetDate != null &&
          goal.targetDate!.isAfter(now) &&
          goal.targetDate!.isBefore(threshold) &&
          !goal.isCompleted;
    }).toList();
  }

  /// Réinitialiser les erreurs
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
