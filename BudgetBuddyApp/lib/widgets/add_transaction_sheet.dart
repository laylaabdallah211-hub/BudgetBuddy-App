import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/transaction_service.dart';

class AddTransactionSheet extends StatefulWidget {
  final Function onAdd;

  const AddTransactionSheet({super.key, required this.onAdd});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final TransactionService _txService = TransactionService();

  String type = "expense";
  String? selectedCategoryId;
  String? selectedGroup;

  final descriptionController = TextEditingController();
  final payeeController = TextEditingController();
  final amountController = TextEditingController();

  List<Map<String, dynamic>> categories = [];
  bool loadingCats = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("categories")
        .get();

    categories = snap.docs
        .map((d) => {
      "id": d.id,
      ...d.data(),
    })
        .toList();

    setState(() => loadingCats = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              "Add Transaction",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // Transaction Type Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Expense"),
                  selected: type == "expense",
                  onSelected: (_) => setState(() => type = "expense"),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Income"),
                  selected: type == "income",
                  onSelected: (_) => setState(() => type = "income"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: payeeController,
              decoration: const InputDecoration(
                labelText: "Payee",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            if (type == "expense") _buildCategoryDropdown(),

            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(errorMessage!,
                    style: const TextStyle(color: Colors.red)),
              ),

            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.blue.shade100,
                  foregroundColor: Colors.blue.shade900,
                ),
                child: const Text(
                  "Add Transaction",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    if (loadingCats) {
      return const Center(child: CircularProgressIndicator());
    }

    return DropdownButtonFormField<String>(
      value: selectedCategoryId,
      decoration: const InputDecoration(
        labelText: "Category",
        border: OutlineInputBorder(),
      ),
      items: categories.map<DropdownMenuItem<String>>((c) {
        return DropdownMenuItem<String>(
          value: c["id"] as String,
          child: Text("${c['name']} (${c['group']})"),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedCategoryId = value;
          selectedGroup = categories.firstWhere((c) => c["id"] == value)["group"];
        });
      },
    );
  }

  Future<void> _save() async {
    final description = descriptionController.text.trim();
    final payee = payeeController.text.trim();
    final amount = double.tryParse(amountController.text.trim()) ?? -1;

    if (description.isEmpty || payee.isEmpty || amount <= 0) {
      setState(() => errorMessage = "Please fill out all fields.");
      return;
    }

    if (type == "expense" && selectedCategoryId == null) {
      setState(() => errorMessage = "Please select a category.");
      return;
    }

    try {
      if (type == "expense") {
        await _txService.addExpense(
          description: description,
          payee: payee,
          amount: amount,
          categoryId: selectedCategoryId!,
          group: selectedGroup!,
          date: DateTime.now(),
        );
      } else {
        await _txService.addIncome(
          description: description,
          payee: payee,
          amount: amount,
          date: DateTime.now(),
        );
      }

      widget.onAdd();
      Navigator.pop(context);
    } catch (e) {
      setState(() => errorMessage = e.toString());
    }
  }
}
