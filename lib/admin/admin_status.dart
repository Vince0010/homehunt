import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminBookingStatus extends StatefulWidget {
  const AdminBookingStatus({super.key});

  @override
  _AdminBookingStatusState createState() => _AdminBookingStatusState();
}

class _AdminBookingStatusState extends State<AdminBookingStatus> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> bookingStream;

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  // Fetch all bookings
  void fetchBookings() {
    bookingStream =
        FirebaseFirestore.instance.collection('Bookings').snapshots();
  }

  // Update or delete booking based on the status
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      if (newStatus == 'Rejected') {
        // Delete booking if rejected
        await FirebaseFirestore.instance
            .collection('Bookings')
            .doc(bookingId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Booking has been rejected and removed.")));
      } else {
        // Update status for other cases (Pending, Confirmed, Completed)
        await FirebaseFirestore.instance
            .collection('Bookings')
            .doc(bookingId)
            .update({'Status': newStatus});
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Booking status updated to $newStatus")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to update status: $e")));
    }
  }

  // Normalize status values to match dropdown items
  String _normalizeStatus(dynamic status) {
    if (status == null) return 'Pending';
    
    String statusStr = status.toString().trim();
    
    // Map common status variations to standard values
    switch (statusStr.toLowerCase()) {
      case 'confirm':
        return 'Confirmed';
      case 'done':
      case 'complete':
        return 'Completed';
      case 'reject':
        return 'Rejected';
      case 'pending':
      case 'pending approval':
        return 'Pending';
      case 'approved':
        return 'Approved';
      default:
        // If it's already a valid value, return it as-is (with proper casing)
        if (['Pending', 'Confirmed', 'Completed', 'Rejected', 'Approved'].contains(statusStr)) {
          return statusStr;
        }
        // Default to Pending if unrecognized
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header with gradient
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF5E60F8),
                    Color(0xFF6D70FA),
                    Color(0xFFE9EBFF),
                  ],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Booking Management',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Manage Bookings',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Title section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Booking Requests',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Bookings list
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: bookingStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text("Error: ${snapshot.error}"),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text(
                        "No booking requests found.",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    DocumentSnapshot<Map<String, dynamic>> booking =
                        snapshot.data!.docs[index];

                    // Convert Firestore Timestamp to DateTime
                    DateTime checkInDate =
                        (booking['CheckInDate'] as Timestamp).toDate();
                    DateTime checkOutDate =
                        (booking['CheckOutDate'] as Timestamp).toDate();

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E5EE), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image
                              booking['ImagePath'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: Image.network(
                                          booking['ImagePath'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: const Color(0xFFE5E7EB),
                                            child: const Icon(Icons.image, size: 50, color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    )
                                  : const Text("No image uploaded",
                                      style: TextStyle(fontSize: 16, color: Colors.black54)),
                              const SizedBox(height: 12),
                              
                              // Booking ID
                              Text(
                                "Booking ID: ${booking['BookingID']}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Date info
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 14, color: Colors.black45),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      "Check-in: ${DateFormat('yyyy-MM-dd').format(checkInDate)}",
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 14, color: Colors.black45),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      "Check-out: ${DateFormat('yyyy-MM-dd').format(checkOutDate)}",
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Price and Status row
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Total Price',
                                          style: TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "₱${booking['TotalPrice']}",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: booking['Status'].toString().toLowerCase() == 'confirmed'
                                          ? Colors.green.shade50
                                          : booking['Status'].toString().toLowerCase() == 'completed'
                                              ? Colors.blue.shade50
                                              : booking['Status'].toString().toLowerCase() == 'pending'
                                                  ? Colors.orange.shade50
                                                  : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      booking['Status'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: booking['Status'].toString().toLowerCase() == 'confirmed'
                                            ? Colors.green.shade700
                                            : booking['Status'].toString().toLowerCase() == 'completed'
                                                ? Colors.blue.shade700
                                                : booking['Status'].toString().toLowerCase() == 'pending'
                                                    ? Colors.orange.shade700
                                                    : Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Status dropdown
                              DropdownButton<String>(
                                value: _normalizeStatus(booking['Status']),
                                items: <String>['Pending', 'Confirmed', 'Completed', 'Rejected', 'Approved']
                                    .map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null &&
                                      newValue != booking['Status']) {
                                    updateBookingStatus(booking.id, newValue);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: snapshot.data!.docs.length,
                ),
              );
            },
          ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
