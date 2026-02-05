import 'package:flutter/foundation.dart';
import '../models/category.dart';
import '../database/database_helper.dart';

class CategoryProvider with ChangeNotifier {
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Obtenir les catégories de dépenses
  List<CategoryModel> get expenseCategories {
    return _categories
        .where((c) => c.categoryType == 'expense' && c.isActive)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Obtenir les catégories de revenus
  List<CategoryModel> get incomeCategories {
    return _categories
        .where((c) => c.categoryType == 'income' && c.isActive)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Initialiser et charger les catégories
  Future<void> initialize() async {
    await loadCategories();
  }

  /// Charger toutes les catégories
  Future<void> loadCategories() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'categories',
        orderBy: 'sort_order ASC',
      );

      _categories = maps.map((map) => CategoryModel.fromMap(map)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtenir une catégorie par ID
  CategoryModel? getCategoryById(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtenir une catégorie par nom
  CategoryModel? getCategoryByName(String name) {
    try {
      return _categories.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Ajouter une catégorie personnalisée
  Future<bool> addCategory(CategoryModel category) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final id = await db.insert('categories', category.toMap());

      final newCategory = category.copyWith(id: id);
      _categories.add(newCategory);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'ajout: $e';
      notifyListeners();
      return false;
    }
  }

  /// Mettre à jour une catégorie
  Future<bool> updateCategory(CategoryModel category) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'categories',
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );

      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour: $e';
      notifyListeners();
      return false;
    }
  }

  /// Désactiver une catégorie (soft delete)
  Future<bool> deactivateCategory(int id) async {
    try {
      final category = getCategoryById(id);
      if (category == null) return false;

      // Ne pas supprimer les catégories par défaut
      if (category.isDefault) {
        _errorMessage = 'Impossible de supprimer une catégorie par défaut';
        notifyListeners();
        return false;
      }

      return await updateCategory(category.copyWith(isActive: false));
    } catch (e) {
      _errorMessage = 'Erreur lors de la désactivation: $e';
      notifyListeners();
      return false;
    }
  }

  /// Réactiver une catégorie
  Future<bool> activateCategory(int id) async {
    try {
      final category = getCategoryById(id);
      if (category == null) return false;

      return await updateCategory(category.copyWith(isActive: true));
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'activation: $e';
      notifyListeners();
      return false;
    }
  }
}
