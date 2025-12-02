import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:homehunt/services/database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

class AddRoom extends StatefulWidget {
  const AddRoom({super.key});

  @override
  State<AddRoom> createState() => _AddRoomState();
}

class _AddRoomState extends State<AddRoom> {
  final List<String> roomItems = ['Standard', 'Deluxe', 'Suites', 'Specialty'];
  String? category, status;
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final addressController = TextEditingController();
  final priceController = TextEditingController();
  final maxGuestsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  Uint8List? selectedImageBytes;
  bool isLoading = false;

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
            content: Text("No image selected",
                style: TextStyle(fontSize: 20, fontFamily: 'ProtestStrike')),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> uploadItem() async {
    if (selectedImage != null ||
        selectedImageBytes != null &&
            titleController.text.isNotEmpty &&
            descController.text.isNotEmpty &&
            addressController.text.isNotEmpty &&
            priceController.text.isNotEmpty &&
            maxGuestsController.text.isNotEmpty &&
            status != null) {
      setState(() {
        isLoading = true;
      });

      try {
        final addId = randomAlphaNumeric(10);
        final firebaseStorageRef =
            FirebaseStorage.instance.ref().child("Image").child(addId);

        // Upload the image
        String downloadUrl;
        if (selectedImage != null) {
          // Mobile case
          final task = firebaseStorageRef.putFile(selectedImage!);
          downloadUrl = await (await task).ref.getDownloadURL();
        } else {
          // Web case
          final byteData = selectedImageBytes!;
          final uploadTask = firebaseStorageRef.putData(byteData);
          downloadUrl = await (await uploadTask).ref.getDownloadURL();
        }

        // Add room item with details
        final addItem = {
          "Image": downloadUrl,
          "Title": titleController.text,
          "Description": descController.text,
          "Address": addressController.text,
          "Price": double.parse(priceController.text), // Store as number for analytics
          "MaxGuests": maxGuestsController.text,
          "Status": status,
        };

        await DatabaseMethods().addRoomItem(addItem, category!).then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.orangeAccent,
              content: Text("Room Item has been added Successfully",
                  style: TextStyle(fontSize: 18, fontFamily: 'ProtestStrike')),
            ),
          );
          Navigator.pop(context);
        });
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to upload room item: $e"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please fill in all fields and select an image",
                style: TextStyle(fontSize: 18, fontFamily: 'ProtestStrike')),
            backgroundColor: Colors.red),
      );
    }
  }

  Widget buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, bool numbersOnly = false}) {
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
              hintText: "Enter $label",
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget buildDropdown(String label, List<String> items, String? selectedValue,
      ValueChanged<String?> onChanged) {
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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              items: items
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
              dropdownColor: Colors.white,
              hint: const Text(
                "Select option",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              iconSize: 28,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF5E60F8),
              ),
              value: selectedValue,
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
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
                      'Add Room',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload Room Image',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: getImage,
                      child: Center(
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.black, width: 1.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: selectedImageBytes == null &&
                                    selectedImage == null
                                ? const Icon(Icons.camera_alt_outlined,
                                    color: Colors.black)
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: kIsWeb
                                        ? Image.memory(selectedImageBytes!,
                                            fit: BoxFit.cover) // For web
                                        : Image.file(selectedImage!,
                                            fit: BoxFit.cover), // For mobile
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    buildTextField("Title", titleController),
                    const SizedBox(height: 16),
                    buildTextField("Description", descController, maxLines: 6),
                    const SizedBox(height: 16),
                    buildTextField("Address", addressController),
                    const SizedBox(height: 16),
                    buildTextField("Price", priceController, numbersOnly: true),
                    const SizedBox(height: 16),
                    buildTextField("Maximum Guests", maxGuestsController),
                    const SizedBox(height: 16),
                    buildDropdown("Select Category", roomItems, category,
                        (value) => setState(() => category = value)),
                    const SizedBox(height: 16),
                    buildDropdown(
                        "Select Status",
                        ["Available", "Not Available"],
                        status,
                        (value) => setState(() => status = value)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5E60F8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        onPressed: uploadItem,
                        child: const Text(
                          'Add Room',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
