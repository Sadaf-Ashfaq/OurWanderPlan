import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme.dart';
import '../models/trip_model.dart';
import '../models/expense_model.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import 'create_trip_page.dart';
import 'add_expense_page.dart';

class TripDetailPage extends StatefulWidget {
  final Trip trip;
  const TripDetailPage({super.key, required this.trip});

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  late Trip _trip;
  bool _generatingItinerary = false;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  int _daysCount() {
    return _trip.endDate.difference(_trip.startDate).inDays;
  }

  double _getTotalSpent() {
    final expenses = StorageService.getExpensesForTrip(_trip.id);
    return expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  double _getRemaining() {
    return _trip.totalBudget - _getTotalSpent();
  }

  Color _getBudgetColor() {
    final spent = _getTotalSpent();
    final ratio = spent / _trip.totalBudget;
    if (ratio <= 0.7) return Colors.green;
    if (ratio < 1.0) return Colors.orange;
    return Colors.red;
  }

  void _deleteTrip() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text('Are you sure you want to delete this trip? All expenses will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final expenses = StorageService.getExpensesForTrip(_trip.id);
              for (var expense in expenses) {
                await StorageService.deleteExpense(expense.id);
              }
              await StorageService.deleteTrip(_trip.id);
              if (!mounted) return;
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editTrip() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateTripPage(trip: _trip)),
    ).then((_) => setState(() {}));
  }

  void _generateItinerary() async {
    setState(() => _generatingItinerary = true);

    final days = _trip.endDate.difference(_trip.startDate).inDays;
    final itinerary = await AiService.generateItinerary(_trip.destination, days, _trip.totalBudget);

    _trip.generatedItinerary = itinerary;
    await StorageService.updateTrip(_trip);

    if (!mounted) return;
    setState(() => _generatingItinerary = false);
  }

  void _deleteExpense(String expenseId) async {
    await StorageService.deleteExpense(expenseId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final expenses = StorageService.getExpensesForTrip(_trip.id);
    final totalSpent = _getTotalSpent();
    final remaining = _getRemaining();
    final isOverBudget = totalSpent > _trip.totalBudget;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Trip Details'),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _editTrip),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _deleteTrip),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip name
            Text(
              _trip.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),

            // Destination & dates
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _trip.destination,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textMid),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.textMid),
                const SizedBox(width: 6),
                Text(
                  '${_formatDate(_trip.startDate)} - ${_formatDate(_trip.endDate)} (${_daysCount()} days)',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textMid),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Notes
            if (_trip.notes.isNotEmpty) ...[
              const Text('Notes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                ),
                child: Text(_trip.notes, style: const TextStyle(fontSize: 13, color: AppTheme.textMid, height: 1.5)),
              ),
              const SizedBox(height: 24),
            ],

            // AI Itinerary section
            const Text('AI Itinerary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 12),

            if (_trip.generatedItinerary.isEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generatingItinerary ? null : _generateItinerary,
                  icon: _generatingItinerary ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
                  label: Text(_generatingItinerary ? 'Generating...' : 'Generate AI Itinerary'),
                ),
              )
            else if (_trip.generatedItinerary.startsWith('API Error') || _trip.generatedItinerary.startsWith('Network error') || _trip.generatedItinerary.startsWith('Failed'))
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _trip.generatedItinerary,
                            style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _trip.generatedItinerary = '';
                            StorageService.updateTrip(_trip);
                            setState(() {});
                          },
                          child: Icon(Icons.refresh, size: 18, color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Generated Itinerary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                        GestureDetector(
                          onTap: () {
                            _trip.generatedItinerary = '';
                            StorageService.updateTrip(_trip);
                            setState(() {});
                          },
                          child: const Icon(Icons.refresh, size: 18, color: AppTheme.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 300,
                      child: SingleChildScrollView(
                        child: MarkdownBody(
                          data: _trip.generatedItinerary,
                          styleSheet: MarkdownStyleSheet(
                            h2: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                            p: const TextStyle(fontSize: 13.5, color: AppTheme.textDark, height: 1.5),
                            strong: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark),
                            listBullet: const TextStyle(color: AppTheme.primary),
                            blockSpacing: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Budget section
            const Text('Budget', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  // Total budget
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Budget', style: TextStyle(fontSize: 13, color: AppTheme.textMid)),
                      Text('\$${_trip.totalBudget.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Total spent
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Spent', style: TextStyle(fontSize: 13, color: AppTheme.textMid)),
                      Text('\$${totalSpent.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Remaining
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Remaining', style: TextStyle(fontSize: 13, color: AppTheme.textMid)),
                      Text(
                        '\$${remaining.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isOverBudget ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress indicator
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (totalSpent / _trip.totalBudget).clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(_getBudgetColor()),
                    ),
                  ),

                  // Over budget alert
                  if (isOverBudget) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_rounded, size: 16, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Over budget!',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Expenses section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Expenses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddExpensePage(tripId: _trip.id)),
                    ).then((_) => setState(() {}));
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Expenses list
            if (expenses.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textMid.withOpacity(0.3)),
                      const SizedBox(height: 8),
                      const Text('No expenses yet', style: TextStyle(fontSize: 14, color: AppTheme.textMid)),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  return Dismissible(
                    key: Key(expense.id),
                    onDismissed: (_) => _deleteExpense(expense.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red.shade100,
                      child: Icon(Icons.delete, color: Colors.red.shade700),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(expense.category).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getCategoryLabel(expense.category),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getCategoryColor(expense.category),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Title and date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expense.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(expense.date),
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMid),
                                ),
                              ],
                            ),
                          ),

                          // Amount
                          Text(
                            '\$${expense.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'hotel':
        return Colors.indigo;
      case 'activities':
        return Colors.green;
      default:
        return Colors.grey;
    }
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
}
