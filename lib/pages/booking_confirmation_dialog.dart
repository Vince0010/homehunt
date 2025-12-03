import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

class BookingConfirmationDialog extends StatefulWidget {
  final String bookingId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final double totalPrice;
  final String roomTitle;
  final String roomCategory;
  final int lengthOfStay;
  final bool showConfirmation;

  const BookingConfirmationDialog({
    super.key,
    required this.bookingId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.totalPrice,
    required this.roomTitle,
    required this.roomCategory,
    required this.lengthOfStay,
    this.showConfirmation = true,
  });

  @override
  State<BookingConfirmationDialog> createState() =>
      _BookingConfirmationDialogState();
}

class _BookingConfirmationDialogState extends State<BookingConfirmationDialog> {
  bool _hasReadWarning = false;

  String _generateQRData() {
    final data = {
      'BookingID': widget.bookingId,
      'RoomTitle': widget.roomTitle,
      'RoomCategory': widget.roomCategory,
      'CheckIn': DateFormat('yyyy-MM-dd').format(widget.checkInDate),
      'CheckOut': DateFormat('yyyy-MM-dd').format(widget.checkOutDate),
      'TotalPrice': widget.totalPrice,
      'LengthOfStay': widget.lengthOfStay,
      'BookingDate': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
    };
    return jsonEncode(data);
  }

  Future<void> _showSaveConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Important: Save Your Booking Details',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200, width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Management is NOT responsible for the loss or failure of guest information.',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please confirm that you have saved all your booking details including the QR code and booking information.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Go Back & Save',
                style: TextStyle(color: Color(0xFF5E60F8)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E60F8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('I Have Saved Everything'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrData = _generateQRData();
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.85,
          minHeight: 200,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Booking Confirmed!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Booking ID: ${widget.bookingId}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Important Warning Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200, width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info, color: Colors.amber.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'YOU ARE LIABLE FOR SAVING THIS INFORMATION. Take a screenshot or save the QR code.',
                              style: TextStyle(
                                color: Colors.amber.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // QR Code Section
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE2E5EE), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SizedBox(
                          width: 180,
                          height: 180,
                          child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Divider
                    Container(
                      height: 1,
                      color: const Color(0xFFE2E5EE),
                    ),
                    const SizedBox(height: 20),

                    // Booking Details
                    const Text(
                      'Booking Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildDetailRow('Booking ID', widget.bookingId, isPrimary: true),
                    const SizedBox(height: 10),

                    _buildDetailRow('Room', widget.roomTitle),
                    const SizedBox(height: 10),

                    _buildDetailRow('Category', widget.roomCategory),
                    const SizedBox(height: 10),

                    _buildDetailRow(
                      'Check-in',
                      DateFormat('MMM dd, yyyy').format(widget.checkInDate),
                    ),
                    const SizedBox(height: 10),

                    _buildDetailRow(
                      'Check-out',
                      DateFormat('MMM dd, yyyy').format(widget.checkOutDate),
                    ),
                    const SizedBox(height: 10),

                    _buildDetailRow('Length of Stay', '${widget.lengthOfStay} night(s)'),
                    const SizedBox(height: 10),

                    _buildDetailRow(
                      'Total Price',
                      '₱${widget.totalPrice.toStringAsFixed(2)}',
                      isPrice: true,
                    ),
                    const SizedBox(height: 20),

                    // Important Notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200, width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notification_important,
                              color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Management will NOT be responsible if you lose this information.',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confirmation Checkbox
                    if (widget.showConfirmation)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200, width: 1),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _hasReadWarning,
                              onChanged: (value) {
                                setState(() {
                                  _hasReadWarning = value ?? false;
                                });
                              },
                              activeColor: const Color(0xFF5E60F8),
                            ),
                            Expanded(
                              child: Text(
                                'I have saved my booking details and understand the policy',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: widget.showConfirmation
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFF5E60F8),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Go Back',
                              style: TextStyle(
                                color: Color(0xFF5E60F8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _hasReadWarning
                                ? _showSaveConfirmationDialog
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5E60F8),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5E60F8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isPrice = false, bool isPrimary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              color: isPrice
                  ? const Color(0xFF5E60F8)
                  : isPrimary
                      ? const Color(0xFF5E60F8)
                      : Colors.black87,
              fontWeight: isPrice || isPrimary ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
