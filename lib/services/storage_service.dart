import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_model.dart';
import '../models/expense_model.dart';

class StorageService {
  static late Box<Trip> _tripBox;
  static late Box<Expense> _expenseBox;

  static final _db = FirebaseFirestore.instance;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Firestore references
  static CollectionReference? get _tripsRef => _uid == null
      ? null
      : _db.collection('users').doc(_uid).collection('trips');

  static CollectionReference? get _expensesRef => _uid == null
      ? null
      : _db.collection('users').doc(_uid).collection('expenses');

  // ── INIT ──────────────────────────────────────────────────────
  static Future<void> initHive() async {
    _tripBox = await Hive.openBox<Trip>('trips');
    _expenseBox = await Hive.openBox<Expense>('expenses');
  }

  // ── TRIPS ─────────────────────────────────────────────────────

  // Save trip — Hive + Firestore
  static Future<void> saveTrip(Trip trip) async {
    await _tripBox.put(trip.id, trip);

    if (_tripsRef != null) {
      await _tripsRef!.doc(trip.id).set(trip.toMap());
      await _updateTripCount();
    }
  }

  // Update trip
  static Future<void> updateTrip(Trip trip) async {
    await _tripBox.put(trip.id, trip);

    if (_tripsRef != null) {
      await _tripsRef!.doc(trip.id).set(trip.toMap());
    }
  }

  // Delete trip
  static Future<void> deleteTrip(String tripId) async {
    await _tripBox.delete(tripId);

    if (_tripsRef != null) {
      await _tripsRef!.doc(tripId).delete();
      await _updateTripCount();
    }
  }

  // Get all trips — Hive se (fast local)
  static List<Trip> getAllTrips() {
    return _tripBox.values.toList();
  }

  // Firestore se trips fetch karke Hive sync karo
  static Future<void> syncTripsFromFirestore() async {
    if (_tripsRef == null) return;
    try {
      final snapshot = await _tripsRef!.get();
      await _tripBox.clear();
      for (final doc in snapshot.docs) {
        final trip = Trip.fromMap(doc.data() as Map<String, dynamic>);
        await _tripBox.put(trip.id, trip);
      }
    } catch (e) {
      // Hive data as fallback
    }
  }

  // ── EXPENSES ──────────────────────────────────────────────────

  // Save expense — Hive + Firestore
  static Future<void> saveExpense(Expense expense) async {
    await _expenseBox.put(expense.id, expense);

    if (_expensesRef != null) {
      await _expensesRef!.doc(expense.id).set(expense.toMap());
    }
  }

  // Delete expense
  static Future<void> deleteExpense(String expenseId) async {
    await _expenseBox.delete(expenseId);

    if (_expensesRef != null) {
      await _expensesRef!.doc(expenseId).delete();
    }
  }

  // Get expenses for a trip
  static List<Expense> getExpensesForTrip(String tripId) {
    return _expenseBox.values
        .where((e) => e.tripId == tripId)
        .toList();
  }

  // Firestore se expenses sync karo
  static Future<void> syncExpensesFromFirestore() async {
    if (_expensesRef == null) return;
    try {
      final snapshot = await _expensesRef!.get();
      await _expenseBox.clear();
      for (final doc in snapshot.docs) {
        final expense = Expense.fromMap(doc.data() as Map<String, dynamic>);
        await _expenseBox.put(expense.id, expense);
      }
    } catch (e) {
      // Hive data as fallback
    }
  }

  // ── PROFILE STATS ─────────────────────────────────────────────
  static Future<void> _updateTripCount() async {
    if (_uid == null) return;
    final count = _tripBox.length;
    await _db.collection('users').doc(_uid).update({
      'trips': count,
    });
  }

  // Full sync — login ke baad call karo
  static Future<void> syncAllFromFirestore() async {
    await syncTripsFromFirestore();
    await syncExpensesFromFirestore();
  }
}