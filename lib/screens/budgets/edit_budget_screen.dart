import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/budget.dart';
import '../../utils/theme.dart';
import '../../utils/formatters.dart';

/// Écran d'édition de budget
class EditBudgetScreen extends StatefulWidget {
  final BudgetModel budget;

  const EditBudgetScreen({super.key, required this.budget});

  @override
  State<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends State<EditBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late bool _notificationsEnabled;
  late double _notificationThreshold;
  late String _selectedPeriod;
  bool _isLoading = false;

  final List<Map<String, String>> _periods = [
    {'value': 'daily', 'label': 'Quotidien'},
    {'value': 'weekly', 'label': 'Hebdomadaire'},
    {'value': 'monthly', 'label': 'Mensuel'},
    {'value': 'yearly', 'label': 'Annuel'},
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.budget.amountLimit.toString(),
    );
    _notificationsEnabled = widget.budget.notificationsEnabled;
    _notificationThreshold = widget.budget.notificationThreshold;
    _selectedPeriod = widget.budget.periodType;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le budget'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveBudget,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Catégorie (non modifiable)
              Consumer<CategoryProvider>(
                builder: (context, categoryProvider, child) {
                  final category = categoryProvider.getCategoryById(
                    widget.budget.categoryId,
                  );

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withValues(
                          alpha: 0.2,
                        ),
                        child: Text(
                          category?.icon ?? '❓',
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      title: Text(
                        category?.name ?? 'Catégorie inconnue',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Catégorie'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Montant limite
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Montant limite',
                  hintText: 'Ex: 500',
                  prefixIcon: const Icon(Icons.money),
                  suffixText: 'GNF',
                  border: const OutlineInputBorder(),
                  helperText:
                      'Actuellement dépensé: ${Formatters.formatCurrency(widget.budget.currentSpent)}',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Le montant doit être positif';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Période
              DropdownButtonFormField<String>(
                initialValue: _selectedPeriod,
                decoration: const InputDecoration(
                  labelText: 'Période',
                  hintText: 'Sélectionner une période',
                  prefixIcon: Icon(Icons.date_range),
                  border: OutlineInputBorder(),
                ),
                items: _periods.map((period) {
                  return DropdownMenuItem<String>(
                    value: period['value'],
                    child: Text(period['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Statistiques du budget
              Card(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 Statistiques',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow(
                        'Dépensé',
                        Formatters.formatCurrency(widget.budget.currentSpent),
                      ),
                      const Divider(height: 16),
                      _buildStatRow(
                        'Limite actuelle',
                        Formatters.formatCurrency(widget.budget.amountLimit),
                      ),
                      const Divider(height: 16),
                      _buildStatRow(
                        'Restant',
                        Formatters.formatCurrency(
                          widget.budget.remainingAmount,
                        ),
                        valueColor: widget.budget.isExceeded
                            ? Colors.red
                            : Colors.green,
                      ),
                      const Divider(height: 16),
                      _buildStatRow(
                        'Utilisation',
                        Formatters.formatPercentage(
                          widget.budget.percentageUsed,
                        ),
                        valueColor: widget.budget.isExceeded
                            ? Colors.red
                            : widget.budget.isNearThreshold
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Notifications
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications),
                          const SizedBox(width: 8),
                          Text(
                            'Notifications',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Switch(
                            value: _notificationsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _notificationsEnabled = value;
                              });
                            },
                            activeThumbColor: AppTheme.primaryColor,
                            activeTrackColor: AppTheme.primaryColor.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_notificationsEnabled) ...[
                        Text(
                          'Seuil d\'alerte',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _notificationThreshold,
                          min: 50,
                          max: 100,
                          divisions: 10,
                          label: '${_notificationThreshold.round()}%',
                          onChanged: (value) {
                            setState(() {
                              _notificationThreshold = value;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                        Text(
                          'Vous serez alerté lorsque vous atteindrez ${_notificationThreshold.round()}% du budget',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.grey.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveBudget,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Sauvegarder',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);

      final updatedBudget = widget.budget.copyWith(
        amountLimit: amount,
        periodType: _selectedPeriod,
        notificationsEnabled: _notificationsEnabled,
        notificationThreshold: _notificationThreshold,
        updatedAt: DateTime.now(),
      );

      final provider = context.read<BudgetProvider>();
      final success = await provider.updateBudget(updatedBudget);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Budget modifié avec succès!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la modification du budget'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
