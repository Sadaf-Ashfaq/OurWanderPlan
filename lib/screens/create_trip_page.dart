import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/trip_model.dart';
import '../services/storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateTripPage extends StatefulWidget {
  final Trip? trip;
  const CreateTripPage({super.key, this.trip});

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final _nameCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.trip != null) {
      _nameCtrl.text = widget.trip!.name;
      _destinationCtrl.text = widget.trip!.destination;
      _budgetCtrl.text = widget.trip!.totalBudget.toString();
      _notesCtrl.text = widget.trip!.notes;
      _startDate = widget.trip!.startDate;
      _endDate = widget.trip!.endDate;
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _saveTrip() async {
  if (_nameCtrl.text.isEmpty ||
      _destinationCtrl.text.isEmpty ||
      _startDate == null ||
      _endDate == null ||
      _budgetCtrl.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.red),
    );
    return;
  }

  setState(() => _saving = true);

  final trip = Trip(
    id: widget.trip?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: _nameCtrl.text,
    destination: _destinationCtrl.text,
    startDate: _startDate!,
    endDate: _endDate!,
    totalBudget: double.parse(_budgetCtrl.text),
    notes: _notesCtrl.text,
  );

  await StorageService.saveTrip(trip);
  await _updateProfileStats(); // ← yeh add karo

  if (!mounted) return;
  setState(() => _saving = false);
  Navigator.pop(context);
}

// Yeh function add karo
Future<void> _updateProfileStats() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final db = FirebaseFirestore.instance;
  final userRef = db.collection('users').doc(uid);

  final allTrips = StorageService.getAllTrips();

  final countries = <String>{};
  final places = <String>{};

  for (final t in allTrips) {
    final destination = t.destination.trim();

    if (destination.contains(',')) {
      // "Lahore, Pakistan" → place = "Lahore", country = "Pakistan"
      final parts = destination.split(',');
      final place = parts[0].trim().toLowerCase();
      final country = parts[parts.length - 1].trim().toLowerCase();
      if (place.isNotEmpty) places.add(place);
      if (country.isNotEmpty) countries.add(country);
    } else {
      // Sirf ek word hai — dono mein add karo
      final val = destination.toLowerCase();
      places.add(val);
      countries.add(val);
    }
  }

  await userRef.update({
    'trips': allTrips.length,
    'countries': countries.length,
    'places': places.length,
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.trip == null ? 'Create Trip' : 'Edit Trip'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip name
            const Text('Trip Name', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g., Summer Vacation',
                prefixIcon: Icon(Icons.edit_outlined, color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 24),

            // Destination
            const Text('Destination', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _destinationCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g., Paris, France',
                prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 24),

            // Start date
            const Text('Start Date', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickStartDate,
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
                      _startDate == null ? 'Pick start date' : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                      style: TextStyle(
                        color: _startDate == null ? AppTheme.textMid : AppTheme.textDark,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // End date
            const Text('End Date', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickEndDate,
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
                      _endDate == null ? 'Pick end date' : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                      style: TextStyle(
                        color: _endDate == null ? AppTheme.textMid : AppTheme.textDark,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Budget
            const Text('Total Budget', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _budgetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g., 5000',
                prefixIcon: Icon(Icons.wallet_outlined, color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 24),

            // Notes
            const Text('Notes (optional)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Add any notes about this trip...',
                prefixIcon: Icon(Icons.note_outlined, color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveTrip,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(widget.trip == null ? 'Create Trip' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _destinationCtrl.dispose();
    _budgetCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}
