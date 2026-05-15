import 'package:flutter/material.dart';
import '../services/category_service.dart';

class EditCategorySheet extends StatefulWidget {
  final Map<String, dynamic> category;
  final Function onUpdate;

  const EditCategorySheet({
    super.key,
    required this.category,
    required this.onUpdate,
  });

  @override
  State<EditCategorySheet> createState() => _EditCategorySheetState();
}

class _EditCategorySheetState extends State<EditCategorySheet> {
  final CategoryService _categoryService = CategoryService();

  late TextEditingController nameController;
  late TextEditingController budgetController;

  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.category["name"]);
    budgetController = TextEditingController(
        text: (widget.category["budgetedAmount"] ?? 0).toString());
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Edit Category",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Name
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "Category Name",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),

          // Budget
          TextField(
            controller: budgetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Budget Amount",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 10),

          if (errorMessage != null)
            Text(errorMessage!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 10),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _saveChanges,
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
                "Save Changes",
                style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Delete Button
          TextButton(
            onPressed: isLoading ? null : _deleteCategory,
            child: const Text(
              "Delete Category",
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final newName = nameController.text.trim();
    final newBudget = double.tryParse(budgetController.text.trim()) ?? -1;

    try {
      await _categoryService.renameCategory(widget.category["id"], newName);

      await _categoryService.setCategoryBudget(
        categoryId: widget.category["id"],
        newBudget: newBudget,
      );

      widget.onUpdate();
      Navigator.pop(context);
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteCategory() async {
    setState(() => isLoading = true);

    try {
      await _categoryService.deleteCategory(widget.category["id"]);
      widget.onUpdate();
      Navigator.pop(context);
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }
}
