import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/transaction.dart';

/// Écran d'ajout/modification de transaction - VERSION COMPLÈTE
class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'expense'; // Par défaut: dépense
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  String _selectedPaymentMethod = 'Carte bancaire';
  bool _isLoading = false;
  bool _isEditing = false;

  final List<String> _paymentMethods = [
    'Carte bancaire',
    'Espèces',
    'Chèque',
    'Virement',
    'PayPal',
    'Apple Pay',
    'Google Pay',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.transaction != null;
    if (_isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final transaction = widget.transaction!;
    _titleController.text = transaction.title;
    _amountController.text = transaction.amount.toString();
    _descriptionController.text = transaction.description ?? '';
    _selectedDate = transaction.date;
    _selectedPaymentMethod = transaction.paymentMethod ?? 'Carte bancaire';
    _selectedCategoryId = transaction.categoryId;
    _selectedType = transaction.transactionType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Modifier la transaction' : 'Nouvelle transaction',
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveTransaction,
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
              // ✅ Sélecteur Type (Dépense/Revenu)
              _buildTypeSelector(),
              const SizedBox(height: 16),

              // Titre
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  hintText: 'Ex: Courses alimentaires',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer un titre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Montant
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Montant',
                  hintText: 'Ex: 50.00',
                  prefixIcon: Icon(Icons.euro),
                  suffixText: '€',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  final amount = double.tryParse(value.replaceAll(',', '.'));
                  if (amount == null || amount <= 0) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Catégorie
              Consumer<CategoryProvider>(
                builder: (context, categoryProvider, child) {
                  final categories = _selectedType == 'income'
                      ? categoryProvider.incomeCategories
                      : categoryProvider.expenseCategories;

                  // Si changement de type, réinitialiser la catégorie
                  if (_selectedCategoryId != null) {
                    final currentCat = categoryProvider.getCategoryById(
                      _selectedCategoryId!,
                    );
                    if (currentCat != null &&
                        currentCat.categoryType != _selectedType) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() => _selectedCategoryId = null);
                      });
                    }
                  }

                  return DropdownButtonFormField<int>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      hintText: 'Sélectionner une catégorie',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Row(
                          children: [
                            Text(
                              category.icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(category.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner une catégorie';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Date
              _buildDatePicker(),
              const SizedBox(height: 16),

              // Méthode de paiement
              DropdownButtonFormField<String>(
                initialValue: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Méthode de paiement',
                  hintText: 'Sélectionner une méthode',
                  prefixIcon: Icon(Icons.payment),
                  border: OutlineInputBorder(),
                ),
                items: _paymentMethods.map((method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPaymentMethod = value!);
                },
              ),
              const SizedBox(height: 16),

              // Description (optionnel)
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Note (optionnel)',
                  hintText: 'Ajoutez une note...',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              // Bouton de sauvegarde
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
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
                          'Enregistrer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Widget pour sélectionner Dépense/Revenu
  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              'Dépense',
              'expense',
              Icons.arrow_upward,
              Colors.red,
            ),
          ),
          Expanded(
            child: _buildTypeButton(
              'Revenu',
              'income',
              Icons.arrow_downward,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(
    String label,
    String type,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedCategoryId = null; // Reset catégorie quand on change de type
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      title: const Text('Date'),
      subtitle: Text(
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
      ),
      leading: const Icon(Icons.calendar_today),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      tileColor: Colors.grey.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: _selectDate,
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une catégorie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Parse amount (gérer virgule et point)
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));

      final provider = context.read<TransactionProvider>();
      bool success;

      if (_isEditing) {
        // ✅ MODIFIER la transaction existante
        final updatedTransaction = widget.transaction!.copyWith(
          title: _titleController.text.trim(),
          amount: amount,
          date: _selectedDate,
          categoryId: _selectedCategoryId!,
          transactionType: _selectedType,
          paymentMethod: _selectedPaymentMethod,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
        );
        success = await provider.updateTransaction(updatedTransaction);
      } else {
        // ✅ CRÉER une NOUVELLE transaction
        final transaction = TransactionModel(
          title: _titleController.text.trim(),
          amount: amount,
          date: _selectedDate,
          categoryId: _selectedCategoryId!,
          transactionType: _selectedType,
          paymentMethod: _selectedPaymentMethod,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
        );
        success = await provider.addTransaction(transaction);
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Transaction modifiée avec succès!'
                    : 'Transaction enregistrée avec succès!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Retourner true pour indiquer succès
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                provider.errorMessage ?? 'Erreur lors de l\'enregistrement',
              ),
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
        setState(() => _isLoading = false);
      }
    }
  }
}
