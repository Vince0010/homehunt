import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:homehunt/admin/add_room.dart';
import 'package:homehunt/admin/edit_room.dart';
import 'package:homehunt/services/database.dart';
import 'package:homehunt/components/analytics_summary.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const _primary = Color(0xFF5E60F8);
  Stream<QuerySnapshot>? roomItemStream;
  String selectedCategory = "Standard"; // Default category

  @override
  void initState() {
    super.initState();
    _loadRoomItems();
  }

  void _loadRoomItems() async {
    roomItemStream = await DatabaseMethods().getRoomItem(selectedCategory);
    setState(() {}); // Refresh UI
  }

  Widget _buildRoomItemList() {
    return StreamBuilder<QuerySnapshot>(
      stream: roomItemStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text(
            "No rooms found in this category.",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ));
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _buildRoomItemCard(snapshot.data!.docs[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildRoomItemCard(DocumentSnapshot ds) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                ds["Image"],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE5E7EB),
                  child: const Icon(Icons.home, size: 50, color: Colors.grey),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ds["Status"].toString().toLowerCase() == 'available'
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ds["Status"],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ds["Status"].toString().toLowerCase() == 'available'
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _buildEditIcon(ds),
                    _buildDeleteIcon(ds),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ds["Title"],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.black45),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ds["Address"],
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 14, color: Colors.black45),
                    const SizedBox(width: 4),
                    Text(
                      'Max guests: ${ds["MaxGuests"]}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    text: '₱${ds["Price"].toString()}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                    children: const [
                      TextSpan(
                        text: ' /day',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEditIcon(DocumentSnapshot ds) {
    return IconButton(
      icon: const Icon(Icons.edit),
      onPressed: () {
        String collectionName =
            selectedCategory; // Use selected category directly
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditRoomScreen(
              collectionName: collectionName,
              docID: ds.id,
              images: ds["Image"],
              title: ds["Title"],
              description: ds["Description"],
              address: ds["Address"],
              price: (ds["Price"]),
              maxGuests: (ds["MaxGuests"]),
              status: ds["Status"],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeleteIcon(DocumentSnapshot ds) {
    return IconButton(
      icon: const Icon(Icons.delete, color: Colors.red),
      onPressed: () async {
        bool confirm = await _showDeleteConfirmationDialog();
        if (confirm) {
          await DatabaseMethods().deleteRoomItem(selectedCategory, ds.id);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Room deleted successfully.")));
          _loadRoomItems(); // Refresh the list after deletion
        }
      },
    );
  }

  Future<bool> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Room"),
          content: const Text("Are you sure you want to delete this room?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel")),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Delete",
                    style: TextStyle(color: Colors.red))),
          ],
        );
      },
    ).then((value) => value ?? false);
  }

  // Method to create category buttons
  Widget _buildCategoryButton(String category) {
    final bool isSelected = selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category; // Update selected category
          _loadRoomItems(); // Fetch new data for the selected category
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF5E60F8), Color(0xFF6D70FA)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF5E60F8) : const Color(0xFFE2E5EE),
            width: 1.2,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
          ],
        ),
        child: Text(
          category,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

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
                              'Admin Dashboard',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Manage Rooms',
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

          // Welcome text
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EASE ESTATE',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Room Management',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Category buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryButton("Standard"),
                    const SizedBox(width: 8),
                    _buildCategoryButton("Deluxe"),
                    const SizedBox(width: 8),
                    _buildCategoryButton("Suites"),
                    const SizedBox(width: 8),
                    _buildCategoryButton("Specialty"),
                  ],
                ),
              ),
            ),
          ),

          // Analytics Summary
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const AnalyticsSummary(),
            ),
          ),

          // Section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'All Rooms',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Rooms list
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 400,
              child: _buildRoomItemList(),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      const AddRoom())); // Navigate to AddRoom
        },
        backgroundColor: _primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
