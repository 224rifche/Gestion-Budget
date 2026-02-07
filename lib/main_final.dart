import 'package:flutter/material.dart';

/// Version finale de BudgetBuddy - sans build, pure web
void main() {
  runApp(const BudgetBuddyFinal());
}

class BudgetBuddyFinal extends StatelessWidget {
  const BudgetBuddyFinal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BudgetBuddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.light,
        ),
      ),
      home: const BudgetBuddyHomeFinal(),
    );
  }
}

class BudgetBuddyHomeFinal extends StatefulWidget {
  const BudgetBuddyHomeFinal({super.key});

  @override
  State<BudgetBuddyHomeFinal> createState() => _BudgetBuddyHomeFinalState();
}

class _BudgetBuddyHomeFinalState extends State<BudgetBuddyHomeFinal> {
  int _currentIndex = 0;
  
  // Données de démonstration
  final double _balance = 2767.00;
  final double _monthlyIncome = 2950.00;
  final double _monthlyExpense = 183.00;
  
  final List<Map<String, dynamic>> _transactions = [
    {
      'icon': '🍔',
      'title': 'Courses Carrefour',
      'amount': -85.50,
      'date': 'Il y a 2 jours',
      'color': Colors.red,
    },
    {
      'icon': '💰',
      'title': 'Salaire Mensuel',
      'amount': 2500.00,
      'date': 'Il y a 5 jours',
      'color': Colors.green,
    },
    {
      'icon': '🚗',
      'title': 'Essence',
      'amount': -65.00,
      'date': 'Il y a 1 semaine',
      'color': Colors.red,
    },
    {
      'icon': '🎬',
      'title': 'Restaurant',
      'amount': -32.50,
      'date': 'Il y a 1 semaine',
      'color': Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BudgetBuddy'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('BudgetBuddy - Version finale sans build'),
              backgroundColor: Color(0xFFF59E0B),
            ),
          );
        },
        backgroundColor: const Color(0xFFF59E0B),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistiques',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budgets',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeView();
      case 1:
        return _buildTransactionsView();
      case 2:
        return _buildStatisticsView();
      case 3:
        return _buildBudgetsView();
      default:
        return _buildHomeView();
    }
  }

  Widget _buildHomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte de solde
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Solde actuel',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_balance.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Résumé du mois
          const Text(
            'Ce mois-ci',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.arrow_downward, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Revenus',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_monthlyIncome.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.arrow_upward, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Dépenses',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_monthlyExpense.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Transactions récentes
          const Text(
            'Transactions récentes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Liste de transactions
          ..._transactions.map((transaction) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: transaction['color'].withValues(alpha: 0.1),
                  child: Text(
                    transaction['icon'],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                title: Text(transaction['title']),
                subtitle: Text(transaction['date']),
                trailing: Text(
                  '${transaction['amount'] > 0 ? '+' : ''}${transaction['amount'].toStringAsFixed(2)} €',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: transaction['color'],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTransactionsView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.list, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Liste des transactions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('(Version finale - sans build)'),
        ],
      ),
    );
  }

  Widget _buildStatisticsView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Statistiques',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('(Version finale - sans build)'),
        ],
      ),
    );
  }

  Widget _buildBudgetsView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Budgets',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('(Version finale - sans build)'),
        ],
      ),
    );
  }
}
