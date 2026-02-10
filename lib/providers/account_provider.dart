import 'package:flutter/foundation.dart';
import '../models/account.dart';
import '../database/database_helper.dart';
import '../database/db_constants.dart';

/// Provider pour la gestion des comptes bancaires
class AccountProvider with ChangeNotifier {
  List<AccountModel> _accounts = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<AccountModel> get accounts => _accounts;
  List<AccountModel> get activeAccounts => _accounts.where((account) => account.isActive).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get totalBalance => activeAccounts.fold(0.0, (sum, account) => sum + account.currentBalance);

  /// Initialiser et charger les comptes
  Future<void> initialize() async {
    await loadAccounts();
  }

  /// Charger tous les comptes
  Future<void> loadAccounts() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DbConstants.tableAccounts,
        orderBy: '${DbConstants.columnCreatedAt} DESC',
      );

      _accounts = maps.map((map) => AccountModel.fromMap(map)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ajouter un compte
  Future<bool> addAccount(AccountModel account) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final id = await db.insert(DbConstants.tableAccounts, account.toMap());

      final newAccount = account.copyWith(id: id);
      _accounts.add(newAccount);

      notifyListeners();
      debugPrint('✅ Compte ajouté: ${newAccount.name}');
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'ajout: $e';
      notifyListeners();
      debugPrint('❌ Erreur addAccount: $e');
      return false;
    }
  }

  /// Mettre à jour un compte
  Future<bool> updateAccount(AccountModel account) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final updatedAccount = account.copyWith(updatedAt: DateTime.now());

      await db.update(
        DbConstants.tableAccounts,
        updatedAccount.toMap(),
        where: '${DbConstants.columnId} = ?',
        whereArgs: [account.id],
      );

      final index = _accounts.indexWhere((a) => a.id == account.id);
      if (index != -1) {
        _accounts[index] = updatedAccount;
      }

      notifyListeners();
      debugPrint('✅ Compte mis à jour: ${updatedAccount.name}');
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour: $e';
      notifyListeners();
      debugPrint('❌ Erreur updateAccount: $e');
      return false;
    }
  }

  /// Supprimer un compte
  Future<bool> deleteAccount(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        DbConstants.tableAccounts,
        where: '${DbConstants.columnId} = ?',
        whereArgs: [id],
      );

      _accounts.removeWhere((account) => account.id == id);

      notifyListeners();
      debugPrint('✅ Compte supprimé: ID $id');
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression: $e';
      notifyListeners();
      debugPrint('❌ Erreur deleteAccount: $e');
      return false;
    }
  }

  /// Activer/Désactiver un compte
  Future<bool> toggleAccountActive(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final accountIndex = _accounts.indexWhere((account) => account.id == id);
      if (accountIndex == -1) return false;

      final account = _accounts[accountIndex];
      final updatedAccount = account.copyWith(
        isActive: !account.isActive,
        updatedAt: DateTime.now(),
      );

      await db.update(
        DbConstants.tableAccounts,
        {
          DbConstants.columnIsActive: updatedAccount.isActive ? 1 : 0,
          DbConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '${DbConstants.columnId} = ?',
        whereArgs: [id],
      );

      _accounts[accountIndex] = updatedAccount;
      notifyListeners();

      debugPrint('✅ Compte ${updatedAccount.isActive ? 'activé' : 'désactivé'}: ${updatedAccount.name}');
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la modification: $e';
      notifyListeners();
      debugPrint('❌ Erreur toggleAccountActive: $e');
      return false;
    }
  }

  /// Obtenir un compte par ID
  AccountModel? getAccountById(int id) {
    try {
      return _accounts.firstWhere((account) => account.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtenir les comptes par type
  List<AccountModel> getAccountsByType(String accountType) {
    return _accounts.where((account) => account.accountType == accountType).toList();
  }

  /// Mettre à jour le solde d'un compte
  Future<bool> updateBalance(int accountId, double newBalance) async {
    try {
      final db = await DatabaseHelper.instance.database;

      await db.update(
        DbConstants.tableAccounts,
        {
          DbConstants.columnCurrentBalance: newBalance,
          DbConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '${DbConstants.columnId} = ?',
        whereArgs: [accountId],
      );

      final index = _accounts.indexWhere((account) => account.id == accountId);
      if (index != -1) {
        _accounts[index] = _accounts[index].copyWith(
          currentBalance: newBalance,
          updatedAt: DateTime.now(),
        );
      }

      notifyListeners();
      debugPrint('✅ Solde mis à jour: $newBalance€ pour le compte ID $accountId');
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour du solde: $e';
      notifyListeners();
      debugPrint('❌ Erreur updateBalance: $e');
      return false;
    }
  }

  /// Réinitialiser les erreurs
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
