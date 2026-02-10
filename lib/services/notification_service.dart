import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Service de gestion des notifications locales
class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  NotificationService._init();

  /// Initialiser le service de notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
    debugPrint('✅ NotificationService initialisé');
  }

  /// Gérer le tap sur une notification
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('🔔 Notification tappée: ${response.payload}');
    // Vous pouvez ajouter une navigation ici
  }

  /// Demander les permissions (Android 13+)
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidPlugin != null) {
        return await androidPlugin.requestNotificationsPermission() ?? false;
      }
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final IOSFlutterLocalNotificationsPlugin? iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iosPlugin != null) {
        return await iosPlugin.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    }

    return true;
  }

  /// Afficher une notification de dépassement de budget
  Future<void> showBudgetWarning({
    required String categoryName,
    required double percentage,
    required double spent,
    required double limit,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'budget_warnings',
          'Alertes Budget',
          channelDescription:
              'Notifications quand un budget approche de la limite',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFF59E0B), // Orange
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      categoryName.hashCode, // ID unique par catégorie
      '⚠️ Budget $categoryName',
      'Vous avez utilisé ${percentage.toStringAsFixed(0)}% (${spent.toStringAsFixed(2)}€ / ${limit.toStringAsFixed(2)}€)',
      details,
      payload: 'budget_warning_$categoryName',
    );

    debugPrint(
      '🔔 Notification envoyée: Budget $categoryName à ${percentage.toStringAsFixed(0)}%',
    );
  }

  /// Afficher une notification de dépassement critique
  Future<void> showBudgetExceeded({
    required String categoryName,
    required double exceeded,
    required double limit,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'budget_exceeded',
          'Budget Dépassé',
          channelDescription: 'Notifications de dépassement de budget',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFEF4444), // Rouge
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      categoryName.hashCode + 1000, // ID différent
      '🚨 Budget $categoryName Dépassé!',
      'Vous avez dépassé de ${exceeded.toStringAsFixed(2)}€ (Limite: ${limit.toStringAsFixed(2)}€)',
      details,
      payload: 'budget_exceeded_$categoryName',
    );

    debugPrint(
      '🔔 Notification CRITIQUE: Budget $categoryName dépassé de ${exceeded.toStringAsFixed(2)}€',
    );
  }

  /// Notification pour objectif d'épargne atteint
  Future<void> showGoalAchieved({
    required String goalName,
    required double amount,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'goals_achieved',
          'Objectifs Atteints',
          channelDescription: 'Notifications quand un objectif est atteint',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF2ECC71), // Vert
          playSound: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      goalName.hashCode,
      '🎉 Objectif Atteint!',
      'Félicitations! Vous avez atteint votre objectif "$goalName" (${amount.toStringAsFixed(2)}€)',
      details,
      payload: 'goal_achieved_$goalName',
    );

    debugPrint('🔔 Notification: Objectif $goalName atteint!');
  }

  /// Programmer une notification récurrente pour une transaction
  Future<void> scheduleRecurringTransaction({
    required int id,
    required String title,
    required double amount,
    required DateTime nextOccurrence,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'recurring_transactions',
          'Transactions Récurrentes',
          channelDescription: 'Rappels pour les transactions automatiques',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Note: flutter_local_notifications ne supporte pas nativement les récurrences
    // Il faut utiliser un package comme workmanager pour cela
    // Ceci est une notification one-time
    await _notifications.zonedSchedule(
      id,
      '📅 Transaction Récurrente',
      '$title - ${amount.toStringAsFixed(2)}€',
      _convertToTZDateTime(nextOccurrence),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint(
      '🔔 Notification programmée: $title pour ${nextOccurrence.toIso8601String()}',
    );
  }

  /// Convertir DateTime en TZDateTime (timezone aware)
  dynamic _convertToTZDateTime(DateTime dateTime) {
    // Utilisation simple sans timezone pour l'instant
    // Dans une vraie app, utilisez le package timezone
    return dateTime;
  }

  /// Annuler toutes les notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    debugPrint('🔕 Toutes les notifications annulées');
  }

  /// Annuler une notification spécifique
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
    debugPrint('🔕 Notification $id annulée');
  }
}
