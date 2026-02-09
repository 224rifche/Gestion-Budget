import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/theme.dart';

/// Graphique circulaire montrant la répartition des dépenses par catégorie
class CategoryPieChart extends StatelessWidget {
  final int? limit;

  const CategoryPieChart({super.key, this.limit});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        return Consumer<CategoryProvider>(
          builder: (context, categoryProvider, child) {
            final transactions = transactionProvider.transactions
                .where((t) => t.amount < 0) // Uniquement les dépenses
                .toList();

            if (transactions.isEmpty) {
              return _buildEmptyState(context);
            }

            // Calculer les totaux par catégorie
            final Map<int, double> categoryTotals = {};
            for (final transaction in transactions) {
              categoryTotals[transaction.categoryId] = 
                  (categoryTotals[transaction.categoryId] ?? 0) + transaction.amount.abs();
            }

            // Trier et limiter si nécessaire
            final sortedEntries = categoryTotals.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            
            final displayEntries = limit != null 
                ? sortedEntries.take(limit!).toList()
                : sortedEntries;

            if (displayEntries.isEmpty) {
              return _buildEmptyState(context);
            }

            final totalExpenses = displayEntries.fold(0.0, (sum, entry) => sum + entry.value);

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Répartition des dépenses',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Graphique
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 60,
                          sections: displayEntries.asMap().entries.map((entry) {
                            final categoryId = entry.value.key;
                            final amount = entry.value.value;
                            final percentage = (amount / totalExpenses * 100);
                            
                            final category = categoryProvider.getCategoryById(categoryId);
                            final color = CategoryColors.fromHex(category?.color ?? '#AAB7B8');
                            
                            return PieChartSectionData(
                              value: amount,
                              title: '${percentage.toStringAsFixed(1)}%',
                              radius: 50,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              color: color,
                              badgeWidget: _Badge(
                                category?.icon ?? '❓',
                                color,
                                size: 40,
                              ),
                              badgePositionPercentageOffset: .98,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Légende
                    ...displayEntries.map((entry) {
                      final category = categoryProvider.getCategoryById(entry.key);
                      final percentage = (entry.value / totalExpenses * 100);
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: CategoryColors.fromHex(category?.color ?? '#AAB7B8'),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category?.icon ?? '❓',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                category?.name ?? 'Inconnue',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
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
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.pie_chart,
              size: 48,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune dépense',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez par ajouter des dépenses pour voir la répartition',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge personnalisé pour les sections du graphique
class _Badge extends StatelessWidget {
  final String icon;
  final Color color;
  final double size;

  const _Badge(
    this.icon,
    this.color, {
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.15),
      child: Center(
        child: Text(
          icon,
          style: TextStyle(fontSize: size * 0.5),
        ),
      ),
    );
  }
}
