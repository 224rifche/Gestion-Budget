import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/formatters.dart';

/// Graphique linéaire montrant l'évolution des revenus/dépenses dans le temps
class ExpenseEvolutionChart extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final bool showIncome;
  final bool showExpense;

  const ExpenseEvolutionChart({
    super.key,
    this.startDate,
    this.endDate,
    this.showIncome = true,
    this.showExpense = true,
  });

  @override
  State<ExpenseEvolutionChart> createState() => _ExpenseEvolutionChartState();
}

class _ExpenseEvolutionChartState extends State<ExpenseEvolutionChart> {
  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        // Calculer les données pour les 12 derniers mois
        final data = _calculateMonthlyData(provider);

        if (data.isEmpty) {
          return _buildEmptyState(context);
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Évolution sur 12 mois',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Comparaison revenus vs dépenses',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: 24),

                // Graphique
                SizedBox(
                  height: 250,
                  child: LineChart(
                    _buildChartData(data),
                  ),
                ),

                const SizedBox(height: 16),

                // Légende
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.showIncome) ...[
                      _buildLegendItem('Revenus', Colors.green),
                      const SizedBox(width: 24),
                    ],
                    if (widget.showExpense) ...[
                      _buildLegendItem('Dépenses', Colors.red),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
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
              Icons.show_chart,
              size: 48,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Pas assez de données',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des transactions pour voir l\'évolution',
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

  Map<int, Map<String, double>> _calculateMonthlyData(TransactionProvider provider) {
    final Map<int, Map<String, double>> monthlyData = {};
    final now = DateTime.now();

    // Initialiser les 12 derniers mois
    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = month.month + (month.year * 100);
      monthlyData[key] = {'income': 0.0, 'expense': 0.0};
    }

    // Calculer les totaux par mois
    for (final transaction in provider.allTransactions) {
      final date = transaction.date;
      final key = date.month + (date.year * 100);

      if (monthlyData.containsKey(key)) {
        if (transaction.transactionType == 'income') {
          monthlyData[key]!['income'] = (monthlyData[key]!['income'] ?? 0) + transaction.amount.abs();
        } else {
          monthlyData[key]!['expense'] = (monthlyData[key]!['expense'] ?? 0) + transaction.amount.abs();
        }
      }
    }

    return monthlyData;
  }

  LineChartData _buildChartData(Map<int, Map<String, double>> data) {
    final sortedKeys = data.keys.toList()..sort();
    
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];

    for (int i = 0; i < sortedKeys.length; i++) {
      final monthData = data[sortedKeys[i]]!;
      incomeSpots.add(FlSpot(i.toDouble(), monthData['income'] ?? 0));
      expenseSpots.add(FlSpot(i.toDouble(), monthData['expense'] ?? 0));
    }

    // Trouver le maximum pour l'axe Y
    final maxIncome = incomeSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final maxExpense = expenseSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final maxY = (maxIncome > maxExpense ? maxIncome : maxExpense) * 1.2;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              return Text(
                Formatters.formatCompactCurrency(value),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= sortedKeys.length) return const Text('');
              
              final monthKey = sortedKeys[index];
              final month = monthKey % 100;
              
              // Afficher seulement certains mois pour éviter la surcharge
              if (index % 2 != 0) return const Text('');
              
              return Text(
                _getMonthLabel(month),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (sortedKeys.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        if (widget.showIncome)
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.green,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withValues(alpha: 0.1),
            ),
          ),
        if (widget.showExpense)
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.red,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withValues(alpha: 0.1),
            ),
          ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final isIncome = spot.barIndex == 0 && widget.showIncome;
              return LineTooltipItem(
                Formatters.formatCurrency(spot.y),
                TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: '\n${isIncome ? "Revenus" : "Dépenses"}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }

  String _getMonthLabel(int month) {
    const months = [
      '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return months[month];
  }
}
