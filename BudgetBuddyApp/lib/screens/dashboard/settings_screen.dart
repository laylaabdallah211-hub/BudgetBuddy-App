import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final incomeController = TextEditingController();
  String? selectedCurrency;
  String? selectedBudgetType;

  final List<String> currencies = ["USD", "JOD", "EUR", "GBP", "AED"];
  final List<String> budgetTypes = [
    "50/30/20",
    "Aggressive Saver",
    "Customizable"
  ];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserAuthProvider>(context, listen: false).userModel!;
    incomeController.text = user.monthlyIncome.toString();
    selectedCurrency = user.currency;
    selectedBudgetType = user.budgetType;
  }

  Future<void> _saveChanges() async {
    final auth = Provider.of<UserAuthProvider>(context, listen: false);
    final user = auth.userModel!;

    final income = double.tryParse(incomeController.text.trim()) ??
        user.monthlyIncome;

    double newNeeds = user.needsBudget;
    double newWants = user.wantsBudget;
    double newSavings = user.savingsBudget;

    // Recalculate budgets
    switch (selectedBudgetType) {
      case "50/30/20":
        newNeeds = income * 0.50;
        newWants = income * 0.30;
        newSavings = income * 0.20;
        break;

      case "Aggressive Saver":
        newNeeds = income * 0.30;
        newWants = income * 0.20;
        newSavings = income * 0.50;
        break;

      case "Customizable":
        newNeeds = 0;
        newWants = 0;
        newSavings = 0;
        break;
    }

    await auth.updateUserData({
      "monthlyIncome": income,
      "currency": selectedCurrency,
      "budgetType": selectedBudgetType,
      "needsBudget": newNeeds,
      "wantsBudget": newWants,
      "savingsGoal": newSavings,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Settings updated!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<UserAuthProvider>(context);
    final user = auth.userModel!;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            // ---------- ACCOUNT ----------
            const Text(
              "Account",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(user.email),
              subtitle: const Text("Email"),
            ),

            const SizedBox(height: 25),

            // ---------- BUDGET SETTINGS ----------
            const Text(
              "Budget Settings",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: incomeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Monthly Income",
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),

            const SizedBox(height: 20),

            // ---------- CURRENCY ----------
            DropdownButtonFormField(
              value: selectedCurrency,
              items: currencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => selectedCurrency = v),
              decoration: const InputDecoration(
                labelText: "Currency",
                prefixIcon: Icon(Icons.money),
              ),
            ),

            const SizedBox(height: 20),

            // ---------- BUDGET TYPE ----------
            DropdownButtonFormField(
              value: selectedBudgetType,
              items: budgetTypes
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (v) => setState(() => selectedBudgetType = v),
              decoration: const InputDecoration(
                labelText: "Budget Type",
                prefixIcon: Icon(Icons.pie_chart),
              ),
            ),

            const SizedBox(height: 30),

            // ---------- SAVE BUTTON ----------
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveChanges,
                child: const Text("Save Changes"),
              ),
            ),

            const SizedBox(height: 40),

            // ---------- LOGOUT ----------
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () async {
                  await auth.logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
