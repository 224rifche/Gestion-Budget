import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/transaction.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';
import '../transactions/add_transaction_screen.dart';

/// Écran listant toutes les transactions
class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  String _selectedFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionModel> _getFilteredTransactions(
    TransactionProvider provider,
  ) {
    List<TransactionModel> transactions = provider.transactions;

    // Filtrer par type
    if (_selectedFilter != 'all') {
      transactions = transactions
          .where((t) => t.transactionType == _selectedFilter)
          .toList();
    }

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      transactions = transactions
          .where(
            (t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    // Filtrer par date
    if (_startDate != null) {
      transactions = transactions
          .where((t) => t.date.isAfter(_startDate!))
          .toList();
    }
    if (_endDate != null) {
      transactions = transactions
          .where((t) => t.date.isBefore(_endDate!))
          .toList();
    }

    // Trier par date (plus récent en premier)
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return transactions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.list),
                    SizedBox(width: 8),
                    Text('Toutes'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'income',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Revenus'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'expense',
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Dépenses'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer2<TransactionProvider, CategoryProvider>(
        builder: (context, transactionProvider, categoryProvider, child) {
          final filteredTransactions = _getFilteredTransactions(
            transactionProvider,
          );

          return Column(
            children: [
              // Barre de recherche et filtres
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Column(
                  children: [
                    // Barre de recherche
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher une transaction...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Filtres de date
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  _startDate = date;
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _startDate != null
                                  ? Formatters.formatDate(_startDate!)
                                  : 'Date début',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  _endDate = date;
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _endDate != null
                                  ? Formatters.formatDate(_endDate!)
                                  : 'Date fin',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                            ),
                          ),
                        ),
                        if (_startDate != null || _endDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _startDate = null;
                                _endDate = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Liste des transactions
              Expanded(
                child: filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = filteredTransactions[index];
                          final category = categoryProvider.getCategoryById(
                            transaction.categoryId,
                          );

                          return _buildTransactionCard(transaction, category);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'transactions_list_fab',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
              fullscreenDialog: true,
            ),
          );
          if (result == true && context.mounted) {
            context.read<TransactionProvider>().loadTransactions();
          }
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune transaction trouvée',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos filtres ou ajoutez une nouvelle transaction',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction, category) {
    final isIncome = transaction.transactionType == 'income';
    final amount = transaction.amount;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category?.color ?? Colors.grey,
          child: Icon(
            _getCategoryIcon(category?.name ?? 'Autre'),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${Formatters.formatDate(transaction.date)} • ${category?.name ?? 'Non catégorisé'}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncome ? '+' : '-'}${Formatters.formatCurrency(amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            if (transaction.paymentMethod != null)
              Text(
                _getPaymentMethodLabel(transaction.paymentMethod),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
          ],
        ),
        onTap: () async {
          final navigator = Navigator.of(context);
          final result = await navigator.push(
            MaterialPageRoute(
              builder: (context) =>
                  AddTransactionScreen(transaction: transaction),
              fullscreenDialog: true,
            ),
          );
          if (result == true && mounted) {
            context.read<TransactionProvider>().loadTransactions();
          }
        },
      ),
    );
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

  String _getPaymentMethodLabel(String? method) {
    if (method == null) return '';
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Espèces';
      case 'card':
        return 'Carte';
      case 'transfer':
        return 'Virement';
      case 'mobile':
        return 'Mobile';
      default:
        return method;
    }
  }
}
