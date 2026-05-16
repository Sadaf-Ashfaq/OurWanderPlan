import 'package:hive/hive.dart';

part 'trip_model.g.dart';

@HiveType(typeId: 1)
class Trip extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String destination;

  @HiveField(3)
  late DateTime startDate;

  @HiveField(4)
  late DateTime endDate;

  @HiveField(5)
  late double totalBudget;

  @HiveField(6)
  late String notes;

  @HiveField(7)
  late String generatedItinerary;

  @HiveField(8)
  late String dataHash;

  Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.totalBudget,
    this.notes = '',
    this.generatedItinerary = '',
    this.dataHash = '',
  });

  // Firestore ke liye
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'destination': destination,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalBudget': totalBudget,
      'notes': notes,
      'generatedItinerary': generatedItinerary,
      'dataHash': dataHash,
    };
  }

  static Trip fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'],
      name: map['name'],
      destination: map['destination'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      totalBudget: (map['totalBudget'] as num).toDouble(),
      notes: map['notes'] ?? '',
      generatedItinerary: map['generatedItinerary'] ?? '',
      dataHash: map['dataHash'] ?? '',
    );
  }
}