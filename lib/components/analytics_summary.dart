import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsSummary extends StatefulWidget {
  const AnalyticsSummary({super.key});

  @override
  State<AnalyticsSummary> createState() => _AnalyticsSummaryState();
}

class _AnalyticsSummaryState extends State<AnalyticsSummary> {
  Future<Map<String, dynamic>> _fetchThisMonthData() async {
    final now = DateTime.now();
    final monthFilter =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    try {
      // Get all bookings and filter client-side to handle both old and new MonthBooked formats
      final bookings = await FirebaseFirestore.instance
          .collection('Bookings')
          .get();

      double totalRevenue = 0;
      int totalUnits = 0;

      for (var booking in bookings.docs) {
        final data = booking.data();
        final status = data['Status'] ?? 'Pending';

        // Get MonthBooked or calculate from CheckInDate
        String? bookingMonth = data['MonthBooked'];
        if (bookingMonth == null && data['CheckInDate'] != null) {
          final checkIn = (data['CheckInDate'] as Timestamp).toDate();
          bookingMonth = '${checkIn.year}-${checkIn.month.toString().padLeft(2, '0')}';
        }

        // Only count if matches current month and status is confirmed/completed
        if (bookingMonth == monthFilter && (status == 'Confirmed' || status == 'Completed')) {
          totalRevenue += (data['TotalPrice'] ?? 0).toDouble();
          totalUnits++;
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'totalUnits': totalUnits,
      };
    } catch (e) {
      print('Error fetching analytics summary: $e');
      return {'totalRevenue': 0.0, 'totalUnits': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchThisMonthData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE2E5EE),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: const Center(
              child: SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final totalRevenue = data['totalRevenue'] as double;
        final totalUnits = data['totalUnits'] as int;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE2E5EE),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This Month',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: isMobile ? 2 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.1,
                children: [
                  _buildSummaryMetric(
                    label: 'Units Sold',
                    value: totalUnits.toString(),
                    icon: Icons.shopping_bag,
                    color: Colors.blue,
                  ),
                  _buildSummaryMetric(
                    label: 'Revenue',
                    value: '₱${totalRevenue.toStringAsFixed(0)}',
                    icon: Icons.monetization_on,
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
