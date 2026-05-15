import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _catRef =>
      _firestore.collection("users").doc(_uid).collection("categories");

  DocumentReference<Map<String, dynamic>> get _summaryRef =>
      _firestore.collection("users").doc(_uid).collection("budget").doc("current");

  DocumentReference<Map<String, dynamic>> get _userRef =>
      _firestore.collection("users").doc(_uid);

  // ------------------------------------------------------------------
  // 1) Add Category
  // ------------------------------------------------------------------
  Future<void> addCategory({
    required String name,
    required String group,
    required String icon,
    double initialBudget = 0.0,
  }) async {
    // Fetch group budget limits first
    final userDoc = await _userRef.get();
    final groupBudget = userDoc[group == "Needs" ? "needsBudget"
        : group == "Wants" ? "wantsBudget"
        : "savingsGoal"];

    // Fetch current assigned amount
    final summaryDoc = await _summaryRef.get();
    final assigned = summaryDoc[group == "Needs" ? "needsAssigned"
        : group == "Wants" ? "wantsAssigned"
        : "savingsAssigned"] ?? 0.0;

    // Validation: don't exceed limit
    if (assigned + initialBudget > groupBudget) {
      throw Exception("You cannot assign more than your $group budget.");
    }

    // Create category
    final doc = _catRef.doc();
    await doc.set({
      "id": doc.id,
      "name": name,
      "group": group,
      "icon": icon,
      "budgetedAmount": initialBudget,
      "spentAmount": 0.0,
      "availableAmount": initialBudget,
    });

    // Update summary: assigned/unassigned
    await _updateGroupTotals(group);
  }

  // ------------------------------------------------------------------
  // 2) Update Category Name
  // ------------------------------------------------------------------
  Future<void> renameCategory(String categoryId, String newName) async {
    await _catRef.doc(categoryId).update({
      "name": newName,
    });
  }

  // ------------------------------------------------------------------
  // 3) Set Category Budget (VALIDATION INCLUDED)
  // ------------------------------------------------------------------
  Future<void> setCategoryBudget({
    required String categoryId,
    required double newBudget,
  }) async {
    final catDoc = await _catRef.doc(categoryId).get();
    if (!catDoc.exists) return;

    final data = catDoc.data()!;
    final String group = data["group"];
    final double spent = data["spentAmount"] ?? 0.0;

    // Cannot set a budget lower than amount already spent
    if (newBudget < spent) {
      throw Exception("Budget cannot be lower than the amount already spent.");
    }

    // Fetch group budget limit
    final userDoc = await _userRef.get();
    final groupBudget = userDoc[group == "Needs" ? "needsBudget"
        : group == "Wants" ? "wantsBudget"
        : "savingsGoal"];

    // Fetch current assigned (minus old category budget)
    final summaryDoc = await _summaryRef.get();
    final currentAssigned = summaryDoc[group == "Needs" ? "needsAssigned"
        : group == "Wants" ? "wantsAssigned"
        : "savingsAssigned"] ?? 0.0;

    final oldBudget = (data["budgetedAmount"] ?? 0.0);
    final newAssignedTotal = currentAssigned - oldBudget + newBudget;

    // Validate group limit
    if (newAssignedTotal > groupBudget) {
      final remaining = groupBudget - (currentAssigned - oldBudget);
      throw Exception("You only have ${remaining.toStringAsFixed(2)} left to assign for $group.");
    }

    // Update category
    await _catRef.doc(categoryId).update({
      "budgetedAmount": newBudget,
      "availableAmount": newBudget - spent,
    });

    // Update group totals
    await _updateGroupTotals(group);
  }

  // ------------------------------------------------------------------
  // 4) Delete Category (Return budget to unassigned)
  // ------------------------------------------------------------------
  Future<void> deleteCategory(String categoryId) async {
    final catDoc = await _catRef.doc(categoryId).get();
    if (!catDoc.exists) return;

    final data = catDoc.data()!;
    final String group = data["group"];
    final double budgeted = (data["budgetedAmount"] ?? 0.0);

    // Delete the category
    await _catRef.doc(categoryId).delete();

    // Recalculate group totals
    await _updateGroupTotals(group);

    print("Deleted category and restored $budgeted back to unassigned.");
  }

  // ------------------------------------------------------------------
  // 5) Recalculate assigned/unassigned for group
  // ------------------------------------------------------------------
  Future<void> _updateGroupTotals(String group) async {
    // Fetch group budget
    final userDoc = await _userRef.get();
    final groupBudget = (userDoc[group == "Needs" ? "needsBudget"
        : group == "Wants" ? "wantsBudget"
        : "savingsGoal"])
        .toDouble();

    // Sum category budgets
    final catSnap = await _catRef.where("group", isEqualTo: group).get();

    double assigned = 0.0;
    for (final c in catSnap.docs) {
      assigned += (c["budgetedAmount"] ?? 0.0).toDouble();
    }

    final unassigned = groupBudget - assigned;

    // Update summary document
    await _summaryRef.set({
      group == "Needs" ? "needsAssigned"
          : group == "Wants" ? "wantsAssigned"
          : "savingsAssigned" : assigned,
      group == "Needs" ? "needsUnassigned"
          : group == "Wants" ? "wantsUnassigned"
          : "savingsUnassigned" : unassigned,
    }, SetOptions(merge: true));
  }
}
