import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PerformanceAnalytics extends StatefulWidget {
  const PerformanceAnalytics({super.key});

  @override
  State<PerformanceAnalytics> createState() => _PerformanceAnalyticsState();
}

class _PerformanceAnalyticsState extends State<PerformanceAnalytics> {
  static const _primary = Color(0xFF5E60F8);
  late String _selectedMonth;
  late String _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month.toString().padLeft(2, '0');
    _selectedYear = now.year.toString();
  }

  Future<Map<String, dynamic>> _fetchAnalyticsData() async {
    final monthFilter = '$_selectedYear-$_selectedMonth';
    final queryMonth = DateTime(int.parse(_selectedYear), int.parse(_selectedMonth));
    final daysInMonth =
        DateTime(int.parse(_selectedYear), int.parse(_selectedMonth) + 1, 0).day;

    try {
      final bookings = await FirebaseFirestore.instance
          .collection('Bookings')
          .where('MonthBooked', isEqualTo: monthFilter)
          .get();

      double totalRevenue = 0;
      int totalUnits = 0;
      Map<String, double> roomRevenue = {};
      Map<String, int> roomBookings = {};
      Map<String, double> avgStayByRoom = {};
      Map<String, List<int>> stayLengths = {};
      int totalBookingDays = 0;
      int totalRooms = 0;

      // Get room counts for occupancy
      final standardRooms =
          await FirebaseFirestore.instance.collection('Standard').get();
      final deluxeRooms =
          await FirebaseFirestore.instance.collection('Deluxe').get();
      final suitesRooms =
          await FirebaseFirestore.instance.collection('Suites').get();
      final specialtyRooms =
          await FirebaseFirestore.instance.collection('Specialty').get();
      totalRooms = standardRooms.docs.length +
          deluxeRooms.docs.length +
          suitesRooms.docs.length +
          specialtyRooms.docs.length;

      for (var booking in bookings.docs) {
        final data = booking.data();
        final status = data['Status'] ?? 'Pending';

        // Only count confirmed/completed bookings for revenue
        if (status == 'Confirmed' || status == 'Completed') {
          totalRevenue += (data['TotalPrice'] ?? 0).toDouble();
          totalUnits++;

          final roomTitle = data['RoomTitle'] ?? 'Unknown';
          final roomCategory = data['RoomCategory'] ?? 'Unknown';
          final lengthOfStay = data['LengthOfStay'] ?? 0;
          final roomPrice = data['RoomPrice'] ?? 0;

          // Track by room
          roomRevenue[roomTitle] = (roomRevenue[roomTitle] ?? 0) + (data['TotalPrice'] ?? 0).toDouble();
          roomBookings[roomTitle] = (roomBookings[roomTitle] ?? 0) + 1;

          if (!stayLengths.containsKey(roomTitle)) {
            stayLengths[roomTitle] = [];
          }
          stayLengths[roomTitle]!.add(lengthOfStay);

          totalBookingDays += (lengthOfStay as int);
        }
      }

      // Calculate average stay per room
      for (var room in stayLengths.entries) {
        final lengths = room.value;
        avgStayByRoom[room.key] =
            lengths.isEmpty ? 0 : lengths.reduce((a, b) => a + b) / lengths.length;
      }

      // Calculate occupancy rate
      final occupancyRate = totalRooms > 0
          ? (totalBookingDays / (daysInMonth * totalRooms) * 100)
          : 0.0;

      return {
        'totalRevenue': totalRevenue,
        'totalUnits': totalUnits,
        'roomRevenue': roomRevenue,
        'roomBookings': roomBookings,
        'avgStayByRoom': avgStayByRoom,
        'totalBookingDays': totalBookingDays,
        'occupancyRate': occupancyRate,
        'averageBookingValue': totalUnits > 0 ? totalRevenue / totalUnits : 0,
        'averageStay': totalBookingDays > 0 && totalUnits > 0
            ? totalBookingDays / totalUnits
            : 0,
      };
    } catch (e) {
      print('Error fetching analytics: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

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
                              'Performance Metrics',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Business Analytics',
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

          // Month/Year Selector
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedMonth,
                      isExpanded: true,
                      items: List.generate(12, (i) {
                        final month = (i + 1).toString().padLeft(2, '0');
                        final monthName =
                            DateFormat('MMMM').format(DateTime(2024, i + 1, 1));
                        return DropdownMenuItem(
                          value: month,
                          child: Text(monthName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMonth = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedYear,
                      isExpanded: true,
                      items: List.generate(3, (i) {
                        final year = (DateTime.now().year - 2 + i).toString();
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedYear = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Key Metrics
          FutureBuilder<Map<String, dynamic>>(
            future: _fetchAnalyticsData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text('No data available for selected period'),
                    ),
                  ),
                );
              }

              final data = snapshot.data!;
              final totalRevenue = data['totalRevenue'] as double;
              final totalUnits = data['totalUnits'] as int;
              final avgBookingValue = data['averageBookingValue'] as double;
              final averageStay = data['averageStay'] as double;
              final occupancyRate = data['occupancyRate'] as double;
              final roomRevenue =
                  data['roomRevenue'] as Map<String, dynamic>;
              final roomBookings =
                  data['roomBookings'] as Map<String, dynamic>;
              final avgStayByRoom =
                  data['avgStayByRoom'] as Map<String, dynamic>;

              return SliverList(
                delegate: SliverChildListDelegate([
                  // Summary Section Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      'Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Key Metrics Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      crossAxisCount: isMobile ? 2 : 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildMetricCard(
                          title: 'Units Sold',
                          value: totalUnits.toString(),
                          icon: Icons.shopping_bag,
                          color: Colors.blue,
                        ),
                        _buildMetricCard(
                          title: 'Total Revenue',
                          value: '₱${totalRevenue.toStringAsFixed(0)}',
                          icon: Icons.monetization_on,
                          color: Colors.green,
                        ),
                        _buildMetricCard(
                          title: 'Avg Booking',
                          value: '₱${avgBookingValue.toStringAsFixed(0)}',
                          icon: Icons.trending_up,
                          color: Colors.orange,
                        ),
                        _buildMetricCard(
                          title: 'Occupancy',
                          value: '${occupancyRate.toStringAsFixed(1)}%',
                          icon: Icons.hotel,
                          color: Colors.purple,
                        ),
                        _buildMetricCard(
                          title: 'Avg Stay',
                          value: '${averageStay.toStringAsFixed(1)} nights',
                          icon: Icons.calendar_today,
                          color: Colors.teal,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Room Performance Section
                  if (roomRevenue.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        'Room Performance',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 1 : 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: isMobile ? 1 : 1.2,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: roomRevenue.length,
                        itemBuilder: (context, index) {
                          final roomTitle =
                              roomRevenue.keys.toList()[index];
                          final revenue = roomRevenue[roomTitle];
                          final bookings = roomBookings[roomTitle] ?? 0;
                          final avgStay = avgStayByRoom[roomTitle] ?? 0;

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
                                Text(
                                  roomTitle,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                _buildRoomStat(
                                  label: 'Revenue',
                                  value: '₱${revenue.toStringAsFixed(0)}',
                                ),
                                const SizedBox(height: 8),
                                _buildRoomStat(
                                  label: 'Bookings',
                                  value: bookings.toString(),
                                ),
                                const SizedBox(height: 8),
                                _buildRoomStat(
                                  label: 'Avg Stay',
                                  value: '${avgStay.toStringAsFixed(1)} nights',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Revenue Comparison
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      'Revenue Breakdown',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
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
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: roomRevenue.length,
                        itemBuilder: (context, index) {
                          final roomTitle =
                              roomRevenue.keys.toList()[index];
                          final revenue = roomRevenue[roomTitle] as double;
                          final percentage = totalRevenue > 0
                              ? (revenue / totalRevenue * 100)
                              : 0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      roomTitle,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '₱${revenue.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage / 100,
                                    minHeight: 6,
                                    backgroundColor:
                                        const Color(0xFFE2E5EE),
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      Color.lerp(
                                        Colors.blue,
                                        Colors.purple,
                                        index / (roomRevenue.length > 1 ? roomRevenue.length - 1 : 1),
                                      )!,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E5EE), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomStat({
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
