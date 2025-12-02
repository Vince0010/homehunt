import 'package:cloud_firestore/cloud_firestore.dart';

class MigrationService {
  /// Migrate room prices from String to Double
  /// Run this once after deploying updated add_room.dart
  static Future<void> migrateRoomPrices() async {
    final categories = ['Standard', 'Deluxe', 'Suites', 'Specialty'];
    int totalUpdated = 0;

    for (String category in categories) {
      try {
        final collection = FirebaseFirestore.instance.collection(category);
        final docs = await collection.get();

        for (var doc in docs.docs) {
          final price = doc['Price'];
          // Only update if it's still a string
          if (price is String) {
            final priceNumber = double.tryParse(price) ?? 0.0;
            await doc.reference.update({'Price': priceNumber});
            totalUpdated++;
            print('[$category] Updated ${doc.id}: Price = $priceNumber');
          }
        }
      } catch (e) {
        print('Error migrating $category: $e');
      }
    }
    print('Price migration complete! Updated $totalUpdated documents');
  }

  /// Backfill existing bookings with analytics metadata
  /// This is optional - analytics will work without this but old bookings won't show complete data
  static Future<void> backfillBookingMetadata() async {
    try {
      final bookingsRef = FirebaseFirestore.instance.collection('Bookings');
      final bookings = await bookingsRef.get();

      int updated = 0;
      for (var booking in bookings.docs) {
        Map<String, dynamic> updateData = {};
        final data = booking.data();

        // Add missing RoomID
        if (!data.containsKey('RoomID')) {
          updateData['RoomID'] = 'unknown-backfill';
        }

        // Add missing RoomTitle
        if (!data.containsKey('RoomTitle')) {
          updateData['RoomTitle'] = 'Unknown Room';
        }

        // Add missing RoomCategory
        if (!data.containsKey('RoomCategory')) {
          updateData['RoomCategory'] = 'Unknown';
        }

        // Add missing RoomPrice (estimate from TotalPrice / LengthOfStay if available)
        if (!data.containsKey('RoomPrice')) {
          if (data.containsKey('LengthOfStay') && data['LengthOfStay'] > 0) {
            updateData['RoomPrice'] = data['TotalPrice'] / data['LengthOfStay'];
          } else {
            updateData['RoomPrice'] = data['TotalPrice'];
          }
        }

        // Add missing LengthOfStay
        if (!data.containsKey('LengthOfStay')) {
          final checkIn = (data['CheckInDate'] as Timestamp).toDate();
          final checkOut = (data['CheckOutDate'] as Timestamp).toDate();
          updateData['LengthOfStay'] = checkOut.difference(checkIn).inDays;
        }

        // Add missing MonthBooked (YYYY-MM format)
        if (!data.containsKey('MonthBooked')) {
          final checkIn = (data['CheckInDate'] as Timestamp).toDate();
          updateData['MonthBooked'] = '${checkIn.year}-${checkIn.month.toString().padLeft(2, '0')}';
        }

        // Add missing BookingDate
        if (!data.containsKey('BookingDate')) {
          updateData['BookingDate'] = data['CheckInDate'];
        }

        // Update if there are any missing fields
        if (updateData.isNotEmpty) {
          await booking.reference.update(updateData);
          updated++;
          print('Backfilled booking ${booking.id}');
        }
      }

      print('Backfill complete! Updated $updated bookings with metadata');
    } catch (e) {
      print('Error during backfill: $e');
    }
  }

  /// Update booking statuses to Completed for past check-outs
  /// Run periodically to mark old bookings as completed
  static Future<void> updatePastBookingsToCompleted() async {
    try {
      final bookingsRef = FirebaseFirestore.instance.collection('Bookings');
      final now = DateTime.now();

      // Query bookings that are still pending or confirmed
      final bookings = await bookingsRef
          .where('Status', whereIn: ['Pending', 'Confirmed'])
          .get();

      int updated = 0;
      for (var booking in bookings.docs) {
        final data = booking.data();
        final checkOut = (data['CheckOutDate'] as Timestamp).toDate();

        if (checkOut.isBefore(now)) {
          await booking.reference.update({'Status': 'Completed'});
          updated++;
          print('Marked booking ${booking.id} as Completed');
        }
      }

      print('Status update complete! Updated $updated bookings to Completed');
    } catch (e) {
      print('Error updating status: $e');
    }
  }
}
