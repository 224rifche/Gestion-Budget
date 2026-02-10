import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/savings_goal_provider.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import 'settings/settings_screen.dart';

// ✅ IMPORTS MANQUANTS - CRITIQUES !
import '../widgets/balance_card.dart';
import '../widgets/recent_transactions_list.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/quick_stats_card.dart';
import '../widgets/notification_test_widget.dart';
import '../screens/transactions/add_transaction_screen.dart';
import '../screens/statistics/statistics_screen.dart';
import '../screens/budgets/budgets_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialiser les providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TransactionProvider>().initialize();
        context.read<CategoryProvider>().initialize();
        context.read<BudgetProvider>().initialize();
        context.read<SavingsGoalProvider>().initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BudgetBuddy'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Paramètres (à implémenter)')),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeView(),
          _buildTransactionsView(),
          _buildStatisticsView(),
          _buildBudgetsView(),
          _buildSettingsView(),
        ],
      ),
      // ✅ CORRECTION #1 : Navigation vers AddTransactionScreen
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: () async {
          // ✅ FIX: Capturer le contexte AVANT l'opération asynchrone
          final navigator = Navigator.of(context);
          final transactionProvider = context.read<TransactionProvider>();
          final budgetProvider = context.read<BudgetProvider>();

          final result = await navigator.push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const AddTransactionScreen(),
              fullscreenDialog: true,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(begin: const Offset(0.0, 1.0), end: Offset.zero),
                      ),
                      child: child,
                    );
                  },
            ),
          );

          // ✅ FIX: Vérifier mounted avant d'utiliser les providers
          if (result == true && mounted) {
            transactionProvider.loadTransactions();
            budgetProvider.loadBudgets();
          }
        },
        backgroundColor: AppTheme.accentColor,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistiques',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budgets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }

  // ✅ CORRECTION #2 : Utiliser les VRAIS widgets
  Widget _buildHomeView() {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        if (transactionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (!mounted) return;
            await Future.wait([
              transactionProvider.loadTransactions(),
              context.read<BudgetProvider>().loadBudgets(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Utiliser BalanceCard existant
                const BalanceCard(),
                const SizedBox(height: 24),

                // ✅ Utiliser QuickStatsCard existant
                const QuickStatsCard(),
                const SizedBox(height: 24),

                // En-tête avec bouton "Voir tout"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transactions récentes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _currentIndex = 1);
                      },
                      child: const Text('Voir tout'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ✅ Utiliser RecentTransactionsList existant
                const RecentTransactionsList(limit: 5, showEmptyState: true),
                const SizedBox(height: 24),

                // En-tête budgets
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Budgets en cours',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _currentIndex = 3);
                      },
                      child: const Text('Gérer'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ✅ Utiliser BudgetProgressCard existant
                const BudgetProgressCard(maxBudgets: 3),
                const SizedBox(height: 24),

                // Widget de test pour les notifications (à enlever en production)
                const NotificationTestWidget(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ CORRECTION #3 : Afficher la liste complète des transactions
  Widget _buildTransactionsView() {
    return Consumer2<TransactionProvider, CategoryProvider>(
      builder: (context, transactionProvider, categoryProvider, child) {
        if (transactionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = transactionProvider.transactions;

        return Column(
          children: [
            // Barre de filtres
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.withValues(
                alpha: 0.1,
              ), // ✅ FIX: withValues au lieu de withOpacity
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: transactionProvider
                          .selectedType, // ✅ FIX: initialValue au lieu de value
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Tous')),
                        DropdownMenuItem(
                          value: 'income',
                          child: Text('Revenus'),
                        ),
                        DropdownMenuItem(
                          value: 'expense',
                          child: Text('Dépenses'),
                        ),
                      ],
                      onChanged: (value) {
                        transactionProvider.filterByType(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      // Ouvrir dialogue de filtres avancés
                      _showFilterDialog(context);
                    },
                  ),
                ],
              ),
            ),

            // Liste des transactions
            Expanded(
              child: transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.grey.withValues(
                              alpha: 0.5,
                            ), // ✅ FIX: withValues
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune transaction',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => const AddTransactionScreen(),
                                  transitionsBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        child,
                                      ) {
                                        return SlideTransition(
                                          position: animation.drive(
                                            Tween(
                                              begin: const Offset(0.0, 1.0),
                                              end: Offset.zero,
                                            ),
                                          ),
                                          child: child,
                                        );
                                      },
                                ),
                              );
                              // ✅ FIX: Vérifier mounted
                              if (result == true && mounted) {
                                if (!mounted) return;
                                transactionProvider.loadTransactions();
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter une transaction'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => transactionProvider.loadTransactions(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          final category = categoryProvider.getCategoryById(
                            transaction.categoryId,
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: category != null
                                    ? _colorFromHex(category.color).withValues(
                                        alpha: 0.2,
                                      ) // ✅ FIX: withValues
                                    : Colors.grey.withValues(
                                        alpha: 0.2,
                                      ), // ✅ FIX: withValues
                                child: Text(
                                  category?.icon ?? '📝',
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                              title: Text(
                                transaction.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(category?.name ?? 'Sans catégorie'),
                                  Text(
                                    Formatters.formatDate(transaction.date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.withValues(
                                        alpha: 0.7,
                                      ), // ✅ FIX: withValues
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                '${transaction.transactionType == 'income' ? '+' : '-'}${Formatters.formatCurrency(transaction.amount)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: transaction.transactionType == 'income'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              onTap: () {
                                // Afficher détails (déjà implémenté dans RecentTransactionsList)
                              },
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  // ✅ CORRECTION #4 : Afficher l'écran des statistiques (même si basique)
  Widget _buildStatisticsView() {
    return const StatisticsScreen();
  }

  // ✅ CORRECTION #5 : Afficher l'écran des budgets
  Widget _buildBudgetsView() {
    return const BudgetsScreen();
  }

  // Helper pour convertir couleur hex
  Color _colorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  // Dialogue de filtres
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        // ✅ FIX: Utiliser un nouveau context
        title: const Text('Filtrer les transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Fonctionnalités de filtre avancé à venir'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // ✅ FIX: Utiliser le context parent capturé avant l'async
                if (mounted) {
                  context.read<TransactionProvider>().resetFilters();
                  Navigator.pop(dialogContext); // ✅ FIX: Utiliser dialogContext
                }
              },
              child: const Text('Réinitialiser les filtres'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext), // ✅ FIX: Utiliser dialogContext
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsView() {
    return const SettingsScreen();
  }
}
