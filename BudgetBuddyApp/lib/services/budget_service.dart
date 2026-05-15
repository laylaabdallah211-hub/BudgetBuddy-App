import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _userRef =>
      _firestore.collection("users").doc(_uid);

  DocumentReference<Map<String, dynamic>> get _summaryRef =>
      _firestore.collection("users").doc(_uid).collection("budget").doc("current");

  CollectionReference<Map<String, dynamic>> get _catRef =>
      _firestore.collection("users").doc(_uid).collection("categories");

  // ------------------------------------------------------------
  // 1) Get onboarding data (group budgets + income)
  // ------------------------------------------------------------
  Future<Map<String, dynamic>> getUserOnboardingData() async {
    final doc = await _userRef.get();

    if (!doc.exists) {
      return {
        "monthlyIncome": 0.0,
        "needsBudget": 0.0,
        "wantsBudget": 0.0,
        "savingsGoal": 0.0,
        "currency": "USD",
        "budgetType": "Customizable",
      };
    }

    final data = doc.data()!;

    return {
      "monthlyIncome": (data["monthlyIncome"] ?? 0).toDouble(),
      "needsBudget": (data["needsBudget"] ?? 0).toDouble(),
      "wantsBudget": (data["wantsBudget"] ?? 0).toDouble(),
      "savingsGoal": (data["savingsGoal"] ?? 0).toDouble(),
      "currency": data["currency"] ?? "USD",
      "budgetType": data["budgetType"] ?? "Customizable",
    };
  }

  // ------------------------------------------------------------
  // 2) Get group summary (assigned, unassigned, spent)
  // ------------------------------------------------------------
  Future<Map<String, dynamic>> getBudgetSummary() async {
    final doc = await _summaryRef.get();

    if (!doc.exists) {
      return {
        "needsAssigned": 0.0,
        "needsUnassigned": 0.0,
        "needsSpent": 0.0,
        "wantsAssigned": 0.0,
        "wantsUnassigned": 0.0,
        "wantsSpent": 0.0,
        "savingsAssigned": 0.0,
        "savingsUnassigned": 0.0,
        "savingsSpent": 0.0,
      };
    }

    final data = doc.data()!;
    return {
      "needsAssigned": (data["needsAssigned"] ?? 0).toDouble(),
      "needsUnassigned": (data["needsUnassigned"] ?? 0).toDouble(),
      "needsSpent": (data["needsSpent"] ?? 0).toDouble(),
      "wantsAssigned": (data["wantsAssigned"] ?? 0).toDouble(),
      "wantsUnassigned": (data["wantsUnassigned"] ?? 0).toDouble(),
      "wantsSpent": (data["wantsSpent"] ?? 0).toDouble(),
      "savingsAssigned": (data["savingsAssigned"] ?? 0).toDouble(),
      "savingsUnassigned": (data["savingsUnassigned"] ?? 0).toDouble(),
      "savingsSpent": (data["savingsSpent"] ?? 0).toDouble(),
    };
  }

  // ------------------------------------------------------------
  // 3) Recalculate Assigned + Unassigned totals for a group
  // ------------------------------------------------------------
  Future<void> recalcGroupTotals(String group) async {
    final userDoc = await _userRef.get();
    final groupBudget = (userDoc[group == "Needs" ? "needsBudget"
        : group == "Wants" ? "wantsBudget"
        : "savingsGoal"])
        .toDouble();

    // Fetch all categories for the group
    final catSnap = await _catRef.where("group", isEqualTo: group).get();

    double assigned = 0.0;
    for (final c in catSnap.docs) {
      assigned += (c["budgetedAmount"] ?? 0.0).toDouble();
    }

    final unassigned = groupBudget - assigned;

    // Update in summary doc
    final summaryFieldAssigned =
    group == "Needs" ? "needsAssigned" :
    group == "Wants" ? "wantsAssigned" :
    "savingsAssigned";

    final summaryFieldUnassigned =
    group == "Needs" ? "needsUnassigned" :
    group == "Wants" ? "wantsUnassigned" :
    "savingsUnassigned";

    await _summaryRef.set({
      summaryFieldAssigned: assigned,
      summaryFieldUnassigned: unassigned,
    }, SetOptions(merge: true));
  }

  // ------------------------------------------------------------
  // 4) Update group spending when an expense is added
  // ------------------------------------------------------------
  Future<void> updateGroupSpent({
    required String group,
    required double amount,
  }) async {
    final summaryDoc = await _summaryRef.get();

    double needsSpent = (summaryDoc["needsSpent"] ?? 0).toDouble();
    double wantsSpent = (summaryDoc["wantsSpent"] ?? 0).toDouble();
    double savingsSpent = (summaryDoc["savingsSpent"] ?? 0).toDouble();

    if (group == "Needs") needsSpent += amount;
    if (group == "Wants") wantsSpent += amount;
    if (group == "Savings") savingsSpent += amount;

    await _summaryRef.set({
      "needsSpent": needsSpent,
      "wantsSpent": wantsSpent,
      "savingsSpent": savingsSpent,
    }, SetOptions(merge: true));
  }

  // ------------------------------------------------------------
  // 5) Update group budgets when monthly income changes
  // (Needs/Wants/Savings limits only — categories unchanged)
  // ------------------------------------------------------------
  Future<void> updateMonthlyIncome({
    required double newIncome,
    required String budgetType,
  }) async {
    double needs = 0.0;
    double wants = 0.0;
    double savings = 0.0;

    if (budgetType == "50/30/20 Rule") {
      needs = newIncome * 0.50;
      wants = newIncome * 0.30;
      savings = newIncome * 0.20;
    }
    else if (budgetType == "Aggressive Saver") {
      needs = newIncome * 0.30;
      wants = newIncome * 0.20;
      savings = newIncome * 0.50;
    }
    else {
      // Customizable → keep old percentages based on ratio
      final doc = await _userRef.get();
      final oldIncome = (doc["monthlyIncome"] ?? 1).toDouble();

      final oldNeeds = (doc["needsBudget"] ?? 0).toDouble();
      final oldWants = (doc["wantsBudget"] ?? 0).toDouble();
      final oldSavings = (doc["savingsGoal"] ?? 0).toDouble();

      final ratio = newIncome / oldIncome;

      needs = oldNeeds * ratio;
      wants = oldWants * ratio;
      savings = oldSavings * ratio;
    }

    // Save
    await _userRef.update({
      "monthlyIncome": newIncome,
      "needsBudget": needs,
      "wantsBudget": wants,
      "savingsGoal": savings,
    });

    // Recalc assigned/unassigned for each group
    await recalcGroupTotals("Needs");
    await recalcGroupTotals("Wants");
    await recalcGroupTotals("Savings");
  }
}
