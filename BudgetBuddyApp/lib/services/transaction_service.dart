import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'budget_service.dart';
import 'category_service.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BudgetService _budgetService = BudgetService();
  final CategoryService _categoryService = CategoryService();

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _txRef =>
      _firestore.collection("users").doc(_uid).collection("transactions");

  CollectionReference<Map<String, dynamic>> get _catRef =>
      _firestore.collection("users").doc(_uid).collection("categories");

  DocumentReference<Map<String, dynamic>> get _summaryRef =>
      _firestore.collection("users").doc(_uid).collection("budget").doc("current");

  // ------------------------------------------------------------------
  // 1) ADD EXPENSE
  // ------------------------------------------------------------------
  Future<void> addExpense({
    required String description,
    required String payee,
    required double amount,
    required String categoryId,
    required String group,
    required DateTime date,
    String flag = "none",
  }) async {
    // 1. Create transaction record
    final doc = _txRef.doc();

    await doc.set({
      "id": doc.id,
      "type": "expense",
      "description": description,
      "payee": payee,
      "amount": amount,
      "categoryId": categoryId,
      "group": group,                          // Needs / Wants / Savings
      "flag": flag,
      "date": date.toIso8601String(),
      "createdAt": FieldValue.serverTimestamp(),
    });

    // 2. Update category spent + available
    await _updateCategoryAfterExpense(categoryId, amount);

    // 3. Update group-level spent totals
    await _budgetService.updateGroupSpent(
      group: group,
      amount: amount,
    );
  }

  // ------------------------------------------------------------------
  // Update category spent / available after expense
  // ------------------------------------------------------------------
  Future<void> _updateCategoryAfterExpense(
      String categoryId, double amount) async {
    final doc = await _catRef.doc(categoryId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final spent = (data["spentAmount"] ?? 0.0).toDouble();
    final budgeted = (data["budgetedAmount"] ?? 0.0).toDouble();

    final newSpent = spent + amount;
    final newAvailable = (budgeted - newSpent).clamp(0, double.infinity);

    await _catRef.doc(categoryId).update({
      "spentAmount": newSpent,
      "availableAmount": newAvailable,
    });
  }

  // ------------------------------------------------------------------
  // 2) ADD INCOME (Informational Only)
  //
  // Income does NOT affect budgets or categories in your system.
  // ------------------------------------------------------------------
  Future<void> addIncome({
    required String description,
    required String payee,
    required double amount,
    required DateTime date,
  }) async {
    final doc = _txRef.doc();

    await doc.set({
      "id": doc.id,
      "type": "income",
      "description": description,
      "payee": payee,
      "amount": amount,
      "flag": "none",
      "date": date.toIso8601String(),
      "createdAt": FieldValue.serverTimestamp(),
    });

    // No further updates needed – income does not modify budgets.
  }

  // ------------------------------------------------------------------
  // 3) DELETE TRANSACTION
  // ------------------------------------------------------------------
  Future<void> deleteTransaction(String txId) async {
    final doc = await _txRef.doc(txId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final String type = data["type"];

    // Remove from transactions list
    await _txRef.doc(txId).delete();

    // Undo expense effects
    if (type == "expense") {
      await _undoExpenseEffects(data);
    }
  }

  // ------------------------------------------------------------------
  // Undo expense (restore category + summary)
  // ------------------------------------------------------------------
  Future<void> _undoExpenseEffects(Map<String, dynamic> data) async {
    final String categoryId = data["categoryId"];
    final String group = data["group"];
    final double amount = (data["amount"] ?? 0.0).toDouble();

    // Restore category spent + available
    final cat = await _catRef.doc(categoryId).get();
    if (cat.exists) {
      final c = cat.data()!;
      final spent = (c["spentAmount"] ?? 0.0).toDouble();
      final budgeted = (c["budgetedAmount"] ?? 0.0).toDouble();

      final newSpent = (spent - amount).clamp(0, double.infinity);
      final newAvailable = (budgeted - newSpent).clamp(0, double.infinity);

      await _catRef.doc(categoryId).update({
        "spentAmount": newSpent,
        "availableAmount": newAvailable,
      });
    }

    // Restore group-level spent totals
    final summary = await _summaryRef.get();
    double needsSpent = (summary["needsSpent"] ?? 0).toDouble();
    double wantsSpent = (summary["wantsSpent"] ?? 0).toDouble();
    double savingsSpent = (summary["savingsSpent"] ?? 0).toDouble();

    if (group == "Needs") needsSpent -= amount;
    if (group == "Wants") wantsSpent -= amount;
    if (group == "Savings") savingsSpent -= amount;

    await _summaryRef.set({
      "needsSpent": needsSpent,
      "wantsSpent": wantsSpent,
      "savingsSpent": savingsSpent,
    }, SetOptions(merge: true));
  }
}
