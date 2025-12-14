import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'edit_profile.dart';
import 'terms_and_conditions.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _primary = Color(0xFF5E60F8);
  User? get _user => FirebaseAuth.instance.currentUser;

  Stream<DocumentSnapshot<Map<String,dynamic>>>? _userStream;

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .snapshots();
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_userStream == null) {
      return const Center(child: Text('Not signed in'));
    }
    return StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(
      stream: _userStream,
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};
        final name = (data['displayName'] ?? _user?.displayName ?? 'User').toString();
        final email = (_user?.email ?? data['email'] ?? '').toString();
        final photo = (data['photoUrl'] ?? _user?.photoURL) as String?;
        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header(name: name, email: email, photoUrl: photo)),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _tile(
                      icon: Icons.edit,
                      text: 'Edit Profile',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditProfilePage()),
                      ),
                    ),
                    _tile(
                      icon: Icons.lock,
                      text: 'Change Password',
                      onTap: () async {
                        if (_user != null) {
                          await _user!.sendPasswordResetEmail(email: _user!.email!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reset email sent')),
                          );
                        }
                      },
                    ),
                    _tile(
                      icon: Icons.description,
                      text: 'Terms & Conditions',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsAndConditionsPage()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _logout,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Logout', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tile({required IconData icon, required String text, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        leading: Icon(icon, color: Colors.black54),
        title: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black38),
        onTap: onTap,
      ),
    );
  }

  bool _darkMode = false;
  Widget _darkModeTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: ListTile(
        leading: const Icon(Icons.dark_mode, color: Colors.black54),
        title: const Text('Dark Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: Switch(
          value: _darkMode,
          activeColor: _primary,
          onChanged: (v) {
            setState(() => _darkMode = v);
            // Optional: persist preference
          },
        ),
        onTap: () => setState(() => _darkMode = !_darkMode),
      ),
    );
  }

  void _showTextDialog(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}

extension on User {
  Future<void> sendPasswordResetEmail({required String email}) async {}
}

class _Header extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;
  const _Header({required this.name, required this.email, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5E60F8), Color(0xFF6D70FA), Color(0xFF8E90FF)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white24,
            backgroundImage: photoUrl != null && photoUrl!.isNotEmpty ? NetworkImage(photoUrl!) : null,
            child: (photoUrl == null || photoUrl!.isEmpty)
                ? const Icon(Icons.person, size: 40, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(email,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w400),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage()));
            },
          )
        ],
      ),
    );
  }
}
