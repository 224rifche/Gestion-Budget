import 'package:intl/intl.dart';

/// Utilitaires de formatage pour BudgetBuddy
class Formatters {
  // Formatters monétaires
  static final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'GNF',
    decimalDigits: 0, // GNF n'a généralement pas de décimales
  );

  static final NumberFormat currencyFormatterWithDecimals = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'GNF',
    decimalDigits: 2,
  );

  static final NumberFormat compactCurrencyFormatter =
      NumberFormat.compactCurrency(
        locale: 'fr_FR',
        symbol: 'GNF',
        decimalDigits: 1,
      );

  // Formatters de dates
  static final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
  static final DateFormat shortDateFormatter = DateFormat('dd/MM');
  static final DateFormat monthYearFormatter = DateFormat('MMMM yyyy', 'fr_FR');
  static final DateFormat dayMonthFormatter = DateFormat('d MMMM', 'fr_FR');
  static final DateFormat timeFormatter = DateFormat('HH:mm');
  static final DateFormat dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');

  // Formatter de nombres
  static final NumberFormat numberFormatter = NumberFormat.decimalPattern(
    'fr_FR',
  );

  static final NumberFormat percentFormatter = NumberFormat.percentPattern(
    'fr_FR',
  );

  /// Formater un montant en GNF
  static String formatCurrency(double amount) {
    // Pour GNF, on n'affiche généralement pas les décimales
    return '${amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    )} GNF';
  }

  // Formatter pour les montants avec décimales si nécessaire
  static String formatCurrencyWithDecimals(double amount) {
    return currencyFormatterWithDecimals.format(amount);
  }

  // Formatter compact pour les grands montants
  static String formatCompactCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M GNF';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K GNF';
    } else {
      return formatCurrency(amount);
    }
  }

  /// Formater la différence de temps (ex: "il y a 2 heures")
  static String formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Hier';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays} jours';
      } else if (difference.inDays < 30) {
        return 'Il y a ${(difference.inDays / 7).floor()} semaine${(difference.inDays / 7).floor() > 1 ? 's' : ''}';
      } else if (difference.inDays < 365) {
        return 'Il y a ${(difference.inDays / 30).floor()} mois';
      } else {
        return 'Il y a ${(difference.inDays / 365).floor()} an${(difference.inDays / 365).floor() > 1 ? 's' : ''}';
      }
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  // Formatter de pourcentage
  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  // Formatter de nombre
  static String formatNumber(double number) {
    return numberFormatter.format(number);
  }

  // Formatter de nombre compact
  static String formatCompactNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return formatNumber(number);
    }
  }

  // Formatter de période
  static String formatPeriod(String period) {
    switch (period.toLowerCase()) {
      case 'daily':
        return 'Quotidien';
      case 'weekly':
        return 'Hebdomadaire';
      case 'monthly':
        return 'Mensuel';
      case 'yearly':
        return 'Annuel';
      default:
        return period;
    }
  }

  // Formatter de type de transaction
  static String formatTransactionType(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return 'Revenu';
      case 'expense':
        return 'Dépense';
      default:
        return type;
    }
  }

  // Formatter de méthode de paiement
  static String formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Espèces';
      case 'card':
        return 'Carte bancaire';
      case 'transfer':
        return 'Virement';
      case 'mobile':
        return 'Mobile Money';
      default:
        return method;
    }
  }

  // Formatter de date
  static String formatDate(DateTime date) {
    return dateFormatter.format(date);
  }

  static String formatDateWithTime(DateTime date) {
    return dateTimeFormatter.format(date);
  }

  static String formatShortDate(DateTime date) {
    return shortDateFormatter.format(date);
  }

  static String formatMonthYear(DateTime date) {
    return monthYearFormatter.format(date);
  }
}
