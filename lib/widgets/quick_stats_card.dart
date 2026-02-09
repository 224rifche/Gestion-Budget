import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/savings_goal_provider.dart';
import '../utils/formatters.dart';

/// Carte affichant des statistiques rapides (nombre de transactions, budgets, etc.)
class QuickStatsCard extends StatefulWidget {
  const QuickStatsCard({super.key});

  @override
  State<QuickStatsCard> createState() => _QuickStatsCardState();
}

class _QuickStatsCardState extends State<QuickStatsCard> {
  @override
  Widget build(BuildContext context) {
    return Consumer3<TransactionProvider, BudgetProvider, SavingsGoalProvider>(
      builder:
          (
            context,
            transactionProvider,
            budgetProvider,
            savingsProvider,
            child,
          ) {
            // Calculer les statistiques
            final transactionsThisMonth = transactionProvider
                .getTransactionsByMonth(DateTime.now());
            final activeBudgets = budgetProvider.activeBudgets.length;
            final activeGoals = savingsProvider.activeGoals.length;
            final totalSaved = savingsProvider.totalSaved;

            return RepaintBoundary(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aperçu rapide',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              context,
                              icon: Icons.receipt_long,
                              label: 'Transactions',
                              value: '${transactionsThisMonth.length}',
                              color: Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              context,
                              icon: Icons.account_balance_wallet,
                              label: 'Budgets',
                              value: '$activeBudgets',
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              context,
                              icon: Icons.savings,
                              label: 'Objectifs',
                              value: '$activeGoals',
                              color: Colors.green,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              context,
                              icon: Icons.trending_up,
                              label: 'Épargné',
                              value: Formatters.formatCompactCurrency(
                                totalSaved,
                              ),
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
    );
  }

  /// Construire un élément de statistique
  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
