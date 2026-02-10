import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../providers/category_provider.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import '../screens/budgets/budgets_screen.dart';

/// Carte affichant la progression des budgets
class BudgetProgressCard extends StatelessWidget {
  final int maxBudgets;

  const BudgetProgressCard({super.key, this.maxBudgets = 3});

  @override
  Widget build(BuildContext context) {
    return Consumer2<BudgetProvider, CategoryProvider>(
      builder: (context, budgetProvider, categoryProvider, child) {
        final budgets = budgetProvider.activeBudgets;

        if (budgets.isEmpty) {
          return _buildEmptyState(context);
        }

        // Prendre les premiers budgets (triés par pourcentage utilisé)
        final displayBudgets = budgets.take(maxBudgets).toList();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                ...displayBudgets.map((budget) {
                  final category = categoryProvider.getCategoryById(
                    budget.categoryId,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildBudgetProgress(
                      context,
                      category?.name ?? 'Inconnu',
                      category?.icon ?? '❓',
                      category?.color ?? '#AAB7B8',
                      budget.currentSpent,
                      budget.amountLimit,
                      budget.percentageUsed,
                    ),
                  );
                }),
                if (budgets.length > maxBudgets)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BudgetsScreen(),
                        ),
                      );
                    },
                    child: Text('Voir tous les budgets (${budgets.length})'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Construire une barre de progression pour un budget
  Widget _buildBudgetProgress(
    BuildContext context,
    String categoryName,
    String icon,
    String colorHex,
    double spent,
    double limit,
    double percentage,
  ) {
    final color = CategoryColors.fromHex(colorHex);
    final isExceeded = spent > limit;
    final isNearLimit = percentage >= 80 && !isExceeded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec icône et montants
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Text(icon, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${Formatters.formatCurrency(spent)} / ${Formatters.formatCurrency(limit)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            // Pourcentage avec badge de statut
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isExceeded
                    ? Colors.red.withValues(alpha: 0.1)
                    : isNearLimit
                    ? Colors.orange.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isExceeded)
                    Icon(Icons.error, size: 14, color: Colors.red)
                  else if (isNearLimit)
                    Icon(Icons.warning_amber, size: 14, color: Colors.orange)
                  else
                    Icon(Icons.check_circle, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isExceeded
                          ? Colors.red
                          : isNearLimit
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Barre de progression
        Stack(
          children: [
            // Fond de la barre
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Progression
            FractionallySizedBox(
              widthFactor: (percentage / 100).clamp(0.0, 1.0),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isExceeded
                        ? [Colors.red.shade400, Colors.red.shade600]
                        : isNearLimit
                        ? [Colors.orange.shade400, Colors.orange.shade600]
                        : [Colors.green.shade400, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),

        // Message d'avertissement
        if (isExceeded || isNearLimit) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isExceeded ? Icons.error : Icons.warning_amber,
                size: 14,
                color: isExceeded ? Colors.red : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                isExceeded
                    ? 'Budget dépassé de ${Formatters.formatCurrency(spent - limit)}'
                    : 'Attention ! ${Formatters.formatCurrency(limit - spent)} restants',
                style: TextStyle(
                  fontSize: 12,
                  color: isExceeded ? Colors.red : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// État vide
  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun budget défini',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez des budgets pour suivre vos dépenses',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
