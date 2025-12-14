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

  void fetchBookings() {
    bookingStream =
        FirebaseFirestore.instance.collection('Bookings').snapshots();
  }

  // --- LOGIC: Check-In Guest ---
  Future<void> _handleCheckIn(String bookingId, String? userId, String roomTitle) async {
    try {
      // This will CREATE the 'ActualCheckInTime' field if it doesn't exist yet
      await FirebaseFirestore.instance.collection('Bookings').doc(bookingId).update({
        'Status': 'Checked In',
        'ActualCheckInTime': Timestamp.now(), 
      });

      if (userId != null) {
        await _createAlert(userId, 'Checked In', 
          'You have successfully checked in to $roomTitle. Enjoy your stay!', 'checked_in');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Guest Checked In successfully!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print("Error checking in: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // --- LOGIC: Check-Out Guest ---
  Future<void> _handleCheckOut(String bookingId, String? userId, String roomTitle) async {
    try {
      // This will CREATE the 'ActualCheckOutTime' field if it doesn't exist yet
      await FirebaseFirestore.instance.collection('Bookings').doc(bookingId).update({
        'Status': 'Completed',
        'ActualCheckOutTime': Timestamp.now(),
      });

      if (userId != null) {
        await _createAlert(userId, 'Checked Out', 
          'Thank you for staying at $roomTitle. We hope to see you again!', 'completed');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Guest Checked Out. Booking Completed."), backgroundColor: Colors.blue),
        );
      }
    } catch (e) {
      print("Error checking out: $e");
    }
  }

  // --- LOGIC: General Status Updates ---
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      final bookingDoc = await FirebaseFirestore.instance.collection('Bookings').doc(bookingId).get();
      final bookingData = bookingDoc.data();
      
      // Safe access using ?. and ?? in case fields are missing
      final userId = bookingData?['UserID']; 
      final roomTitle = bookingData?['RoomTitle'] ?? 'Room';

      if (newStatus == 'Rejected') {
        await FirebaseFirestore.instance.collection('Bookings').doc(bookingId).delete();
        if (userId != null) {
          await _createAlert(userId, 'Booking Rejected', 'Your booking for $roomTitle has been rejected.', 'rejected');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking rejected and removed.")));
        }
      } else {
        await FirebaseFirestore.instance.collection('Bookings').doc(bookingId).update({'Status': newStatus});
        if (userId != null) {
          await _createAlert(userId, 'Booking Status Updated', 'Your booking for $roomTitle is now $newStatus.', newStatus.toLowerCase());
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Status updated to $newStatus")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update: $e")));
      }
    }
  }

  Future<void> _createAlert(String userId, String title, String message, String statusType) async {
    try {
      // Check if 'users' collection exists first to prevent errors
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(userId).collection('alerts').add({
          'type': 'automated',
          'title': title,
          'message': message,
          'status': statusType,
          'timestamp': Timestamp.now(),
          'isRead': false,
        });
      }
    } catch (e) {
      print("Error creating alert (User might not exist yet): $e");
    }
  }

  String _normalizeStatus(dynamic status) {
    if (status == null) return 'Pending';
    String statusStr = status.toString().trim();
    
    switch (statusStr.toLowerCase()) {
      case 'confirm': return 'Confirmed';
      case 'done':
      case 'complete': return 'Completed';
      case 'reject': return 'Rejected';
      case 'pending':
      case 'pending approval': return 'Pending';
      case 'approved': return 'Approved';
      case 'checked in': return 'Checked In';
      default:
        if (['Pending', 'Confirmed', 'Completed', 'Rejected', 'Approved', 'Checked In'].contains(statusStr)) {
          return statusStr;
        }
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
          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF5E60F8), Color(0xFF6D70FA), Color(0xFFE9EBFF)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Booking Management', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('Manage Bookings', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          
          // Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text('Booking Requests', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),

          // List
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: bookingStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator())));
              }
              if (snapshot.hasError) {
                return SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text("Error: ${snapshot.error}"))));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text("No bookings found.", style: TextStyle(fontSize: 16, color: Colors.black54)))));
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final booking = snapshot.data!.docs[index];
                    final data = booking.data();

                    // --- SAFE DATA ACCESS (Handling missing fields) ---
                    
                    // Safely get Dates
                    DateTime checkInDate = DateTime.now();
                    if (data['CheckInDate'] != null) {
                       checkInDate = (data['CheckInDate'] as Timestamp).toDate();
                    }
                    
                    DateTime checkOutDate = DateTime.now();
                    if (data['CheckOutDate'] != null) {
                       checkOutDate = (data['CheckOutDate'] as Timestamp).toDate();
                    }
                    
                    // Safely get other fields
                    String currentStatus = _normalizeStatus(data['Status']);
                    String roomTitle = data['RoomTitle'] ?? 'Unknown Room';
                    String? userId = data['UserID'];
                    String totalPrice = data['TotalPrice']?.toString() ?? '0';
                    String? imagePath = data['ImagePath'];

                    // Color Coding Logic
                    Color statusColorBg;
                    Color statusColorText;
                    
                    if (currentStatus == 'Confirmed') {
                      statusColorBg = Colors.green.shade50;
                      statusColorText = Colors.green.shade700;
                    } else if (currentStatus == 'Checked In') {
                      statusColorBg = Colors.purple.shade50;
                      statusColorText = Colors.purple.shade700;
                    } else if (currentStatus == 'Completed') {
                      statusColorBg = Colors.blue.shade50;
                      statusColorText = Colors.blue.shade700;
                    } else if (currentStatus == 'Pending') {
                      statusColorBg = Colors.orange.shade50;
                      statusColorText = Colors.orange.shade700;
                    } else {
                      statusColorBg = Colors.red.shade50;
                      statusColorText = Colors.red.shade700;
                    }

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E5EE), width: 1),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image
                              imagePath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: Image.network(imagePath, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE5E7EB), child: const Icon(Icons.image, size: 50, color: Colors.grey))),
                                      ),
                                    )
                                  : Container(
                                      height: 100, 
                                      width: double.infinity, 
                                      color: Colors.grey[200], 
                                      child: const Center(child: Text("No Image", style: TextStyle(color: Colors.grey)))
                                    ),
                              const SizedBox(height: 12),
                              
                              // ID
                              Text("Booking ID: ${booking.id}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                              const SizedBox(height: 8),

                              // Dates
                              Row(children: [const Icon(Icons.calendar_today, size: 14, color: Colors.black45), const SizedBox(width: 4), Expanded(child: Text("Check-in: ${DateFormat('yyyy-MM-dd').format(checkInDate)}", style: const TextStyle(fontSize: 12, color: Colors.black54)))]),
                              const SizedBox(height: 4),
                              Row(children: [const Icon(Icons.calendar_today, size: 14, color: Colors.black45), const SizedBox(width: 4), Expanded(child: Text("Check-out: ${DateFormat('yyyy-MM-dd').format(checkOutDate)}", style: const TextStyle(fontSize: 12, color: Colors.black54)))]),
                              const SizedBox(height: 8),

                              // Price & Status Badge
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      const Text('Total Price', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                      const SizedBox(height: 2),
                                      Text("₱$totalPrice", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
                                    ]),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: statusColorBg, borderRadius: BorderRadius.circular(6)),
                                    child: Text(currentStatus, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColorText)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Dropdown
                              DropdownButton<String>(
                                isExpanded: true,
                                value: currentStatus,
                                items: <String>['Pending', 'Confirmed', 'Checked In', 'Completed', 'Rejected', 'Approved']
                                    .map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null && newValue != currentStatus) {
                                    updateBookingStatus(booking.id, newValue);
                                  }
                                },
                              ),

                              // Action Buttons
                              if (currentStatus == 'Confirmed' || currentStatus == 'Checked In') ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      if (currentStatus == 'Confirmed') {
                                        _handleCheckIn(booking.id, userId, roomTitle);
                                      } else if (currentStatus == 'Checked In') {
                                        _handleCheckOut(booking.id, userId, roomTitle);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: currentStatus == 'Confirmed' ? const Color(0xFF5E60F8) : Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: Icon(currentStatus == 'Confirmed' ? Icons.login : Icons.logout),
                                    label: Text(currentStatus == 'Confirmed' ? "Check In Guest" : "Check Out Guest", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
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
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}