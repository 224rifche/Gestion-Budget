import 'package:flutter/material.dart';
import '../services/notification_service.dart';

/// Widget de test pour les notifications
class NotificationTestWidget extends StatelessWidget {
  const NotificationTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔔 Tests de Notifications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _testBudgetWarning(),
                  icon: const Icon(Icons.warning),
                  label: const Text('Avertissement Budget'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                ElevatedButton.icon(
                  onPressed: () => _testBudgetExceeded(),
                  icon: const Icon(Icons.error),
                  label: const Text('Budget Dépassé'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                ElevatedButton.icon(
                  onPressed: () => _testGoalAchieved(),
                  icon: const Icon(Icons.celebration),
                  label: const Text('Objectif Atteint'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                ElevatedButton.icon(
                  onPressed: () => _testRecurringTransaction(),
                  icon: const Icon(Icons.schedule),
                  label: const Text('Transaction Récurrente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                ElevatedButton.icon(
                  onPressed: () => _cancelAll(),
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Tout Annuler'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Text(
              '💡 Utilisez ces boutons pour tester les différentes notifications. '
              'Assurez-vous d\'avoir accordé les permissions de notification.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testBudgetWarning() async {
    await NotificationService.instance.showBudgetWarning(
      categoryName: 'Alimentation',
      percentage: 85.0,
      spent: 425.50,
      limit: 500.0,
    );
  }

  void _testBudgetExceeded() async {
    await NotificationService.instance.showBudgetExceeded(
      categoryName: 'Transport',
      exceeded: 50.25,
      limit: 200.0,
    );
  }

  void _testGoalAchieved() async {
    await NotificationService.instance.showGoalAchieved(
      goalName: 'Vacances 2024',
      amount: 1500.0,
    );
  }

  void _testRecurringTransaction() async {
    await NotificationService.instance.scheduleRecurringTransaction(
      id: 12345,
      title: 'Loyer Mensuel',
      amount: 800.0,
      nextOccurrence: DateTime.now().add(const Duration(seconds: 5)),
    );
  }

  void _cancelAll() async {
    await NotificationService.instance.cancelAll();
  }
}
