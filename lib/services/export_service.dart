import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

/// Service pour l'export des données
class ExportService {
  /// Exporter les transactions en CSV
  static Future<File> exportTransactionsToCSV(List<TransactionModel> transactions) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'budget_buddy_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');

      // Créer le contenu CSV
      final buffer = StringBuffer();
      
      // En-tête
      buffer.writeln('Date,Titre,Montant,Type,Catégorie,Méthode de paiement,Description');
      
      // Données
      for (final transaction in transactions) {
        final date = Formatters.formatDate(transaction.date);
        final amount = transaction.amount.abs().toStringAsFixed(2);
        final type = transaction.transactionType == 'income' ? 'Revenu' : 'Dépense';
        final description = transaction.description?.replaceAll(',', ';') ?? '';
        
        buffer.writeln('$date,${transaction.title},$amount,$type,${transaction.categoryId},$transaction.paymentMethod,$description');
      }

      // Écrire dans le fichier
      await file.writeAsString(buffer.toString());
      
      return file;
    } catch (e) {
      throw Exception('Erreur lors de l\'export CSV: $e');
    }
  }

  /// Partager le fichier CSV
  static Future<void> shareCSVFile(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Export BudgetBuddy',
        text: 'Export de vos transactions BudgetBuddy',
      );
    } catch (e) {
      throw Exception('Erreur lors du partage: $e');
    }
  }

  /// Exporter les transactions en format texte simple
  static Future<File> exportTransactionsToText(List<TransactionModel> transactions) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'budget_buddy_export_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${directory.path}/$fileName');

      final buffer = StringBuffer();
      buffer.writeln('=== EXPORT DES TRANSACTIONS BUDGETBUDDY ===');
      buffer.writeln('Date: ${Formatters.formatDate(DateTime.now())}');
      buffer.writeln('Nombre de transactions: ${transactions.length}');
      buffer.writeln('');
      
      double totalRevenus = 0;
      double totalDepenses = 0;
      
      for (final transaction in transactions) {
        if (transaction.amount > 0) {
          totalRevenus += transaction.amount;
        } else {
          totalDepenses += transaction.amount.abs();
        }
        
        buffer.writeln('---');
        buffer.writeln('Date: ${Formatters.formatDate(transaction.date)}');
        buffer.writeln('Titre: ${transaction.title}');
        buffer.writeln('Montant: ${Formatters.formatCurrency(transaction.amount)}');
        buffer.writeln('Type: ${transaction.transactionType == 'income' ? 'Revenu' : 'Dépense'}');
        buffer.writeln('Catégorie ID: ${transaction.categoryId}');
        buffer.writeln('Méthode: ${transaction.paymentMethod}');
        if (transaction.description != null) {
          buffer.writeln('Description: ${transaction.description}');
        }
        buffer.writeln('');
      }
      
      buffer.writeln('=== RÉSUMÉ ===');
      buffer.writeln('Total des revenus: ${Formatters.formatCurrency(totalRevenus)}');
      buffer.writeln('Total des dépenses: ${Formatters.formatCurrency(totalDepenses)}');
      buffer.writeln('Solde: ${Formatters.formatCurrency(totalRevenus - totalDepenses)}');

      await file.writeAsString(buffer.toString());
      
      return file;
    } catch (e) {
      throw Exception('Erreur lors de l\'export texte: $e');
    }
  }

  /// Obtenir les statistiques pour l'export
  static Map<String, dynamic> getExportStatistics(List<TransactionModel> transactions) {
    final totalRevenus = transactions
        .where((t) => t.amount > 0)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final totalDepenses = transactions
        .where((t) => t.amount < 0)
        .fold(0.0, (sum, t) => sum + t.amount.abs());
        
    final Map<int, int> categoryCount = {};
    for (final transaction in transactions) {
      categoryCount[transaction.categoryId] = (categoryCount[transaction.categoryId] ?? 0) + 1;
    }
    
    final mostUsedCategory = categoryCount.entries.isNotEmpty
        ? categoryCount.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : null;

    return {
      'total_transactions': transactions.length,
      'total_revenus': totalRevenus,
      'total_depenses': totalDepenses,
      'solde': totalRevenus - totalDepenses,
      'most_used_category_id': mostUsedCategory,
      'export_date': DateTime.now().toIso8601String(),
    };
  }
}
