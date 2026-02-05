import 'package:intl/intl.dart';

/// Utilitaires de formatage pour BudgetBuddy
class Formatters {
  // Formatters monétaires
  static final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 2,
  );

  static final NumberFormat compactCurrencyFormatter = NumberFormat.compactCurrency(
    locale: 'fr_FR',
    symbol: '€',
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
  static final NumberFormat numberFormatter = NumberFormat.decimalPattern('fr_FR');
  static final NumberFormat percentFormatter = NumberFormat.percentPattern('fr_FR');

  /// Formater un montant en euros
  static String formatCurrency(double amount) {
    return currencyFormatter.format(amount);
  }

  /// Formater un montant compact (ex: 1.2k€ pour 1200€)
  static String formatCompactCurrency(double amount) {
    return compactCurrencyFormatter.format(amount);
  }

  /// Formater un montant sans symbole
  static String formatAmount(double amount) {
    return numberFormatter.format(amount);
  }

  /// Formater un pourcentage
  static String formatPercentage(double value) {
    return percentFormatter.format(value / 100);
  }

  /// Formater une date complète
  static String formatDate(DateTime date) {
    return dateFormatter.format(date);
  }

  /// Formater une date courte (jour/mois)
  static String formatShortDate(DateTime date) {
    return shortDateFormatter.format(date);
  }

  /// Formater mois et année
  static String formatMonthYear(DateTime date) {
    return monthYearFormatter.format(date);
  }

  /// Formater jour et mois
  static String formatDayMonth(DateTime date) {
    return dayMonthFormatter.format(date);
  }

  /// Formater l'heure
  static String formatTime(DateTime date) {
    return timeFormatter.format(date);
  }

  /// Formater date et heure
  static String formatDateTime(DateTime date) {
    return dateTimeFormatter.format(date);
  }

  /// Formater une durée (ex: "2 jours", "1 semaine")
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} jour${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} heure${duration.inHours > 1 ? 's' : ''}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Quelques secondes';
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
        final weeks = (difference.inDays / 7).floor();
        return 'Il y a ${weeks} semaine${weeks > 1 ? 's' : ''}';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return 'Il y a ${months} mois';
      } else {
        final years = (difference.inDays / 365).floor();
        return 'Il y a ${years} an${years > 1 ? 's' : ''}';
      }
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  /// Formater un nombre avec séparateurs de milliers
  static String formatNumber(int number) {
    return NumberFormat.decimalPattern('fr_FR').format(number);
  }

  /// Formater un texte pour l'affichage (tronquer si trop long)
  static String formatText(String text, {int maxLength = 20}) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// Formater un type de transaction en français
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

  /// Formater une période de budget en français
  static String formatPeriodType(String period) {
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

  /// Formater un montant avec couleur (positif/négatif)
  static String formatAmountWithSign(double amount) {
    final formatted = formatCurrency(amount.abs());
    return amount >= 0 ? '+$formatted' : '-$formatted';
  }

  /// Capitaliser la première lettre
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
  }

  /// Formater une liste en texte (ex: "A, B et C")
  static String formatList(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items[0];
    if (items.length == 2) return '${items[0]} et ${items[1]}';
    
    return '${items.take(items.length - 1).join(', ')} et ${items.last}';
  }
}

/// Extension pour DateTime
extension DateTimeExtensions on DateTime {
  /// Vérifier si c'est aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    return day == now.day && month == now.month && year == now.year;
  }

  /// Vérifier si c'est hier
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return day == yesterday.day && month == yesterday.month && year == yesterday.year;
  }

  /// Vérifier si c'est cette semaine
  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return isAfter(weekStart.subtract(const Duration(days: 1))) && 
           isBefore(weekEnd.add(const Duration(days: 1)));
  }

  /// Vérifier si c'est ce mois
  bool get isThisMonth {
    final now = DateTime.now();
    return month == now.month && year == now.year;
  }

  /// Vérifier si c'est cette année
  bool get isThisYear {
    return year == DateTime.now().year;
  }
}

/// Extension pour double
extension DoubleExtensions on double {
  /// Arrondir à 2 décimales
  double roundToTwoDecimals() {
    return (this * 100).roundToDouble() / 100;
  }

  /// Formater comme monnaie
  String toCurrency() {
    return Formatters.formatCurrency(this);
  }

  /// Formater comme pourcentage
  String toPercentage() {
    return Formatters.formatPercentage(this);
  }
}
