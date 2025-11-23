import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:homehunt/helper/helperfunction.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;

  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const _primary = Color(0xFF5E60F8);
  static const _subtitle = Color(0xFF6B7280);

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPwController = TextEditingController();

  bool _obscurePw = true;
  bool _obscureConfirm = true;

  Future<void> registerUser() async {
    // Show loader
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // Validate
    if (passwordController.text.trim() != confirmPwController.text.trim()) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        displayMessageToUser("Error", "Passwords don't match", context);
      }
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await _createUserDocument(userCredential);

      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        displayMessageToUser("Success", "Account created.", context);
        // OPTIONAL: Navigate now
        // Navigator.pushReplacement(...);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        displayMessageToUser("Error", e.message ?? e.code, context);
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        displayMessageToUser("Error", e.toString(), context);
      }
    }
  }

  Future<void> _createUserDocument(UserCredential cred) async {
    final user = cred.user;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection("Users")
        .doc(user.email)
        .set({
      'email': user.email,
      'username': usernameController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandMark(primary: _primary),
              const SizedBox(height: 16),
              Text('Register Now!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 6),
              Text('Enter your information below',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.white70)),
              const SizedBox(height: 20),

              _LabeledField(
                label: 'Name',
                hint: 'Your full name',
                controller: usernameController,
                prefix: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: 'Email Address',
                hint: 'you@example.com',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                prefix: Icons.email_outlined,
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: 'Password',
                hint: 'Enter Password',
                controller: passwordController,
                prefix: Icons.lock_outline,
                obscure: _obscurePw,
                suffix: IconButton(
                  icon: Icon(_obscurePw
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _obscurePw = !_obscurePw),
                ),
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: 'Confirm Password',
                hint: 'Re-enter Password',
                controller: confirmPwController,
                prefix: Icons.lock_outline,
                obscure: _obscureConfirm,
                suffix: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Register'),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already a member? '),
                  TextButton(
                    onPressed: widget.onTap,
                    child: const Text('Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData? prefix;
  final Widget? suffix;
  final bool readOnly;
  final bool obscure;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;

  static const _primary = Color(0xFF5E60F8);

  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    this.prefix,
    this.suffix,
    this.readOnly = false,
    this.obscure = false,
    this.onTap,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        fillColor: Colors.white,
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E5EE), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5E60F8), width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.black54),
        hintStyle: const TextStyle(color: Colors.black38),
        prefixIcon: prefix != null ? Icon(prefix, color: Colors.black54) : null,
        suffixIcon: suffix,
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  final Color primary;
  const _BrandMark({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: primary, width: 2),
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            text: 'live ',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: primary, fontWeight: FontWeight.w600),
            children: const [
              TextSpan(text: 'Green', style: TextStyle(color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
}
