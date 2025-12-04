import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homehunt/pages/terms_and_conditions.dart';
import 'package:homehunt/components/bottompagenav.dart';
import 'package:homehunt/admin/admin_announcement.dart';

class AdminProfile extends StatefulWidget {
  const AdminProfile({super.key});

  @override
  _AdminProfileState createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  String email = "";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchAdminEmail();
  }

  // Fetch the admin's email from Firestore
  Future<void> _fetchAdminEmail() async {
    String adminId = 'mlGIA7f5c2SSyNMjt8FO';

    // Fetch the admin's email from Firestore
    DocumentSnapshot adminDoc =
        await _firestore.collection('Admin').doc(adminId).get();

    if (adminDoc.exists) {
      setState(() {
        email = adminDoc['email'] ?? "No email found";
      });
    } else {
      setState(() {
        email = "Admin not found in Firestore";
      });
    }
  }

  // Run price migration
  // 
  // Future<void> _runMigration() async {
  //   setState(() {
  //     isMigrating = true;
  //   });
  //
  //   try {
  //     await MigrationService.migrateRoomPrices();
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text("✅ Migration complete! Room prices updated."),
  //         backgroundColor: Colors.green,
  //         duration: Duration(seconds: 3),
  //       ),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text("❌ Migration error: $e"),
  //         backgroundColor: Colors.red,
  //         duration: const Duration(seconds: 3),
  //       ),
  //     );
  //   } finally {
  //     setState(() {
  //       isMigrating = false;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header with gradient
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
                              'Welcome back,',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Admin Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ClipOval(
                        child: Container(
                          color: Colors.white,
                          width: 45,
                          height: 45,
                          child: Image.asset(
                            "images/12.jpg",
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Title section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Account Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Email display
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
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
                child: Row(
                  children: [
                    const Icon(Icons.email, color: Color(0xFF5E60F8), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Email Address',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Make Announcement button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminAnnouncementPage()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.green.shade200, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.campaign, color: Colors.green.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Make Announcement',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Send announcement to all users',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.black45, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TermsAndConditionsPage()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
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
                  child: Row(
                    children: [
                      const Icon(Icons.description, color: Color(0xFF5E60F8), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Terms and Conditions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Review our policies',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.black45, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // Data Migration button - COMMENTED OUT (Migration already completed)
          // SliverToBoxAdapter(
          //   child: Padding(
          //     padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          //     child: GestureDetector(
          //       onTap: isMigrating ? null : _runMigration,
          //       child: Container(
          //         decoration: BoxDecoration(
          //           color: Colors.blue.shade50,
          //           borderRadius: BorderRadius.circular(18),
          //           border: Border.all(color: Colors.blue.shade200, width: 1),
          //         ),
          //         padding: const EdgeInsets.all(12),
          //         child: Row(
          //           children: [
          //             if (isMigrating)
          //               SizedBox(
          //                 width: 24,
          //                 height: 24,
          //                 child: CircularProgressIndicator(
          //                   strokeWidth: 2.5,
          //                   valueColor: AlwaysStoppedAnimation<Color>(
          //                     Colors.blue.shade700,
          //                   ),
          //                 ),
          //               )
          //             else
          //               Icon(Icons.sync, color: Colors.blue.shade700, size: 24),
          //             const SizedBox(width: 12),
          //             Expanded(
          //               child: Column(
          //                 crossAxisAlignment: CrossAxisAlignment.start,
          //                 children: [
          //                   Text(
          //                     'Data Migration',
          //                     style: TextStyle(
          //                       fontSize: 16,
          //                       fontWeight: FontWeight.w600,
          //                       color: Colors.blue.shade700,
          //                     ),
          //                   ),
          //                   const SizedBox(height: 2),
          //                   Text(
          //                     isMigrating 
          //                       ? 'Updating room prices...' 
          //                       : 'Update room prices to new format',
          //                     style: TextStyle(
          //                       fontSize: 12,
          //                       color: Colors.blue.shade600,
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //             ),
          //             if (!isMigrating)
          //               Icon(Icons.arrow_forward, color: Colors.blue.shade400, size: 20),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          // ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Logout button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () async {
                  // Sign out from Firebase
                  await FirebaseAuth.instance.signOut();
                  // Navigate to Bottompagenav (main home with navbar)
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Bottompagenav()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.red.shade200, width: 1),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red.shade700, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
