import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:homehunt/admin/admin_home.dart';
import 'package:homehunt/admin/admin_status.dart';
import 'package:homehunt/admin/admin_profile.dart';
import 'package:homehunt/admin/performance_analytics.dart';

class AdminNavbar extends StatefulWidget {
  const AdminNavbar({super.key});

  @override
  State<AdminNavbar> createState() => _AdminNavbarState();
}

class _AdminNavbarState extends State<AdminNavbar> {
  late List<Widget> pages;
  late AdminDashboard admindash;
  late AdminBookingStatus adminstatus;
  late PerformanceAnalytics analytics;
  late AdminProfile adminprofile;
  int currenttabindex = 0;

  @override
  void initState() {
    super.initState();
    admindash = const AdminDashboard();
    adminstatus = const AdminBookingStatus();
    analytics = const PerformanceAnalytics();
    adminprofile = const AdminProfile();

    pages = [admindash, adminstatus, analytics, adminprofile];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        height: 65,
        backgroundColor: Colors.white,
        color: const Color.fromARGB(255, 94, 96, 248),
        animationDuration: const Duration(milliseconds: 500),
        onTap: (int index) {
          setState(() {
            currenttabindex = index;
          });
        },
        items: const [
          Icon(Icons.home_outlined, color: Colors.white),
          Icon(Icons.book_online_outlined, color: Colors.white),
          Icon(Icons.analytics_outlined, color: Colors.white),
          Icon(Icons.person_2_outlined, color: Colors.white),
        ],
      ),
      body: pages[currenttabindex],
    );
  }
}
