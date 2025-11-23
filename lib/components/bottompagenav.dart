import 'package:flutter/material.dart';
import 'package:homehunt/pages/home.dart';
import 'package:homehunt/pages/booking.dart';
import 'package:homehunt/pages/profile.dart';          // functional profile
// (Create favorites_page.dart & notifications_page.dart if you want separate files)

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
    BookingPage(price: ''),
    _FavoritesStub(),
    _NotificationsStub(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
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
            icon: Icon(Icons.notifications_none, color: _index == 3 ? _primary : Colors.black54),
            selectedIcon: Icon(Icons.notifications, color: _primary),
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
}

// Temporary stubs (replace with real pages later)
class _FavoritesStub extends StatelessWidget {
  const _FavoritesStub();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Favorites'));
}

class _NotificationsStub extends StatelessWidget {
  const _NotificationsStub();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Notifications'));
}
