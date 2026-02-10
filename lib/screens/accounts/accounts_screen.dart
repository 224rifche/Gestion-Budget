import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/account_provider.dart';
import '../../models/account.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';

/// Écran de gestion des comptes bancaires
class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Comptes'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AccountProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final accounts = provider.activeAccounts;

          return RefreshIndicator(
            onRefresh: () => provider.loadAccounts(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte du solde total
                  _buildTotalBalanceCard(context, provider),
                  const SizedBox(height: 24),

                  // Liste des comptes
                  Text(
                    'Vos comptes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (accounts.isEmpty)
                    _buildEmptyState(context)
                  else
                    ...accounts.map(
                      (account) =>
                          _buildAccountCard(context, account, provider),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'accounts_fab',
        onPressed: () => _showAddAccountDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTotalBalanceCard(
    BuildContext context,
    AccountProvider provider,
  ) {
    final totalBalance = provider.totalBalance;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solde Total',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.formatCurrency(totalBalance),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${provider.activeAccounts.length} compte(s) actif(s)',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    AccountModel account,
    AccountProvider provider,
  ) {
    final color = _colorFromHex(account.color ?? account.defaultColor);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Text(
            account.icon ?? account.defaultIcon,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Text(
          account.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatAccountType(account.accountType)),
            Text(
              Formatters.formatCurrency(account.currentBalance),
              style: TextStyle(
                color: account.currentBalance >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditAccountDialog(context, account);
                break;
              case 'toggle':
                provider.toggleAccountActive(account.id!);
                break;
              case 'delete':
                _confirmDelete(context, account, provider);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Modifier')),
            const PopupMenuItem(
              value: 'toggle',
              child: Text('Activer/Désactiver'),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.account_balance,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun compte',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez votre premier compte bancaire',
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

  String _formatAccountType(String type) {
    switch (type) {
      case 'cash':
        return 'Espèces';
      case 'bank':
        return 'Compte bancaire';
      case 'credit_card':
        return 'Carte de crédit';
      case 'savings':
        return 'Compte épargne';
      case 'investment':
        return 'Investissement';
      default:
        return type;
    }
  }

  Color _colorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor));
  }

  void _showAddAccountDialog(BuildContext context) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0');
    String selectedType = 'bank';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nouveau compte'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du compte',
                  hintText: 'Ex: Compte Courant',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(
                    value: 'bank',
                    child: Text('Compte bancaire'),
                  ),
                  DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                  DropdownMenuItem(value: 'savings', child: Text('Épargne')),
                  DropdownMenuItem(
                    value: 'credit_card',
                    child: Text('Carte de crédit'),
                  ),
                  DropdownMenuItem(
                    value: 'investment',
                    child: Text('Investissement'),
                  ),
                ],
                onChanged: (value) => selectedType = value!,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: balanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Solde initial',
                  suffixText: '€',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez entrer un nom')),
                );
                return;
              }

              final balance = double.tryParse(balanceController.text) ?? 0;

              final account = AccountModel(
                name: nameController.text,
                accountType: selectedType,
                initialBalance: balance,
                currentBalance: balance,
              );

              final provider = Provider.of<AccountProvider>(
                context,
                listen: false,
              );
              final success = await provider.addAccount(account);

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Compte créé avec succès!')),
                  );
                }
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showEditAccountDialog(BuildContext context, AccountModel account) {
    final nameController = TextEditingController(text: account.name);
    final balanceController = TextEditingController(
      text: account.currentBalance.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modifier le compte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nom du compte'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Solde actuel',
                suffixText: '€',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final balance =
                  double.tryParse(balanceController.text) ??
                  account.currentBalance;

              final updatedAccount = account.copyWith(
                name: nameController.text,
                currentBalance: balance,
              );

              final provider = Provider.of<AccountProvider>(
                context,
                listen: false,
              );
              await provider.updateAccount(updatedAccount);

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AccountModel account,
    AccountProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: Text('Voulez-vous vraiment supprimer "${account.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await provider.deleteAccount(account.id!);

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);

                if (!success && provider.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(provider.errorMessage!)),
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
