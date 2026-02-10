import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../database/database_helper.dart';
import '../database/db_constants.dart';
import 'notification_service.dart';

/// Service de gestion des transactions récurrentes
class RecurringTransactionService {
  static final RecurringTransactionService instance = RecurringTransactionService._init();

  RecurringTransactionService._init();

  /// Vérifier et créer les transactions récurrentes échues
  Future<List<TransactionModel>> processPendingRecurringTransactions() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now();

      // Récupérer toutes les transactions récurrentes actives
      final List<Map<String, dynamic>> maps = await db.query(
        DbConstants.tableTransactions,
        where: '${DbConstants.columnIsRecurring} = ? AND ${DbConstants.columnNextOccurrence} <= ?',
        whereArgs: [1, now.toIso8601String()],
      );

      final List<TransactionModel> createdTransactions = [];

      for (final map in maps) {
        final transaction = TransactionModel.fromMap(map);
        
        // Créer la nouvelle transaction
        final newTransaction = await _createNextOccurrence(transaction);
        if (newTransaction != null) {
          createdTransactions.add(newTransaction);
        }
      }

      debugPrint('✅ ${createdTransactions.length} transactions récurrentes créées');
      return createdTransactions;
    } catch (e) {
      debugPrint('❌ Erreur processPendingRecurringTransactions: $e');
      return [];
    }
  }

  /// Créer la prochaine occurrence d'une transaction récurrente
  Future<TransactionModel?> _createNextOccurrence(TransactionModel template) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Calculer la prochaine date selon le pattern
      final nextDate = _calculateNextOccurrence(
        template.nextOccurrence ?? DateTime.now(),
        template.recurringPattern ?? 'monthly',
      );

      // Créer la nouvelle transaction
      final newTransaction = template.copyWith(
        id: null, // Nouvelle transaction
        date: template.nextOccurrence ?? DateTime.now(),
        isRecurring: false, // La copie n'est pas récurrente
        recurringPattern: null,
        nextOccurrence: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await db.insert(
        DbConstants.tableTransactions,
        newTransaction.toMap(),
      );

      // Mettre à jour le template avec la prochaine occurrence
      await db.update(
        DbConstants.tableTransactions,
        {
          DbConstants.columnNextOccurrence: nextDate.toIso8601String(),
          DbConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '${DbConstants.columnId} = ?',
        whereArgs: [template.id],
      );

      // Programmer la prochaine notification
      await NotificationService.instance.scheduleRecurringTransaction(
        id: template.id!,
        title: template.title,
        amount: template.amount,
        nextOccurrence: nextDate,
      );

      debugPrint('✅ Transaction récurrente créée: ${template.title} - Prochaine: ${nextDate.toIso8601String()}');

      return newTransaction.copyWith(id: id);
    } catch (e) {
      debugPrint('❌ Erreur _createNextOccurrence: $e');
      return null;
    }
  }

  /// Calculer la prochaine occurrence selon le pattern
  DateTime _calculateNextOccurrence(DateTime current, String pattern) {
    switch (pattern.toLowerCase()) {
      case 'daily':
        return current.add(const Duration(days: 1));
        
      case 'weekly':
        return current.add(const Duration(days: 7));
        
      case 'biweekly':
        return current.add(const Duration(days: 14));
        
      case 'monthly':
        // Ajouter 1 mois en gérant les mois avec différents nombres de jours
        int nextMonth = current.month + 1;
        int nextYear = current.year;
        
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }
        
        // Gérer les jours invalides (ex: 31 janvier -> 28/29 février)
        int nextDay = current.day;
        final daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        if (nextDay > daysInNextMonth) {
          nextDay = daysInNextMonth;
        }
        
        return DateTime(nextYear, nextMonth, nextDay, current.hour, current.minute);
        
      case 'quarterly':
        return _calculateNextOccurrence(
          _calculateNextOccurrence(
            _calculateNextOccurrence(current, 'monthly'),
            'monthly',
          ),
          'monthly',
        );
        
      case 'yearly':
        return DateTime(
          current.year + 1,
          current.month,
          current.day,
          current.hour,
          current.minute,
        );
        
      default:
        return current.add(const Duration(days: 30));
    }
  }

  /// Créer une transaction récurrente
  Future<TransactionModel?> createRecurringTransaction({
    required TransactionModel transaction,
    required String recurringPattern,
    DateTime? startDate,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final firstOccurrence = startDate ?? DateTime.now();
      final nextOccurrence = _calculateNextOccurrence(firstOccurrence, recurringPattern);

      final recurringTransaction = transaction.copyWith(
        date: firstOccurrence,
        isRecurring: true,
        recurringPattern: recurringPattern,
        nextOccurrence: nextOccurrence,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await db.insert(
        DbConstants.tableTransactions,
        recurringTransaction.toMap(),
      );

      // Programmer la notification
      await NotificationService.instance.scheduleRecurringTransaction(
        id: id,
        title: transaction.title,
        amount: transaction.amount,
        nextOccurrence: nextOccurrence,
      );

      debugPrint('✅ Transaction récurrente créée: ${transaction.title} ($recurringPattern)');

      return recurringTransaction.copyWith(id: id);
    } catch (e) {
      debugPrint('❌ Erreur createRecurringTransaction: $e');
      return null;
    }
  }

  /// Arrêter une transaction récurrente
  Future<bool> stopRecurringTransaction(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;

      await db.update(
        DbConstants.tableTransactions,
        {
          DbConstants.columnIsRecurring: 0,
          DbConstants.columnRecurringPattern: null,
          DbConstants.columnNextOccurrence: null,
          DbConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '${DbConstants.columnId} = ?',
        whereArgs: [id],
      );

      // Annuler la notification
      await NotificationService.instance.cancel(id);

      debugPrint('✅ Transaction récurrente arrêtée: ID $id');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur stopRecurringTransaction: $e');
      return false;
    }
  }

  /// Obtenir toutes les transactions récurrentes actives
  Future<List<TransactionModel>> getActiveRecurringTransactions() async {
    try {
      final db = await DatabaseHelper.instance.database;

      final List<Map<String, dynamic>> maps = await db.query(
        DbConstants.tableTransactions,
        where: '${DbConstants.columnIsRecurring} = ?',
        whereArgs: [1],
        orderBy: '${DbConstants.columnNextOccurrence} ASC',
      );

      return maps.map((map) => TransactionModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Erreur getActiveRecurringTransactions: $e');
      return [];
    }
  }

  /// Formater le pattern en texte lisible
  static String formatPattern(String pattern) {
    switch (pattern.toLowerCase()) {
      case 'daily':
        return 'Quotidienne';
      case 'weekly':
        return 'Hebdomadaire';
      case 'biweekly':
        return 'Bimensuelle';
      case 'monthly':
        return 'Mensuelle';
      case 'quarterly':
        return 'Trimestrielle';
      case 'yearly':
        return 'Annuelle';
      default:
        return pattern;
    }
  }
}
