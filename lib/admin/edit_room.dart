import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:homehunt/services/database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

class EditRoomScreen extends StatefulWidget {
  final String collectionName;
  final String docID;
  final String images;
  final String title;
  final String description;
  final String address;
  final dynamic price;
  final dynamic maxGuests;
  final String status;

  const EditRoomScreen({
    super.key,
    required this.collectionName,
    required this.docID,
    required this.images,
    required this.title,
    required this.description,
    required this.address,
    required this.price,
    required this.maxGuests,
    required this.status,
  });

  @override
  _EditRoomScreenState createState() => _EditRoomScreenState();
}

class _EditRoomScreenState extends State<EditRoomScreen> {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final addressController = TextEditingController();
  final priceController = TextEditingController();
  final maxGuestsController = TextEditingController();
  String? status;
  final ImagePicker _picker = ImagePicker();
  File? selectedImage; // For mobile
  Uint8List? selectedImageBytes; // For web image storage

  @override
  void initState() {
    super.initState();
    // Initialize text controllers with the current room details
    titleController.text = widget.title;
    descController.text = widget.description;
    addressController.text = widget.address;
    priceController.text = widget.price is String ? widget.price : widget.price.toString();
    maxGuestsController.text = widget.maxGuests is String ? widget.maxGuests : widget.maxGuests.toString();
    status = widget.status; // Set the initial status
  }

  Future<void> getImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
        selectedImageBytes = null;
      });

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          selectedImage = null;
          selectedImageBytes = bytes;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("No image selected"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateRoom() async {
    Map<String, dynamic> updatedData = {
      "Title": titleController.text,
      "Description": descController.text,
      "Address": addressController.text,
      "Price": double.parse(priceController.text), // Store as number for analytics
      "MaxGuests": maxGuestsController.text,
      "Status": status,
    };

    if (selectedImage != null || selectedImageBytes != null) {
      String? downloadUrl;
      final firebaseStorageRef =
          FirebaseStorage.instance.ref().child("Image").child(widget.docID);
      try {
        // Upload the new image and get the download URL
        if (selectedImage != null) {
          // Mobile case
          final task = firebaseStorageRef.putFile(selectedImage!);
          downloadUrl = await (await task).ref.getDownloadURL();
        } else {
          // Web case
          final uploadTask = firebaseStorageRef.putData(selectedImageBytes!);
          downloadUrl = await (await uploadTask).ref.getDownloadURL();
        }

        // Update the image URL in the data
        updatedData["Image"] = downloadUrl;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to upload image: $e")));
        return;
      }
    } else {
      // If no new image is selected, retain the old image URL
      updatedData["Image"] = widget.images;
    }

    try {
      // Update the document in Firestore
      await DatabaseMethods()
          .updateRoomItem(widget.collectionName, widget.docID, updatedData);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Room updated successfully.")));
      Navigator.pop(context); // Go back to the previous screen
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error updating room: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
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
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Edit Room',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _updateRoom,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: const Row(
                        children: [
                          Icon(Icons.save, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEditField('Title', titleController),
              const SizedBox(height: 16),
              _buildEditField('Description', descController, maxLines: 6),
              const SizedBox(height: 16),
              _buildEditField('Address', addressController),
              const SizedBox(height: 16),
              _buildEditField('Price', priceController, numbersOnly: true),
              const SizedBox(height: 16),
              _buildEditField('Max Guests', maxGuestsController),
              const SizedBox(height: 16),
              _buildStatusDropdown(),
              const SizedBox(height: 16),
              _buildImagePicker(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool numbersOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: numbersOnly ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Enter $label',
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: status,
              items: <String>['Available', 'Not Available'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  status = newValue!;
                });
              },
              isExpanded: true,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF5E60F8),
              ),
              iconSize: 28,
              dropdownColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Room Image',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: getImage,
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
            child: selectedImageBytes == null && selectedImage == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 48,
                        color: Color(0xFF5E60F8),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap to select image',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                        : Image.file(selectedImage!, fit: BoxFit.cover),
                  ),
          ),
        ),
      ],
    );
  }
}
