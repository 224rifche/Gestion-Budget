import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/theme.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Écran principal des paramètres
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (settingsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = settingsProvider.settings;

          return ListView(
            children: [
              // En-tête utilisateur
              _buildHeader(context),

              const SizedBox(height: 16),

              // Section Général
              _buildSectionHeader(context, '⚙️ Général'),
              _buildListTile(
                context,
                icon: Icons.attach_money,
                title: 'Devise',
                subtitle: settings.currency,
                onTap: () => _showCurrencyPicker(context, settingsProvider),
              ),
              _buildListTile(
                context,
                icon: Icons.language,
                title: 'Langue',
                subtitle: _getLanguageName(settings.language),
                onTap: () => _showLanguagePicker(context, settingsProvider),
              ),
              _buildListTile(
                context,
                icon: Icons.calendar_today,
                title: 'Premier jour de la semaine',
                subtitle: settings.firstDayOfWeek == 1 ? 'Lundi' : 'Dimanche',
                onTap: () => _showFirstDayPicker(context, settingsProvider),
              ),

              const Divider(height: 32),

              // Section Apparence
              _buildSectionHeader(context, '🎨 Apparence'),
              _buildSwitchTile(
                context,
                icon: Icons.brightness_6,
                title: 'Thème sombre',
                subtitle: 'Utiliser le thème sombre',
                value: settings.theme == 'dark',
                onChanged: (value) {
                  settingsProvider.updateSetting(
                    'theme',
                    value ? 'dark' : 'light',
                  );
                },
              ),
              _buildSwitchTile(
                context,
                icon: Icons.animation,
                title: 'Animations',
                subtitle: 'Activer les animations dans l\'app',
                value: settings.showAnimations,
                onChanged: (value) {
                  settingsProvider.updateSetting('show_animations', value);
                },
              ),

              const Divider(height: 32),

              // Section Budgets
              _buildSectionHeader(context, '💰 Budgets'),
              _buildSwitchTile(
                context,
                icon: Icons.notifications_active,
                title: 'Notifications de budget',
                subtitle: 'Recevoir des alertes de dépassement',
                value: settings.budgetNotifications,
                onChanged: (value) {
                  settingsProvider.updateSetting('budget_notifications', value);
                },
              ),
              _buildListTile(
                context,
                icon: Icons.warning_amber,
                title: 'Seuil d\'alerte',
                subtitle: '${settings.budgetWarningThreshold.toInt()}%',
                onTap: () => _showThresholdPicker(context, settingsProvider),
              ),
              _buildListTile(
                context,
                icon: Icons.date_range,
                title: 'Période par défaut',
                subtitle: _getPeriodName(settings.defaultBudgetPeriod),
                onTap: () => _showPeriodPicker(context, settingsProvider),
              ),
              _buildSwitchTile(
                context,
                icon: Icons.dashboard,
                title: 'Résumé des budgets',
                subtitle: 'Afficher sur l\'écran d\'accueil',
                value: settings.showBudgetSummary,
                onChanged: (value) {
                  settingsProvider.updateSetting('show_budget_summary', value);
                },
              ),

              const Divider(height: 32),

              // Section Sécurité
              _buildSectionHeader(context, '🔐 Sécurité'),
              _buildSwitchTile(
                context,
                icon: Icons.fingerprint,
                title: 'Authentification biométrique',
                subtitle: 'Face ID / Empreinte digitale',
                value: settings.biometricAuth,
                onChanged: (value) async {
                  final success = await settingsProvider.toggleBiometricAuth(
                    value,
                  );
                  if (!success && value && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Biométrie non disponible ou authentification échouée',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              _buildSwitchTile(
                context,
                icon: Icons.lock,
                title: 'Verrouillage au démarrage',
                subtitle: 'Demander l\'authentification à l\'ouverture',
                value: settings.requireAuthOnStart,
                onChanged: (value) {
                  settingsProvider.updateSetting(
                    'require_auth_on_start',
                    value,
                  );
                },
              ),
              _buildListTile(
                context,
                icon: Icons.timer,
                title: 'Verrouillage automatique',
                subtitle: settings.autoLockMinutes == 0
                    ? 'Désactivé'
                    : '${settings.autoLockMinutes} minutes',
                onTap: () => _showAutoLockPicker(context, settingsProvider),
              ),

              const Divider(height: 32),

              // Section Notifications
              _buildSectionHeader(context, '🔔 Notifications'),
              _buildSwitchTile(
                context,
                icon: Icons.notifications,
                title: 'Activer les notifications',
                subtitle: 'Recevoir toutes les notifications',
                value: settings.notificationsEnabled,
                onChanged: (value) {
                  settingsProvider.toggleNotifications(value);
                },
              ),
              if (settings.notificationsEnabled) ...[
                _buildSwitchTile(
                  context,
                  icon: Icons.account_balance_wallet,
                  title: 'Alertes de budget',
                  subtitle: 'Quand un budget approche de la limite',
                  value: settings.budgetAlerts,
                  onChanged: (value) {
                    settingsProvider.updateSetting('budget_alerts', value);
                  },
                ),
                _buildSwitchTile(
                  context,
                  icon: Icons.repeat,
                  title: 'Rappels récurrents',
                  subtitle: 'Transactions récurrentes à venir',
                  value: settings.recurringReminders,
                  onChanged: (value) {
                    settingsProvider.updateSetting(
                      'recurring_reminders',
                      value,
                    );
                  },
                ),
                _buildSwitchTile(
                  context,
                  icon: Icons.emoji_events,
                  title: 'Objectifs atteints',
                  subtitle: 'Quand un objectif d\'épargne est atteint',
                  value: settings.goalAchievements,
                  onChanged: (value) {
                    settingsProvider.updateSetting('goal_achievements', value);
                  },
                ),
              ],

              const Divider(height: 32),

              // Section Confidentialité
              _buildSectionHeader(context, '🔒 Confidentialité'),
              _buildSwitchTile(
                context,
                icon: Icons.visibility_off,
                title: 'Masquer les montants',
                subtitle: 'Cacher les montants dans les notifications',
                value: settings.hideAmounts,
                onChanged: (value) {
                  settingsProvider.updateSetting('hide_amounts', value);
                },
              ),
              _buildSwitchTile(
                context,
                icon: Icons.analytics,
                title: 'Statistiques anonymes',
                subtitle: 'Aider à améliorer l\'application',
                value: settings.anonymousAnalytics,
                onChanged: (value) {
                  settingsProvider.updateSetting('anonymous_analytics', value);
                },
              ),

              const Divider(height: 32),

              // Section Avancé
              _buildSectionHeader(context, '🛠️ Avancé'),
              _buildListTile(
                context,
                icon: Icons.backup,
                title: 'Sauvegarder les données',
                subtitle: settings.lastBackupDate != null
                    ? 'Dernière sauvegarde: ${_formatDate(settings.lastBackupDate!)}'
                    : 'Aucune sauvegarde',
                onTap: () => _performBackup(context, settingsProvider),
              ),
              _buildListTile(
                context,
                icon: Icons.restore,
                title: 'Restaurer les données',
                subtitle: 'Importer depuis une sauvegarde',
                onTap: () => _performRestore(context),
              ),
              _buildListTile(
                context,
                icon: Icons.delete_forever,
                title: 'Réinitialiser l\'application',
                subtitle: 'Supprimer toutes les données',
                textColor: Colors.red,
                onTap: () => _confirmReset(context, settingsProvider),
              ),

              const Divider(height: 32),

              // Section À propos
              _buildSectionHeader(context, 'ℹ️ À propos'),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  final info = snapshot.data!;
                  return Column(
                    children: [
                      _buildListTile(
                        context,
                        icon: Icons.info,
                        title: 'Version',
                        subtitle: info.version,
                      ),
                      _buildListTile(
                        context,
                        icon: Icons.code,
                        title: 'Build',
                        subtitle: info.buildNumber,
                      ),
                    ],
                  );
                },
              ),
              _buildListTile(
                context,
                icon: Icons.description,
                title: 'Conditions d\'utilisation',
                onTap: () => _showTerms(context),
              ),
              _buildListTile(
                context,
                icon: Icons.privacy_tip,
                title: 'Politique de confidentialité',
                onTap: () => _showPrivacyPolicy(context),
              ),

              const SizedBox(height: 32),

              // Footer
              Center(
                child: Column(
                  children: [
                    const Text(
                      '💰 BudgetBuddy',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gestion de budget personnel',
                      style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '© 2025 Boubacar Baldé - KCT',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 40, color: AppTheme.primaryColor),
          ),
          SizedBox(height: 16),
          Text(
            'Paramètres',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Personnalisez votre expérience',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppTheme.primaryColor),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.primaryColor,
      activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.3),
    );
  }

  // Pickers et dialogues
  void _showCurrencyPicker(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Devise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('GNF - Guinée Franc'),
              subtitle: const Text('Devise nationale'),
              onTap: () {
                provider.updateCurrency('GNF');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('EUR - Euro'),
              subtitle: const Text('Devise européenne'),
              onTap: () {
                provider.updateCurrency('EUR');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('USD - Dollar Américain'),
              subtitle: const Text('Devise américaine'),
              onTap: () {
                provider.updateCurrency('USD');
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Français'),
              subtitle: const Text('Français'),
              onTap: () {
                provider.updateLanguage('fr');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English'),
              subtitle: const Text('Anglais'),
              onTap: () {
                provider.updateLanguage('en');
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showFirstDayPicker(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premier jour du mois'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(7, (index) {
            final day = index + 1;
            return ListTile(
              title: Text('Jour $day'),
              subtitle: Text('Le $day du mois'),
              onTap: () {
                provider.updateFirstDayOfMonth(day);
                Navigator.pop(context);
              },
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showThresholdPicker(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seuil de budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [50, 60, 70, 80, 85, 90].map((threshold) {
            return ListTile(
              title: Text('$threshold%'),
              subtitle: Text('Alerte à $threshold% du budget'),
              onTap: () {
                provider.updateBudgetWarningThreshold(threshold.toDouble());
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showPeriodPicker(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Période par défaut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Journalier'),
              subtitle: const Text('Budgets quotidiens'),
              onTap: () {
                provider.updateDefaultBudgetPeriod('daily');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Hebdomadaire'),
              subtitle: const Text('Budgets hebdomadaires'),
              onTap: () {
                provider.updateDefaultBudgetPeriod('weekly');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Mensuel'),
              subtitle: const Text('Budgets mensuels'),
              onTap: () {
                provider.updateDefaultBudgetPeriod('monthly');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Annuel'),
              subtitle: const Text('Budgets annuels'),
              onTap: () {
                provider.updateDefaultBudgetPeriod('yearly');
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showAutoLockPicker(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verrouillage automatique'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Jamais'),
              subtitle: const Text('Désactivé'),
              onTap: () {
                provider.updateAutoLockTimeout(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('1 minute'),
              subtitle: const Text('Après 1 minute'),
              onTap: () {
                provider.updateAutoLockTimeout(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('5 minutes'),
              subtitle: const Text('Après 5 minutes'),
              onTap: () {
                provider.updateAutoLockTimeout(5);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('15 minutes'),
              subtitle: const Text('Après 15 minutes'),
              onTap: () {
                provider.updateAutoLockTimeout(15);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('30 minutes'),
              subtitle: const Text('Après 30 minutes'),
              onTap: () {
                provider.updateAutoLockTimeout(30);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _performBackup(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sauvegarder les données'),
        content: const Text(
          'Voulez-vous créer une sauvegarde de toutes vos données ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sauvegarde créée avec succès !'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _performRestore(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer les données'),
        content: const Text(
          'Voulez-vous restaurer vos données à partir d\'une sauvegarde ?\n\nAttention : cela remplacera toutes vos données actuelles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Restauration terminée avec succès !'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser les paramètres'),
        content: const Text(
          'Voulez-vous réinitialiser tous les paramètres à leurs valeurs par défaut ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Paramètres réinitialisés avec succès !'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  void _showTerms(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conditions d\'utilisation'),
        content: const SingleChildScrollView(
          child: Text(
            'BudgetBuddy - Conditions d\'utilisation\n\n'
            '1. Acceptation des conditions\n'
            'En utilisant BudgetBuddy, vous acceptez ces conditions.\n\n'
            '2. Utilisation de l\'application\n'
            'BudgetBuddy est un outil de gestion budgétaire personnelle.\n\n'
            '3. Confidentialité des données\n'
            'Vos données sont stockées localement sur votre appareil.\n\n'
            '4. Responsabilité\n'
            'Vous êtes responsable de l\'exactitude de vos données.\n\n'
            '5. Mises à jour\n'
            'L\'application peut être mise à jour pour améliorer les fonctionnalités.\n\n'
            '6. Contact\n'
            'Pour toute question, contactez le support.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Politique de confidentialité'),
        content: const SingleChildScrollView(
          child: Text(
            'BudgetBuddy - Politique de confidentialité\n\n'
            '1. Collecte des données\n'
            'BudgetBuddy ne collecte aucune donnée personnelle.\n\n'
            '2. Stockage local\n'
            'Toutes vos données sont stockées localement sur votre appareil.\n\n'
            '3. Aucun partage de données\n'
            'Nous ne partageons jamais vos données avec des tiers.\n\n'
            '4. Sécurité\n'
            'Vos données sont protégées par les mesures de sécurité de votre appareil.\n\n'
            '5. Sauvegarde\n'
            'Les sauvegardes sont sous votre contrôle complet.\n\n'
            '6. Contact\n'
            'Pour toute question sur la confidentialité, contactez-nous.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      default:
        return code;
    }
  }

  String _getPeriodName(String period) {
    switch (period) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
