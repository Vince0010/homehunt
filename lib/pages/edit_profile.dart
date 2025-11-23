import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const _primary = Color(0xFF5E60F8);
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  DateTime? _dob;
  String _gender = 'Male';
  String? _photoUrl;
  XFile? _pickedFile;
  bool _loading = true;
  final _formKey = GlobalKey<FormState>();

  final _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
    final data = doc.data() ?? {};
    _nameCtrl.text = (data['displayName'] ?? _user!.displayName ?? '');
    _phoneCtrl.text = (data['phone'] ?? _user!.phoneNumber ?? '');
    _photoUrl = data['photoUrl'] ?? _user!.photoURL;
    final ts = data['dateOfBirth'];
    if (ts is Timestamp) _dob = ts.toDate();
    _gender = (data['gender'] ?? 'Male');
    setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (file != null) {
      setState(() => _pickedFile = file);
      // Upload logic placeholder
      // After upload, set _photoUrl to remote URL
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _user == null) return;
    setState(() => _loading = true);

    // Optional: upload picked file to storage (not implemented here)
    final data = {
      'displayName': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'gender': _gender,
      'dateOfBirth': _dob != null ? Timestamp.fromDate(_dob!) : null,
      if (_photoUrl != null) 'photoUrl': _photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set(
          data,
          SetOptions(merge: true),
        );

    if (_user!.displayName != _nameCtrl.text.trim()) {
      await _user!.updateDisplayName(_nameCtrl.text.trim());
    }
    setState(() => _loading = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: const Color(0xFFE2E5EE),
                          backgroundImage: _pickedFile != null
                              ? (kIsWeb ? NetworkImage(_pickedFile!.path) : FileImage(File(_pickedFile!.path)) as ImageProvider)
                              : (_photoUrl != null && _photoUrl!.isNotEmpty
                                  ? NetworkImage(_photoUrl!)
                                  : null),
                          child: (_photoUrl == null || _photoUrl!.isEmpty) && _pickedFile == null
                              ? const Icon(Icons.person, size: 40, color: Colors.black45)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF5E60F8),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _field(
                    label: 'Name',
                    controller: _nameCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  _field(
                    label: 'Mobile Number',
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                        initialDate: _dob ?? DateTime(2000, 1, 1),
                      );
                      if (picked != null) setState(() => _dob = picked);
                    },
                    child: AbsorbPointer(
                      child: _field(
                        label: 'Date of Birth',
                        controller: TextEditingController(
                          text: _dob != null
                              ? '${_dob!.year}-${_dob!.month.toString().padLeft(2,'0')}-${_dob!.day.toString().padLeft(2,'0')}'
                              : '',
                        ),
                        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Gender', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _genderRadio('Male'),
                      const SizedBox(width: 16),
                      _genderRadio('Female'),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _save,
                      child: const Text('Update', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _genderRadio(String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: _gender,
          activeColor: _primary,
          onChanged: (v) => setState(() => _gender = v!),
        ),
        Text(value),
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF5E60F8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF5E60F8), width: 2),
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}