import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homehunt/pages/home.dart';
import 'package:homehunt/pages/bookings_list.dart';
import 'package:homehunt/pages/favorites_page.dart';
import 'package:homehunt/pages/alerts_page.dart';
import 'package:homehunt/pages/profile.dart';

class Bottompagenav extends StatefulWidget {
  const Bottompagenav({super.key});
  @override
  State<Bottompagenav> createState() => _BottompagenavState();
}

class _BottompagenavState extends State<Bottompagenav> {
  static const _primary = Color(0xFF5E60F8);
  int _index = 0;

  final _pages = const [
    HomePage(),
    BookingsListPage(),
    FavoritesPage(),
    AlertsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: _index == 0 ? _primary : Colors.black54),
            selectedIcon: Icon(Icons.home, color: _primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined, color: _index == 1 ? _primary : Colors.black54),
            selectedIcon: Icon(Icons.calendar_month, color: _primary),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border, color: _index == 2 ? _primary : Colors.black54),
            selectedIcon: Icon(Icons.favorite, color: _primary),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: _buildAlertsIcon(user?.uid),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: _index == 4 ? _primary : Colors.black54),
            selectedIcon: Icon(Icons.person, color: _primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsIcon(String? userId) {
    if (userId == null) {
      return Icon(Icons.notifications_none, color: _index == 3 ? _primary : Colors.black54);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('alerts')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.docs.length ?? 0;
        
        return Stack(
          children: [
            Icon(
              _index == 3 ? Icons.notifications : Icons.notifications_none,
              color: _index == 3 ? _primary : Colors.black54,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
