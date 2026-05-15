import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/user_auth_provider.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;

  double monthlyIncome = 0;
  double totalIncome = 0;
  double totalExpenses = 0;
  double balance = 0;

  double needsBudget = 0;
  double wantsBudget = 0;
  double savingsBudget = 0;

  double needsSpent = 0;
  double wantsSpent = 0;
  double savingsSpent = 0;

  String currency = "USD";

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // -------------------------------------------------------
  // LOAD DASHBOARD DATA
  // -------------------------------------------------------
  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);

    final auth = Provider.of<UserAuthProvider>(context, listen: false);
    final user = auth.userModel!;
    final uid = _auth.currentUser!.uid;

    // Load from userModel
    monthlyIncome = user.monthlyIncome;
    needsBudget = user.needsBudget;
    wantsBudget = user.wantsBudget;
    savingsBudget = user.savingsBudget;
    currency = user.currency;

    // Load group spent values
    final budgetDoc = await _firestore
        .collection("users")
        .doc(uid)
        .collection("budget")
        .doc("current")
        .get();

    if (budgetDoc.exists) {
      needsSpent = (budgetDoc["needsSpent"] ?? 0).toDouble();
      wantsSpent = (budgetDoc["wantsSpent"] ?? 0).toDouble();
      savingsSpent = (budgetDoc["savingsSpent"] ?? 0).toDouble();
    }

    // Load all transactions
    final txSnap = await _firestore
        .collection("users")
        .doc(uid)
        .collection("transactions")
        .get();

    double inc = 0, exp = 0;

    for (var doc in txSnap.docs) {
      final data = doc.data();
      final type = data["type"];
      final amount = (data["amount"] ?? 0).toDouble();

      if (type == "income") inc += amount;
      if (type == "expense") exp += amount;
    }

    totalIncome = inc;
    totalExpenses = exp;
    balance = totalIncome - totalExpenses;

    setState(() => isLoading = false);
  }

  // -------------------------------------------------------
  // BUILD UI
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserAuthProvider>(context).userModel!;
    final name = user.email.split("@")[0];

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("BudgetBuddy"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------ GREETING ------------------
              Text(
                "Welcome, $name!",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 24),

              // ------------------ SUMMARY CARDS ------------------
              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                        "INCOME", totalIncome, Colors.green, currency),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(
                        "EXPENSES", totalExpenses, Colors.red, currency),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(
                        "BALANCE", balance, Colors.blue, currency),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ------------------ GROUP SECTIONS ------------------
              _groupSection("Needs", needsSpent, needsBudget, currency),
              const SizedBox(height: 20),
              _groupSection("Wants", wantsSpent, wantsBudget, currency),
              const SizedBox(height: 20),
              _groupSection("Savings", savingsSpent, savingsBudget, currency),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // WIDGETS
  // -------------------------------------------------------

  Widget _summaryCard(
      String label, double amount, Color color, String currency) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "$currency ${amount.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ]),
      ),
    );
  }

  Widget _groupSection(
      String title, double spent, double budget, String currency) {
    final progress = (budget == 0) ? 0 : (spent / budget);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                "$currency ${spent.toStringAsFixed(2)} / ${budget.toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0).toDouble(),
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                color: progress < 0.8 ? Colors.green : Colors.red,
              )
            ]),
      ),
    );
  }
}
