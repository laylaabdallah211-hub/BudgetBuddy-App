import 'package:flutter/material.dart';
import '../services/category_service.dart';

class AddCategorySheet extends StatefulWidget {
  final String group;        // Needs / Wants / Savings
  final Function onAdd;      // Callback to refresh dashboard

  const AddCategorySheet({
    super.key,
    required this.group,
    required this.onAdd,
  });

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  final CategoryService _categoryService = CategoryService();

  final nameController = TextEditingController();
  final budgetController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            "Add ${widget.group} Category",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Name Field
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "Category Name",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),

          // Budget Field
          TextField(
            controller: budgetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Budget Amount",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),

          if (errorMessage != null)
            Text(errorMessage!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 10),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _saveCategory,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.blue.shade100,
                foregroundColor: Colors.blue.shade900,
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                "Save Category",
                style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCategory() async {
    final name = nameController.text.trim();
    final budgetString = budgetController.text.trim();
    final budget = double.tryParse(budgetString) ?? -1;

    if (name.isEmpty || budget < 0) {
      setState(() => errorMessage = "Enter a valid name and budget.");
      return;
    }

    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    try {
      await _categoryService.addCategory(
        name: name,
        group: widget.group,
        icon: "folder",
        initialBudget: budget,
      );

      widget.onAdd(); // Refresh dashboard
      Navigator.pop(context);
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }
}
