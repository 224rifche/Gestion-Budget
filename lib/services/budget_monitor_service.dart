import 'package:flutter/foundation.dart';
import '../providers/budget_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../services/notification_service.dart';
import '../models/budget.dart';

/// Service de surveillance des budgets pour les notifications automatiques
class BudgetMonitorService {
  static final BudgetMonitorService instance = BudgetMonitorService._init();

  BudgetMonitorService._init();

  /// Surveiller les budgets après une transaction
  Future<void> checkBudgetsAfterTransaction(
    BudgetProvider budgetProvider,
    TransactionProvider transactionProvider,
    CategoryProvider categoryProvider,
  ) async {
    try {
      // Recharger les budgets pour avoir les données à jour
      await budgetProvider.loadBudgets();

      final budgets = budgetProvider.activeBudgets;

      for (final budget in budgets) {
        await _checkSingleBudget(budget, categoryProvider);
      }
    } catch (e) {
      debugPrint('❌ Erreur surveillance budgets: $e');
    }
  }

  /// Vérifier un budget spécifique
  Future<void> _checkSingleBudget(
    BudgetModel budget,
    CategoryProvider categoryProvider,
  ) async {
    final category = categoryProvider.getCategoryById(budget.categoryId);
    if (category == null) return;

    final percentage = budget.percentageUsed;
    final spent = budget.currentSpent;
    final limit = budget.amountLimit;

    debugPrint(
      '🔍 Budget ${category.name}: ${percentage.toStringAsFixed(1)}% utilisé',
    );

    // Notification d'avertissement (80% ou plus)
    if (percentage >= 80 && percentage < 100 && budget.notificationsEnabled) {
      await NotificationService.instance.showBudgetWarning(
        categoryName: category.name,
        percentage: percentage,
        spent: spent,
        limit: limit,
      );
    }

    // Notification de dépassement critique (100% ou plus)
    if (percentage >= 100 && budget.notificationsEnabled) {
      final exceeded = spent - limit;
      await NotificationService.instance.showBudgetExceeded(
        categoryName: category.name,
        exceeded: exceeded,
        limit: limit,
      );
    }
  }

  /// Vérifier tous les budgets (appel manuel)
  Future<void> checkAllBudgets(
    BudgetProvider budgetProvider,
    CategoryProvider categoryProvider,
  ) async {
    try {
      await budgetProvider.loadBudgets();
      final budgets = budgetProvider.activeBudgets;

      debugPrint('🔍 Surveillance de ${budgets.length} budgets');

      for (final budget in budgets) {
        await _checkSingleBudget(budget, categoryProvider);
      }
    } catch (e) {
      debugPrint('❌ Erreur vérification budgets: $e');
    }
  }

  /// Vérifier les objectifs d'épargne atteints
  Future<void> checkSavingsGoals(dynamic savingsGoalProvider) async {
    try {
      // Recharger les objectifs
      await savingsGoalProvider.loadGoals();

      final goals = savingsGoalProvider.goals;

      for (final goal in goals) {
        if (goal.isCompleted && !goal.hasNotified) {
          await NotificationService.instance.showGoalAchieved(
            goalName: goal.name,
            amount: goal.currentAmount,
          );

          // Marquer comme notifié (nécessite une modification du modèle)
          // goal.hasNotified = true;
          // await savingsGoalProvider.updateGoal(goal);
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur vérification objectifs: $e');
    }
  }

  /// Surveillance périodique (peut être appelée par un timer)
  Future<void> periodicCheck(
    BudgetProvider budgetProvider,
    TransactionProvider transactionProvider,
    CategoryProvider categoryProvider,
    dynamic savingsGoalProvider,
  ) async {
    debugPrint('🕐 Surveillance périodique des budgets et objectifs');

    await checkAllBudgets(budgetProvider, categoryProvider);
    await checkSavingsGoals(savingsGoalProvider);
  }
}
