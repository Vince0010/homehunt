import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:homehunt/admin/admin_navbar.dart';
import 'package:homehunt/auth/login_or_register.dart';
import 'package:homehunt/components/bottompagenav.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // user is logged in
          if (snapshot.hasData) {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              return const Bottompagenav();
            }

            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('Admin')
                  .where('email', isEqualTo: user.email)
                  .limit(1)
                  .get(),
              builder: (context, roleSnap) {
                if (roleSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (roleSnap.hasError) {
                  return const Bottompagenav();
                }

                final isAdmin = roleSnap.data?.docs.isNotEmpty == true;
                return isAdmin ? const AdminNavbar() : const Bottompagenav();
              },
            );
          } else {
            // user is NOT logged in
            return const LoginOrRegister();
          }
        },
      ),
    );
  }
}
