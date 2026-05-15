import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/user_auth_provider.dart';

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  final incomeController = TextEditingController();
  String selectedBudget = "50/30/20";
  String selectedCurrency = "USD";

  final List<String> currencies = ["USD", "JOD", "EUR", "GBP", "AED"];
  final List<String> budgetTypes = [
    "50/30/20",
    "Aggressive Saver",
    "Customizable"
  ];

  bool isSaving = false;

  Future<void> _saveUserSetup() async {
    final auth = Provider.of<UserAuthProvider>(context, listen: false);
    final uid = auth.firebaseUser!.uid;

    final income = double.tryParse(incomeController.text.trim()) ?? 0;

    double needs = 0, wants = 0, savings = 0;

    // ----------------------------------------------
    // CALCULATE GROUP BUDGETS BASED ON BUDGET TYPE
    // ----------------------------------------------
    switch (selectedBudget) {
      case "50/30/20":
        needs = income * 0.50;
        wants = income * 0.30;
        savings = income * 0.20;
        break;

      case "Aggressive Saver":
      // Correct formula: 30% needs, 20% wants, 50% savings
        needs = income * 0.30;
        wants = income * 0.20;
        savings = income * 0.50;
        break;

      case "Customizable":
        needs = 0;
        wants = 0;
        savings = 0;
        break;
    }

    setState(() => isSaving = true);

    // ----------------------------------------------
    // UPDATE USER MODEL IN FIRESTORE
    // ----------------------------------------------
    await auth.updateUserData({
      "monthlyIncome": income,
      "budgetType": selectedBudget,
      "currency": selectedCurrency,
      "needsBudget": needs,
      "wantsBudget": wants,
      "savingsGoal": savings,
      "setupComplete": true,
    });

    // ----------------------------------------------
    // CREATE GROUP SPENT TRACKING (NEEDED FOR DASHBOARD)
    // ----------------------------------------------
    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("budget")
        .doc("current")
        .set({
      "needsSpent": 0.0,
      "wantsSpent": 0.0,
      "savingsSpent": 0.0,
    }, SetOptions(merge: true));

    setState(() => isSaving = false);

    // NAVIGATION handled automatically by AppWrapper
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Initial Setup")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              "Set up your budget",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),

            // MONTHLY INCOME
            TextField(
              controller: incomeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Monthly Income",
              ),
            ),
            const SizedBox(height: 20),

            // BUDGET TYPE SELECT
            DropdownButtonFormField(
              value: selectedBudget,
              items: budgetTypes
                  .map(
                    (b) => DropdownMenuItem(
                  value: b,
                  child: Text(b),
                ),
              )
                  .toList(),
              onChanged: (v) => setState(() => selectedBudget = v!),
              decoration: const InputDecoration(labelText: "Budget Type"),
            ),
            const SizedBox(height: 20),

            // CURRENCY SELECT
            DropdownButtonFormField(
              value: selectedCurrency,
              items: currencies
                  .map(
                    (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c),
                ),
              )
                  .toList(),
              onChanged: (v) => setState(() => selectedCurrency = v!),
              decoration: const InputDecoration(labelText: "Currency"),
            ),
            const SizedBox(height: 40),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isSaving ? null : _saveUserSetup,
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save & Continue"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
