import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../utils/formatters.dart';
import '../screens/transactions/edit_transaction_screen.dart';

/// Liste des transactions récentes avec limite configurable
class RecentTransactionsList extends StatefulWidget {
  final int? limit;
  final bool showEmptyState;

  const RecentTransactionsList({
    super.key,
    this.limit,
    this.showEmptyState = true,
  });

  @override
  State<RecentTransactionsList> createState() => _RecentTransactionsListState();
}

class _RecentTransactionsListState extends State<RecentTransactionsList> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, CategoryProvider>(
      builder: (context, transactionProvider, categoryProvider, child) {
        var transactions = transactionProvider.transactions;

        // Limiter le nombre si spécifié
        if (widget.limit != null && transactions.length > widget.limit!) {
          transactions = transactions.take(widget.limit!).toList();
        }

        // État vide
        if (transactions.isEmpty && widget.showEmptyState) {
          return _buildEmptyState(context);
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: transactions.map((transaction) {
              final category = categoryProvider.getCategoryById(
                transaction.categoryId,
              );

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: transaction.amount > 0
                      ? Colors.green.withAlpha(10)
                      : Colors.red.withAlpha(10),
                  child: Icon(
                    transaction.amount > 0
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: transaction.amount > 0 ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ),
                title: Text(
                  transaction.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatDate(transaction.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.withAlpha(170),
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${transaction.amount > 0 ? '+' : ''}${Formatters.formatCurrency(transaction.amount)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: transaction.amount > 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
                onTap: () =>
                    _showTransactionDetails(context, transaction, category),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// État vide
  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune transaction',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez par ajouter votre première transaction',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.withAlpha(170),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Afficher les détails d'une transaction
  void _showTransactionDetails(BuildContext context, transaction, category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(76),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Icône et catégorie
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: category != null
                          ? _colorFromString(category.color).withAlpha(10)
                          : Colors.grey.withAlpha(10),
                      child: Text(
                        category?.icon ?? '❓',
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            category?.name ?? 'Catégorie inconnue',
                            style: TextStyle(
                              color: Colors.grey.withAlpha(170),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Montant
                _buildDetailRow(
                  context,
                  'Montant',
                  Formatters.formatCurrency(transaction.amount),
                  color: transaction.amount > 0 ? Colors.green : Colors.red,
                ),
                const Divider(height: 24),

                // Date
                _buildDetailRow(
                  context,
                  'Date',
                  Formatters.formatDate(transaction.date),
                ),
                const Divider(height: 24),

                // Type
                _buildDetailRow(
                  context,
                  'Type',
                  transaction.transactionType == 'income'
                      ? 'Revenu'
                      : 'Dépense',
                ),

                // Description
                if (transaction.description != null) ...[
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    'Description',
                    transaction.description!,
                  ),
                ],

                const SizedBox(height: 32),

                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          final transactionProvider =
                              Provider.of<TransactionProvider>(
                                context,
                                listen: false,
                              );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditTransactionScreen(
                                transaction: transaction,
                              ),
                            ),
                          ).then((result) {
                            if (result == true && mounted) {
                              // Refresh the data if modification was successful
                              transactionProvider.loadTransactions();
                            }
                          });
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Modifier'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDelete(context, transaction.id!);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Supprimer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construire une ligne de détail
  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.withAlpha(170), fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Convertir une couleur string en Color
  Color _colorFromString(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'yellow':
        return Colors.yellow;
      case 'cyan':
        return Colors.cyan;
      case 'teal':
        return Colors.teal;
      case 'indigo':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  /// Confirmer la suppression
  void _confirmDelete(BuildContext context, int transactionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette transaction ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Capturer les contextes avant l'opération asynchrone
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              final provider = Provider.of<TransactionProvider>(
                context,
                listen: false,
              );
              final success = await provider.deleteTransaction(transactionId);

              if (mounted) {
                navigator.pop();

                if (success) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Transaction supprimée'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Erreur lors de la suppression'),
                      backgroundColor: Colors.red,
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
