import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/expense_model.dart';
import '../services/storage_service.dart';

class AddExpensePage extends StatefulWidget {
  final String tripId;
  const AddExpensePage({super.key, required this.tripId});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _category = 'food';
  DateTime _date = DateTime.now();
  bool _saving = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _saveExpense() async {
    if (_titleCtrl.text.isEmpty || _amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _saving = true);

    final expense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tripId: widget.tripId,
      title: _titleCtrl.text,
      amount: double.parse(_amountCtrl.text),
      category: _category,
      date: _date,
    );

    await StorageService.saveExpense(expense);

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Add Expense'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            const Text('Expense Title', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g., Dinner at restaurant',
                prefixIcon: Icon(Icons.receipt_long_outlined, color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 24),

            // Amount field
            const Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g., 50.00',
                prefixIcon: Icon(Icons.wallet_outlined, color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 24),

            // Category dropdown
            const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFB3E5FC)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _category,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(value: 'food', child: Text(_getCategoryLabel('food'))),
                  DropdownMenuItem(value: 'transport', child: Text(_getCategoryLabel('transport'))),
                  DropdownMenuItem(value: 'hotel', child: Text(_getCategoryLabel('hotel'))),
                  DropdownMenuItem(value: 'activities', child: Text(_getCategoryLabel('activities'))),
                  DropdownMenuItem(value: 'other', child: Text(_getCategoryLabel('other'))),
                ],
                onChanged: (value) => setState(() => _category = value!),
              ),
            ),
            const SizedBox(height: 24),

            // Date picker
            const Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFB3E5FC)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: AppTheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      '${_date.day}/${_date.month}/${_date.year}',
                      style: const TextStyle(fontSize: 16, color: AppTheme.textDark),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveExpense,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Add Expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'food':
        return '🍽️ Food';
      case 'transport':
        return '🚗 Transport';
      case 'hotel':
        return '🏨 Hotel';
      case 'activities':
        return '🎭 Activities';
      default:
        return '📌 Other';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }
}
