import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/trip_model.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;

  const TripCard({super.key, required this.trip, required this.onTap});

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  int _daysCount() {
    return trip.endDate.difference(trip.startDate).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip name
              Text(
                trip.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),

              // Destination with icon
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      trip.destination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMid,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Date range
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textMid),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)} (${_daysCount()} days)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMid,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Budget with wallet icon
              Row(
                children: [
                  const Icon(Icons.wallet_outlined, size: 14, color: AppTheme.accent),
                  const SizedBox(width: 6),
                  Text(
                    '\$${trip.totalBudget.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
