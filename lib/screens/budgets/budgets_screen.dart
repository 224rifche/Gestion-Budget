import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/budget.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import 'add_budget_screen.dart';
import 'edit_budget_screen.dart';

/// Écran complet de gestion des budgets
class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Budgets'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Actifs', icon: Icon(Icons.check_circle, size: 20)),
            Tab(text: 'Dépassés', icon: Icon(Icons.warning, size: 20)),
            Tab(text: 'Tous', icon: Icon(Icons.list, size: 20)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('Toutes les périodes'),
              ),
              const PopupMenuItem(value: 'daily', child: Text('Quotidien')),
              const PopupMenuItem(value: 'weekly', child: Text('Hebdomadaire')),
              const PopupMenuItem(value: 'monthly', child: Text('Mensuel')),
              const PopupMenuItem(value: 'yearly', child: Text('Annuel')),
            ],
          ),
        ],
      ),
      body: Consumer2<BudgetProvider, CategoryProvider>(
        builder: (context, budgetProvider, categoryProvider, child) {
          if (budgetProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => budgetProvider.loadBudgets(),
            child: Column(
              children: [
                // Statistiques globales
                _buildGlobalStats(budgetProvider),

                // Liste des budgets par onglet
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBudgetsList(
                        context,
                        budgetProvider,
                        categoryProvider,
                        budgetProvider.activeBudgets,
                      ),
                      _buildBudgetsList(
                        context,
                        budgetProvider,
                        categoryProvider,
                        budgetProvider.exceededBudgets,
                      ),
                      _buildBudgetsList(
                        context,
                        budgetProvider,
                        categoryProvider,
                        budgetProvider.budgets,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'budgets_fab',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddBudgetScreen(),
              fullscreenDialog: true,
            ),
          );
          if (result == true && context.mounted) {
            context.read<BudgetProvider>().loadBudgets();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Créer un budget'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildGlobalStats(BudgetProvider budgetProvider) {
    final stats = budgetProvider.getBudgetStats();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Budgets Actifs',
                  '${stats['budgetsCount']}',
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Dépassés',
                  '${stats['exceededCount']}',
                  Icons.warning,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Budget Total',
                  Formatters.formatCompactCurrency(stats['totalLimit']),
                  Icons.euro,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Dépensé',
                  Formatters.formatCompactCurrency(stats['totalSpent']),
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barre de progression globale
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Utilisation Moyenne',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${stats['averageUsage'].toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getColorForPercentage(stats['averageUsage']),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (stats['averageUsage'] / 100).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getColorForPercentage(stats['averageUsage']),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetsList(
    BuildContext context,
    BudgetProvider budgetProvider,
    CategoryProvider categoryProvider,
    List<BudgetModel> budgets,
  ) {
    // Filtrer par période si nécessaire
    final filteredBudgets = _selectedPeriod == 'all'
        ? budgets
        : budgets.where((b) => b.periodType == _selectedPeriod).toList();

    if (filteredBudgets.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredBudgets.length,
      itemBuilder: (context, index) {
        final budget = filteredBudgets[index];
        final category = categoryProvider.getCategoryById(budget.categoryId);

        return _buildBudgetCard(
          context,
          budget,
          category?.name ?? 'Inconnu',
          category?.icon ?? '❓',
          category?.color ?? '#AAB7B8',
          budgetProvider,
        );
      },
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    BudgetModel budget,
    String categoryName,
    String icon,
    String colorHex,
    BudgetProvider budgetProvider,
  ) {
    final color = CategoryColors.fromHex(colorHex);
    final percentage = budget.percentageUsed;
    final isExceeded = budget.isExceeded;
    final isNearLimit = budget.isNearThreshold && !isExceeded;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditBudgetScreen(budget: budget),
            ),
          );
          if (result == true && context.mounted) {
            budgetProvider.loadBudgets();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: color.withValues(alpha: 0.2),
                    child: Text(icon, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getPeriodText(budget.periodType),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge de statut
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isExceeded
                          ? Colors.red.withValues(alpha: 0.1)
                          : isNearLimit
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isExceeded
                              ? Icons.error
                              : isNearLimit
                              ? Icons.warning_amber
                              : Icons.check_circle,
                          size: 16,
                          color: isExceeded
                              ? Colors.red
                              : isNearLimit
                              ? Colors.orange
                              : Colors.green,
                        ),
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
              const SizedBox(height: 16),

              // Montants
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dépensé',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        Formatters.formatCurrency(budget.currentSpent),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Limite',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        Formatters.formatCurrency(budget.amountLimit),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Restant',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        Formatters.formatCurrency(budget.remainingAmount),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isExceeded ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Barre de progression
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  minHeight: 12,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isExceeded
                        ? Colors.red
                        : isNearLimit
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
              ),

              // Message d'avertissement
              if (isExceeded || isNearLimit) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isExceeded ? Colors.red : Colors.orange).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (isExceeded ? Colors.red : Colors.orange)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isExceeded ? Icons.error : Icons.warning_amber,
                        size: 16,
                        color: isExceeded ? Colors.red : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isExceeded
                              ? 'Budget dépassé de ${Formatters.formatCurrency(budget.currentSpent - budget.amountLimit)}'
                              : 'Attention ! ${Formatters.formatCurrency(budget.remainingAmount)} restants',
                          style: TextStyle(
                            fontSize: 12,
                            color: isExceeded ? Colors.red : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Actions rapides
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      await budgetProvider.toggleBudgetActive(budget.id!);
                    },
                    icon: Icon(
                      budget.isActive ? Icons.pause : Icons.play_arrow,
                      size: 16,
                    ),
                    label: Text(budget.isActive ? 'Pause' : 'Activer'),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        _confirmDelete(context, budget, budgetProvider),
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    label: const Text(
                      'Supprimer',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 80,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Aucun budget',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Créez votre premier budget pour\ncommencer à suivre vos dépenses',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddBudgetScreen(),
                      fullscreenDialog: true,
                    ),
                  );
                  if (result == true && context.mounted) {
                    context.read<BudgetProvider>().loadBudgets();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Créer un budget'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 100) return Colors.red;
    if (percentage >= 80) return Colors.orange;
    return Colors.green;
  }

  String _getPeriodText(String period) {
    switch (period) {
      case 'daily':
        return 'Quotidien';
      case 'weekly':
        return 'Hebdomadaire';
      case 'monthly':
        return 'Mensuel';
      case 'yearly':
        return 'Annuel';
      default:
        return period;
    }
  }

  void _confirmDelete(
    BuildContext context,
    BudgetModel budget,
    BudgetProvider budgetProvider,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce budget ?'),
        content: const Text(
          'Cette action est irréversible. Toutes les données de ce budget seront perdues.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await budgetProvider.deleteBudget(budget.id!);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Budget supprimé avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
