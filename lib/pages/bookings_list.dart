import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'booking_confirmation_dialog.dart';

class BookingsListPage extends StatefulWidget {
  const BookingsListPage({super.key});

  @override
  State<BookingsListPage> createState() => _BookingsListPageState();
}

class _BookingsListPageState extends State<BookingsListPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getBookingsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('Bookings')
        .where('UserID', isEqualTo: user.uid)
        .snapshots();
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Bookings')
          .doc(bookingId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking canceled successfully.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to cancel booking: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = FirebaseAuth.instance.currentUser;

    // If user is not logged in
    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: const Text(
            'My Bookings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
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
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 24),
                Text(
                  'Login Required',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You must be logged in to view your bookings.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // User is logged in - show bookings
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
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
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Active Bookings Tab
          _buildActiveBookingsTab(),
          // History Tab
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildActiveBookingsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      key: const ValueKey('active_bookings'),
      stream: getBookingsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Active Bookings',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Start booking your favorite rooms now!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Filter and sort pending bookings by latest first
        final pendingBookings = snapshot.data!.docs
            .where((doc) => doc['Status'] == 'Pending')
            .toList();
        
        // Sort by BookingDate descending (latest first)
        pendingBookings.sort((a, b) {
          final dateA = (a['BookingDate'] as Timestamp).toDate();
          final dateB = (b['BookingDate'] as Timestamp).toDate();
          return dateB.compareTo(dateA);
        });

        if (pendingBookings.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.green.shade400,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'All Caught Up!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No pending bookings. Check History for completed bookings.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingBookings.length,
          itemBuilder: (context, index) {
            final booking = pendingBookings[index];
            return _buildBookingCard(booking, context);
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      key: const ValueKey('history_bookings'),
      stream: getBookingsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Booking History',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Filter and sort completed bookings by latest first
        final historyBookings = snapshot.data!.docs
            .where((doc) =>
                doc['Status'] == 'Confirmed' ||
                doc['Status'] == 'Accepted' ||
                doc['Status'] == 'Rejected' ||
                doc['Status'] == 'Approved' ||
                doc['Status'] == 'Completed')
            .toList();
        
        // Sort by BookingDate descending (latest first)
        historyBookings.sort((a, b) {
          final dateA = (a['BookingDate'] as Timestamp).toDate();
          final dateB = (b['BookingDate'] as Timestamp).toDate();
          return dateB.compareTo(dateA);
        });

        if (historyBookings.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Booking History',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: historyBookings.length,
          itemBuilder: (context, index) {
            final booking = historyBookings[index];
            return _buildHistoryBookingCard(booking, context);
          },
        );
      },
    );
  }

  Widget _buildBookingCard(
      DocumentSnapshot<Map<String, dynamic>> booking, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking['RoomTitle'] ?? 'Unknown Room',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Pending',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Category', booking['RoomCategory'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Check-in',
              DateFormat('MMM dd, yyyy').format(booking['CheckInDate'].toDate()),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Check-out',
              DateFormat('MMM dd, yyyy').format(booking['CheckOutDate'].toDate()),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Total Price',
              '₱${booking['TotalPrice'].toStringAsFixed(2)}',
              isPrice: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _cancelBooking(booking.id);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Colors.red,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => BookingConfirmationDialog(
                            bookingId: booking['BookingID'],
                            checkInDate: booking['CheckInDate'].toDate(),
                            checkOutDate: booking['CheckOutDate'].toDate(),
                            totalPrice: booking['TotalPrice'],
                            roomTitle: booking['RoomTitle'] ?? 'Unknown Room',
                            roomCategory: booking['RoomCategory'] ?? 'Unknown',
                            lengthOfStay: booking['LengthOfStay'] ?? 0,
                            showConfirmation: false,
                          ),
                        );
                      },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5E60F8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'View QR',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryBookingCard(
      DocumentSnapshot<Map<String, dynamic>> booking, BuildContext context) {
    final status = booking['Status'] ?? 'Unknown';
    final statusColor = status == 'Accepted'
        ? Colors.green
        : status == 'Rejected'
            ? Colors.red
            : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking['RoomTitle'] ?? 'Unknown Room',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Category', booking['RoomCategory'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Check-in',
              DateFormat('MMM dd, yyyy').format(booking['CheckInDate'].toDate()),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Check-out',
              DateFormat('MMM dd, yyyy').format(booking['CheckOutDate'].toDate()),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Total Price',
              '₱${booking['TotalPrice'].toStringAsFixed(2)}',
              isPrice: true,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Booked Date',
              DateFormat('MMM dd, yyyy').format(booking['BookingDate'].toDate()),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => BookingConfirmationDialog(
                        bookingId: booking['BookingID'],
                        checkInDate: booking['CheckInDate'].toDate(),
                        checkOutDate: booking['CheckOutDate'].toDate(),
                        totalPrice: booking['TotalPrice'],
                        roomTitle: booking['RoomTitle'] ?? 'Unknown Room',
                        roomCategory: booking['RoomCategory'] ?? 'Unknown',
                        lengthOfStay: booking['LengthOfStay'] ?? 0,
                        showConfirmation: false,
                      ),
                    );
                  },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5E60F8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'View QR Code & Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isPrice = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: isPrice ? const Color(0xFF5E60F8) : Colors.black87,
            fontWeight: isPrice ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
