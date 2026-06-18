import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';

class ManageCategoriesScreen extends StatelessWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, _) {
        final income = provider.categoriesForType(TransactionType.income);
        final expense = provider.categoriesForType(TransactionType.expense);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader(
              title: 'Income Categories',
              onAdd: () => _openEditor(context, TransactionType.income),
            ),
            ...income.map((c) => _CategoryTile(category: c)),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Expense Categories',
              onAdd: () => _openEditor(context, TransactionType.expense),
            ),
            ...expense.map((c) => _CategoryTile(category: c)),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  void _openEditor(BuildContext context, TransactionType type, [BudgetCategory? existing]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryEditorScreen(type: type, existing: existing),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onAdd});

  final String title;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final BudgetCategory category;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<BudgetProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category.color.withValues(alpha: 0.15),
          child: Icon(categoryIconData(category.icon), color: category.color, size: 20),
        ),
        title: Text(category.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryEditorScreen(
                    type: category.type,
                    existing: category,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.expense),
              onPressed: () async {
                final error = await provider.deleteCategory(category.id);
                if (context.mounted && error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: AppColors.expense),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryEditorScreen extends StatefulWidget {
  const CategoryEditorScreen({super.key, required this.type, this.existing});

  final TransactionType type;
  final BudgetCategory? existing;

  @override
  State<CategoryEditorScreen> createState() => _CategoryEditorScreenState();
}

class _CategoryEditorScreenState extends State<CategoryEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late String _icon;
  late int _colorValue;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _icon = existing.icon;
      _colorValue = existing.colorValue;
    } else {
      _icon = categoryIconOptions.first;
      _colorValue = widget.type == TransactionType.income ? 0xFF22C55E : 0xFFEF4444;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Category' : 'New Category'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Category Name'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 20),
            const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categoryIconOptions.map((icon) {
                final selected = icon == _icon;
                return GestureDetector(
                  onTap: () => setState(() => _icon = icon),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? Color(_colorValue).withValues(alpha: 0.2)
                          : AppColors.border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: selected
                          ? Border.all(color: Color(_colorValue), width: 2)
                          : null,
                    ),
                    child: Icon(categoryIconData(icon), size: 22),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                0xFF6366F1,
                0xFF22C55E,
                0xFFEF4444,
                0xFFF59E0B,
                0xFF3B82F6,
                0xFF8B5CF6,
                0xFF14B8A6,
                0xFFEC4899,
              ].map((color) {
                final selected = color == _colorValue;
                return GestureDetector(
                  onTap: () => setState(() => _colorValue = color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: AppColors.textPrimary, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(isEditing ? 'Update Category' : 'Create Category'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<BudgetProvider>();
    final category = BudgetCategory(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      type: widget.type,
      icon: _icon,
      colorValue: _colorValue,
    );

    if (isEditing) {
      await provider.updateCategory(category);
    } else {
      await provider.addCategory(category);
    }

    if (mounted) Navigator.pop(context);
  }
}
