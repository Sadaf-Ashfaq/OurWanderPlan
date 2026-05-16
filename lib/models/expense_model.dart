import 'package:hive/hive.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 2)
class Expense extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String tripId;

  @HiveField(2)
  late String title;

  @HiveField(3)
  late double amount;

  @HiveField(4)
  late String category;

  @HiveField(5)
  late DateTime date;

  Expense({
    required this.id,
    required this.tripId,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });
  // Expense model mein yeh methods add karo:

Map<String, dynamic> toMap() {
  return {
    'id': id,
    'tripId': tripId,
    'title': title,
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
  };
}

static Expense fromMap(Map<String, dynamic> map) {
  return Expense(
    id: map['id'],
    tripId: map['tripId'],
    title: map['title'],
    amount: (map['amount'] as num).toDouble(),
    category: map['category'],
    date: DateTime.parse(map['date']),
  );
}
}
