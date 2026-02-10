import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/budget_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';

/// Écran des statistiques et graphiques
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = 'month';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Consumer3<TransactionProvider, CategoryProvider, BudgetProvider>(
        builder:
            (
              context,
              transactionProvider,
              categoryProvider,
              budgetProvider,
              child,
            ) {
              final now = DateTime.now();
              DateTime startDate;
              DateTime endDate;

              switch (_selectedPeriod) {
                case 'week':
                  startDate = now.subtract(const Duration(days: 7));
                  endDate = now;
                  break;
                case 'month':
                  startDate = DateTime(now.year, now.month, 1);
                  endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
                  break;
                case 'year':
                  startDate = DateTime(now.year, 1, 1);
                  endDate = DateTime(now.year, 12, 31, 23, 59, 59);
                  break;
                case 'custom':
                  startDate =
                      _customStartDate ?? DateTime(now.year, now.month, 1);
                  endDate = _customEndDate ?? now;
                  break;
                default:
                  startDate = DateTime(now.year, now.month, 1);
                  endDate = now;
              }

              final transactions = transactionProvider.getTransactionsByPeriod(
                startDate,
                endDate,
              );
              final totalIncome = transactionProvider.getTotalIncome(
                start: startDate,
                end: endDate,
              );
              final totalExpense = transactionProvider.getTotalExpense(
                start: startDate,
                end: endDate,
              );
              final balance = totalIncome - totalExpense;

              return Column(
                children: [
                  // Sélecteur de période
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: Row(
                      children: [
                        Expanded(child: _buildPeriodChip('Semaine', 'week')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildPeriodChip('Mois', 'month')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildPeriodChip('Année', 'year')),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPeriodChip('Personnalisé', 'custom'),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedPeriod == 'custom')
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      _customStartDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() {
                                    _customStartDate = date;
                                  });
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _customStartDate != null
                                    ? Formatters.formatDate(_customStartDate!)
                                    : 'Date début',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _customEndDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() {
                                    _customEndDate = date;
                                  });
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _customEndDate != null
                                    ? Formatters.formatDate(_customEndDate!)
                                    : 'Date fin',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Cartes de statistiques
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Cartes principales
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Revenus',
                                  Formatters.formatCurrency(totalIncome),
                                  Icons.arrow_downward,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Dépenses',
                                  Formatters.formatCurrency(totalExpense),
                                  Icons.arrow_upward,
                                  Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildStatCard(
                            'Solde',
                            Formatters.formatCurrency(balance),
                            balance >= 0
                                ? Icons.account_balance
                                : Icons.account_balance_wallet,
                            balance >= 0 ? AppTheme.primaryColor : Colors.red,
                          ),
                          const SizedBox(height: 24),
                          // Graphique des catégories
                          _buildCategoryChart(transactions, categoryProvider),
                          const SizedBox(height: 24),
                          // Transactions récentes
                          _buildRecentTransactions(
                            transactions,
                            categoryProvider,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(
    List transactions,
    CategoryProvider categoryProvider,
  ) {
    final categoryTotals = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.transactionType == 'expense') {
        final category = categoryProvider.getCategoryById(
          transaction.categoryId,
        );
        final categoryName = category?.name ?? 'Non catégorisé';
        categoryTotals[categoryName] =
            (categoryTotals[categoryName] ?? 0) + transaction.amount;
      }
    }

    if (categoryTotals.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.pie_chart, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'Aucune dépense pour cette période',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final totalExpense = categoryTotals.values.fold(
      0.0,
      (sum, amount) => sum + amount,
    );
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition par catégorie',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            ...sortedCategories.take(5).map((entry) {
              final percentage = (entry.value / totalExpense * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                Formatters.formatCurrency(entry.value),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(
    List transactions,
    CategoryProvider categoryProvider,
  ) {
    final recentTransactions = transactions.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transactions récentes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            if (recentTransactions.isEmpty)
              Center(
                child: Text(
                  'Aucune transaction récente',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              )
            else
              ...recentTransactions.map((transaction) {
                final category = categoryProvider.getCategoryById(
                  transaction.categoryId,
                );
                final isIncome = transaction.transactionType == 'income';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: _getCategoryColor(
                          category?.name ?? 'Autre',
                        ),
                        child: Icon(
                          _getCategoryIcon(category?.name ?? 'Autre'),
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              Formatters.formatDate(transaction.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isIncome ? '+' : '-'}${Formatters.formatCurrency(transaction.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String categoryName) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
    ];
    final index = categoryName.hashCode.abs() % colors.length;
    return colors[index];
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'alimentation':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'logement':
        return Icons.home;
      case 'santé':
        return Icons.local_hospital;
      case 'éducation':
        return Icons.school;
      case 'divertissement':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_cart;
      case 'salaire':
        return Icons.work;
      case 'investissement':
        return Icons.trending_up;
      default:
        return Icons.category;
    }
  }
}
