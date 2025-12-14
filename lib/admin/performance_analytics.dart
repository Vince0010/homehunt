import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fl_chart/fl_chart.dart';

class PerformanceAnalytics extends StatefulWidget {
  const PerformanceAnalytics({super.key});

  @override
  State<PerformanceAnalytics> createState() => _PerformanceAnalyticsState();
}

class _PerformanceAnalyticsState extends State<PerformanceAnalytics> {
  static const _primary = Color(0xFF5E60F8);

  // --- CHART COLORS ---
  // For the App UI (Flutter Colors)
  final List<Color> _screenColors = [
    Colors.blue, Colors.purple, Colors.orange, Colors.teal, Colors.redAccent, Colors.indigo,
  ];

  // For the PDF (PdfColor objects)
  final List<PdfColor> _pdfColors = [
    PdfColors.blue, PdfColors.purple, PdfColors.orange, PdfColors.teal, PdfColors.redAccent, PdfColors.indigo,
  ];

  late String _selectedMonth;
  late String _selectedYear;

  // --- API CONFIGURATION ---
  // TODO: Replace this with your actual Gemini API Key
  final String _apiKey = 'AIzaSyBdkn5Wito3SsIP_tUQm04AwSgeh8_idMI'; 
  
  String? _aiAnalysisResult;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month.toString().padLeft(2, '0');
    _selectedYear = now.year.toString();
  }

  // --- 1. AI GENERATION LOGIC ---
  Future<void> _generateAiInsights(Map<String, dynamic> data) async {
    if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      setState(() => _aiAnalysisResult = "Error: Please add your API Key in the code.");
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _aiAnalysisResult = null;
    });

    try {
      // Using the model confirmed to work for your key
      final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: _apiKey);

      final cleanRoomData = Map.from(data['roomRevenue'])..removeWhere((k, v) => v == 0);

      final prompt = '''
        You are a Senior Hotel Performance Consultant. Write a detailed "Monthly Performance Report" based on this data:
        
        DATA CONTEXT:
        - Period: $_selectedMonth/$_selectedYear
        - Total Revenue: ₱${data['totalRevenue']}
        - Occupancy Rate: ${(data['occupancyRate'] as double).toStringAsFixed(1)}%
        - Total Units Sold: ${data['totalUnits']}
        - Avg Booking Value: ₱${(data['averageBookingValue'] as double).toStringAsFixed(0)}
        - Avg Length of Stay: ${(data['averageStay'] as double).toStringAsFixed(1)} nights
        - Revenue by Room Type: $cleanRoomData

        STRUCTURE YOUR RESPONSE EXACTLY LIKE THIS:
        
        ### 1. Executive Summary
        (A 2-3 sentence high-level overview of the business health this month.)

        ### 2. Revenue Deep Dive
        (Analyze the revenue sources. Which room type is the "Cash Cow"? Are we relying too much on one type? Mention percentages.)

        ### 3. Operational Efficiency
        (Comment on the Occupancy Rate of ${(data['occupancyRate'] as double).toStringAsFixed(1)}% and Avg Stay. Is this efficient? Are guests staying long enough?)

        ### 4. Strategic Recommendations
        (Provide 3 specific, actionable bullet points for the Hotel Manager to improve next month's numbers.)
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      setState(() {
        _aiAnalysisResult = response.text;
      });
    } catch (e) {
      setState(() {
        _aiAnalysisResult = "Error generating insights: $e";
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  // --- 2. APP SCREEN CHART WIDGET ---
  Widget _buildRevenueChart(Map<String, dynamic> roomRevenue) {
    if (roomRevenue.isEmpty) return const SizedBox.shrink();

    int colorIndex = 0;
    final sections = roomRevenue.entries.map((entry) {
      final color = _screenColors[colorIndex % _screenColors.length];
      colorIndex++;
      final value = (entry.value as num).toDouble();
      
      return PieChartSectionData(
        color: color,
        value: value,
        title: value > 1000 ? '${(value/1000).toStringAsFixed(1)}k' : value.toStringAsFixed(0),
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: roomRevenue.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final name = entry.value.key;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, color: _screenColors[index % _screenColors.length]),
                const SizedBox(width: 4),
                Text(name, style: const TextStyle(fontSize: 12)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- 3. PDF EXPORT LOGIC (Text + Graph) ---
  Future<void> _exportToPdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    
    final currencyFormat = NumberFormat.currency(symbol: 'P', decimalDigits: 0);
    final totalRevenue = data['totalRevenue'] as double;
    final roomRevenue = data['roomRevenue'] as Map<String, dynamic>;
    
    // Clean AI text (remove markdown stars for clean PDF text)
    final String cleanAiText = _aiAnalysisResult?.replaceAll('**', '') ?? 
        "AI Insights not generated for this report. Please click 'Generate Report' in the app first.";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Monthly Performance Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text('$_selectedMonth/$_selectedYear', style: const pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
              ]
            )
          ),

          pw.SizedBox(height: 20),

          // AI Insights Section
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: PdfColors.blue200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('AI Consultant Report', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.SizedBox(height: 10),
                pw.Text(cleanAiText, style: const pw.TextStyle(fontSize: 10, height: 1.5)),
              ]
            )
          ),

          pw.SizedBox(height: 30),

          // GRAPH SECTION IN PDF
          if (roomRevenue.isNotEmpty) ...[
            pw.Text('Revenue Composition', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 15),
            
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // The Pie Chart
                pw.Expanded(
                  flex: 2,
                  child: pw.SizedBox(
                    height: 150,
                    child: pw.Chart(
                      grid: pw.PieGrid(),
                      datasets: List.generate(roomRevenue.length, (index) {
                        final key = roomRevenue.keys.elementAt(index);
                        final value = (roomRevenue[key] as num).toDouble();
                        final color = _pdfColors[index % _pdfColors.length];
                        return pw.PieDataSet(
                          legend: key,
                          value: value,
                          color: color,
                          legendStyle: const pw.TextStyle(fontSize: 10),
                        );
                      }),
                    ),
                  ),
                ),
                // The Legend text on the side
                pw.SizedBox(width: 20),
                pw.Expanded(
                  flex: 1,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: List.generate(roomRevenue.length, (index) {
                      final key = roomRevenue.keys.elementAt(index);
                      final value = (roomRevenue[key] as num).toDouble();
                      final color = _pdfColors[index % _pdfColors.length];
                      final pct = totalRevenue > 0 ? (value / totalRevenue * 100).toStringAsFixed(1) : '0';
                      
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 5),
                        child: pw.Row(
                          children: [
                            pw.Container(width: 8, height: 8, color: color),
                            pw.SizedBox(width: 5),
                            pw.Text('$key: $pct%', style: const pw.TextStyle(fontSize: 10)),
                          ]
                        )
                      );
                    }),
                  ),
                ),
              ]
            ),
          ],

          pw.SizedBox(height: 30),

          // Data Table
          pw.Text('Financial Breakdown', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headerHeight: 25,
            cellHeight: 25,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
            },
            headers: ['Room Type', 'Revenue'],
            data: roomRevenue.entries.map((e) {
              return [e.key, currencyFormat.format(e.value)];
            }).toList(),
          ),
          
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Generated by Hotel AI • ${DateTime.now().toString().split('.')[0]}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          )
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }


  // --- 4. DATA FETCHING LOGIC ---
  Future<Map<String, dynamic>> _fetchAnalyticsData() async {
    final monthFilter = '$_selectedYear-$_selectedMonth';
    final queryMonth = DateTime(int.parse(_selectedYear), int.parse(_selectedMonth));
    final daysInMonth = DateTime(int.parse(_selectedYear), int.parse(_selectedMonth) + 1, 0).day;

    try {
      // Get all bookings
      final bookings = await FirebaseFirestore.instance.collection('Bookings').get();

      double totalRevenue = 0;
      int totalUnits = 0;
      Map<String, double> roomRevenue = {};
      Map<String, int> roomBookings = {};
      Map<String, double> avgStayByRoom = {};
      Map<String, List<int>> stayLengths = {};
      int totalBookingDays = 0;
      int totalRooms = 0;

      // Get room counts for occupancy
      final standardRooms = await FirebaseFirestore.instance.collection('Standard').get();
      final deluxeRooms = await FirebaseFirestore.instance.collection('Deluxe').get();
      final suitesRooms = await FirebaseFirestore.instance.collection('Suites').get();
      final specialtyRooms = await FirebaseFirestore.instance.collection('Specialty').get();
      
      totalRooms = standardRooms.docs.length + deluxeRooms.docs.length + suitesRooms.docs.length + specialtyRooms.docs.length;

      for (var booking in bookings.docs) {
        final data = booking.data();
        final status = data['Status'] ?? 'Pending';

        // Normalize MonthBooked
        String? bookingMonth = data['MonthBooked'];
        if (bookingMonth == null && data['CheckInDate'] != null) {
          final checkIn = (data['CheckInDate'] as Timestamp).toDate();
          bookingMonth = '${checkIn.year}-${checkIn.month.toString().padLeft(2, '0')}';
        }

        // Only count confirmed/completed bookings for this month
        if (bookingMonth == monthFilter && (status == 'Confirmed' || status == 'Completed')) {
          totalRevenue += (data['TotalPrice'] ?? 0).toDouble();
          totalUnits++;

          final roomTitle = data['RoomTitle'] ?? 'Unknown';
          final lengthOfStay = data['LengthOfStay'] ?? 0;

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

      // Calculate averages
      for (var room in stayLengths.entries) {
        final lengths = room.value;
        avgStayByRoom[room.key] = lengths.isEmpty ? 0 : lengths.reduce((a, b) => a + b) / lengths.length;
      }

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
        'averageBookingValue': totalUnits > 0 ? totalRevenue / totalUnits : 0.0,
        'averageStay': totalBookingDays > 0 && totalUnits > 0
            ? totalBookingDays / totalUnits
            : 0.0,
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
                  const Text(
                    'Performance Metrics',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
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
                        final monthName = DateFormat('MMMM').format(DateTime(2024, i + 1, 1));
                        return DropdownMenuItem(value: month, child: Text(monthName));
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedMonth = value!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedYear,
                      isExpanded: true,
                      items: List.generate(3, (i) {
                        final year = (DateTime.now().year - 2 + i).toString();
                        return DropdownMenuItem(value: year, child: Text(year));
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedYear = value!),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Metrics Loader
          FutureBuilder<Map<String, dynamic>>(
            future: _fetchAnalyticsData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No data available for selected period'))),
                );
              }

              final data = snapshot.data!;
              final totalRevenue = data['totalRevenue'] as double;
              final totalUnits = data['totalUnits'] as int;
              final avgBookingValue = data['averageBookingValue'] as double;
              final averageStay = data['averageStay'] as double;
              final occupancyRate = data['occupancyRate'] as double;
              final roomRevenue = data['roomRevenue'] as Map<String, dynamic>;
              final roomBookings = data['roomBookings'] as Map<String, dynamic>;
              final avgStayByRoom = data['avgStayByRoom'] as Map<String, dynamic>;

              return SliverList(
                delegate: SliverChildListDelegate([
                  
                  // --- EXPORT BUTTON ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _exportToPdf(data),
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text("Export Report"),
                        style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                      ),
                    ),
                  ),

                  // --- AI ANALYST CARD (With Chart) ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 5, 16, 10),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.indigo.shade50, Colors.white]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _primary.withOpacity(0.3)),
                        boxShadow: [
                           BoxShadow(color: _primary.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                        ]
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.auto_awesome, color: _primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'AI Business Analyst',
                                    style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              if (!_isAnalyzing)
                                ElevatedButton(
                                  onPressed: () => _generateAiInsights(data),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                                  ),
                                  child: Text(_aiAnalysisResult == null ? 'Generate Report' : 'Refresh'),
                                ),
                            ],
                          ),
                          
                          // Loading Indicator
                          if (_isAnalyzing)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: 20, 
                                      height: 20, 
                                      child: CircularProgressIndicator(strokeWidth: 2, color: _primary)
                                    ),
                                    const SizedBox(height: 8),
                                    const Text("Consulting Senior Analyst...", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),

                          // Results Display
                          if (_aiAnalysisResult != null && !_isAnalyzing) ...[
                            const SizedBox(height: 12),
                            Divider(color: Colors.grey.withOpacity(0.2)),
                            
                            // 1. Text Report
                            MarkdownBody(
                              data: _aiAnalysisResult!,
                              styleSheet: MarkdownStyleSheet(
                                h3: TextStyle(color: _primary, fontSize: 16, fontWeight: FontWeight.bold, height: 2.0),
                                p: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                                strong: TextStyle(color: Colors.indigo.shade900, fontWeight: FontWeight.bold),
                              ),
                            ),
                            
                            const SizedBox(height: 24),

                            // 2. Visual Chart (App side)
                            if (roomRevenue.isNotEmpty) ...[
                              Text("Revenue Visualization", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 10),
                              _buildRevenueChart(roomRevenue),
                            ]
                          ],
                        ],
                      ),
                    ),
                  ),

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
                          childAspectRatio: isMobile ? 2.5 : 1.2,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: roomRevenue.length,
                        itemBuilder: (context, index) {
                          final roomTitle = roomRevenue.keys.toList()[index];
                          final revenue = roomRevenue[roomTitle];
                          final bookings = roomBookings[roomTitle] ?? 0;
                          final avgStay = avgStayByRoom[roomTitle] ?? 0;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE2E5EE)),
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  roomTitle,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                _buildRoomStat(
                                  label: 'Revenue',
                                  value: '₱${revenue?.toStringAsFixed(0)}',
                                ),
                                const SizedBox(height: 8),
                                _buildRoomStat(
                                  label: 'Bookings',
                                  value: bookings.toString(),
                                ),
                                const SizedBox(height: 8),
                                _buildRoomStat(
                                  label: 'Avg Stay',
                                  value: '${avgStay.toStringAsFixed(1)} nts',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

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
        border: Border.all(color: const Color(0xFFE2E5EE)),
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
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ],
    );
  }
}