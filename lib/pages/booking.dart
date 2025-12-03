import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'booking_confirmation_dialog.dart';

class BookingPage extends StatefulWidget {
  final dynamic price; // Changed to dynamic to accept int or String
  final String? roomId;
  final String? roomTitle;
  final String? roomCategory;

  const BookingPage({
    super.key,
    required this.price,
    this.roomId,
    this.roomTitle,
    this.roomCategory,
  });

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? checkInDate;
  DateTime? checkOutDate;
  XFile? imageFile;
  Uint8List? imageBytes;
  final ImagePicker _picker = ImagePicker();

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn
          ? (checkInDate ?? DateTime.now())
          : (checkOutDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != (isCheckIn ? checkInDate : checkOutDate)) {
      setState(() {
        if (isCheckIn) {
          checkInDate = picked;
        } else {
          checkOutDate = picked;
        }
      });
    }
  }

  Future<void> _uploadImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imageFile = pickedFile; // Keep for mobile
        imageBytes = null; // Clear web bytes for mobile
      });

      // Convert to Uint8List for web image handling
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          imageFile = null; // Clear the file for web usage
          imageBytes = bytes; // Store the bytes for display
        });
      }
    }
  }

  double _calculateTotalPrice() {
    // Convert price from string or int to double
    double pricePerNight;
    if (widget.price is String) {
      pricePerNight = double.tryParse(widget.price) ?? 0.0;
    } else {
      pricePerNight = (widget.price as num).toDouble();
    }

    if (checkInDate != null && checkOutDate != null) {
      int totalDays = checkOutDate!.difference(checkInDate!).inDays;
      return totalDays > 0 ? totalDays * pricePerNight : 0.0;
    }
    return 0.0;
  }

  Future<String?> _uploadImageToFirebase() async {
    if (imageFile != null) {
      File file = File(imageFile!.path);
      try {
        // Upload the file to Firebase Storage
        String fileName =
            'uploads/${DateTime.now().millisecondsSinceEpoch}_${imageFile!.name}';
        TaskSnapshot snapshot =
            await FirebaseStorage.instance.ref(fileName).putFile(file);

        // Get the download URL
        String downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } catch (e) {
        print("Error uploading image: $e");
      }
    } else if (imageBytes != null) {
      try {
        // Upload the image bytes for web
        String fileName =
            'uploads/${DateTime.now().millisecondsSinceEpoch}.png';
        Reference ref = FirebaseStorage.instance.ref(fileName);
        UploadTask uploadTask = ref.putData(imageBytes!);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } catch (e) {
        print("Error uploading image: $e");
      }
    }
    return null;
  }

  Future<void> _confirmBooking() async {
    if (checkInDate != null && checkOutDate != null) {
      // Calculate total price
      double totalPrice = _calculateTotalPrice();

      // Get the current user's ID
      User? user = FirebaseAuth.instance.currentUser;
      String? uid = user?.uid;

      // Generate a unique BookingID
      String bookingId = DateTime.now().millisecondsSinceEpoch.toString();

      // Upload image and get its download URL
      String? imagePath = await _uploadImageToFirebase();

      // Calculate length of stay
      int lengthOfStay = checkOutDate!.difference(checkInDate!).inDays;
      
      // Calculate month booked (YYYY-MM format)
      String monthBooked = '${checkInDate!.year}-${checkInDate!.month.toString().padLeft(2, '0')}';

      // Prepare booking data with analytics fields
      Map<String, dynamic> bookingData = {
        'BookingID': bookingId,
        'UserID': uid,
        'CheckInDate': checkInDate,
        'CheckOutDate': checkOutDate,
        'TotalPrice': totalPrice,
        'Status': 'Pending',
        'ImagePath': imagePath,
        // Analytics fields
        'RoomID': widget.roomId ?? 'unknown',
        'RoomTitle': widget.roomTitle ?? 'Unknown Room',
        'RoomCategory': widget.roomCategory ?? 'Unknown',
        'RoomPrice': widget.price is String 
            ? (double.tryParse(widget.price) ?? 0.0) 
            : ((widget.price as num).toDouble()),
        'LengthOfStay': lengthOfStay,
        'MonthBooked': monthBooked,
        'BookingDate': DateTime.now(),
      };

      try {
        // Save booking data to Firestore
        await FirebaseFirestore.instance
            .collection('Bookings')
            .doc(bookingId)
            .set(bookingData);
        
        // Show confirmation dialog with QR code
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => BookingConfirmationDialog(
            bookingId: bookingId,
            checkInDate: checkInDate!,
            checkOutDate: checkOutDate!,
            totalPrice: totalPrice,
            roomTitle: widget.roomTitle ?? 'Unknown Room',
            roomCategory: widget.roomCategory ?? 'Unknown',
            lengthOfStay: lengthOfStay,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to confirm booking: $e")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all fields.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalPrice = _calculateTotalPrice();
    const Color _primary = Color(0xFF5E60F8);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white),
        ),
        title: const Text(
          "Book a Room",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Booking Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _primary,
              ),
            ),
            const SizedBox(height: 20),
            _buildDateField('Check-in Date', checkInDate, () => _selectDate(context, true)),
            const SizedBox(height: 16),
            _buildDateField('Check-out Date', checkOutDate, () => _selectDate(context, false)),
            const SizedBox(height: 16),
            _buildImageUploadField(),
            const SizedBox(height: 20),
            _buildPriceCard(totalPrice),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Confirm Booking',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Color(0xFF5E60F8)),
                const SizedBox(width: 12),
                Text(
                  date == null
                      ? 'Select date'
                      : DateFormat('MMM dd, yyyy').format(date),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Image (VALID ID)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _uploadImage,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
            child: imageFile == null && imageBytes == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 48,
                        color: Color(0xFF5E60F8),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap to upload image',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.memory(imageBytes!, fit: BoxFit.cover)
                        : Image.file(File(imageFile!.path), fit: BoxFit.cover),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceCard(double totalPrice) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Price',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₱${totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5E60F8),
            ),
          ),
        ],
      ),
    );
  }
}
