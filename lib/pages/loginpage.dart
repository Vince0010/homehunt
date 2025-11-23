import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:homehunt/admin/admin_navbar.dart';
import 'package:homehunt/components/bottompagenav.dart';
import 'package:homehunt/helper/helperfunction.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;

  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Brand colors to match mock
  static const _primary = Color(0xFF5E60F8);
  static const _subtitle = Color(0xFF6B7280);

  // Text controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool get _canLogin =>
      emailController.text.trim().isNotEmpty &&
      passwordController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_onChanged);
    passwordController.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  // Route based on role
  Future<void> _routeAfterSignIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final adminSnap = await FirebaseFirestore.instance
        .collection('Admin')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    final isAdmin = adminSnap.docs.isNotEmpty;
    if (!mounted) return;

    if (isAdmin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminNavbar()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Bottompagenav()),
      );
    }
  }

  void _closeLoaderIfOpen() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void login() async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (!mounted) return;
      _closeLoaderIfOpen();
      await _routeAfterSignIn(); // Navigation
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _closeLoaderIfOpen();
        displayMessageToUser("Error", e.message ?? e.code, context);
      }
    } catch (e) {
      if (mounted) {
        _closeLoaderIfOpen();
        displayMessageToUser("Error", e.toString(), context);
      }
    }
  }

  Future<void> signInWithGoogle() async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          _closeLoaderIfOpen();
          return; // user canceled
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      if (!mounted) return;
      _closeLoaderIfOpen();
      await _routeAfterSignIn();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _closeLoaderIfOpen();
        displayMessageToUser("Error", e.message ?? e.code, context);
      }
    } catch (e) {
      if (mounted) {
        _closeLoaderIfOpen();
        displayMessageToUser("Error", e.toString(), context);
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      displayMessageToUser("Reset password", "Enter your email first.", context);
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      displayMessageToUser("Reset email sent", "Check your inbox.", context);
    } catch (e) {
      displayMessageToUser("Error", e.toString(), context);
    }
  }

  bool _obscureText = true;
  void _togglePasswordVisibility() {
    setState(() => _obscureText = !_obscureText);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandMark(primary: _primary),
              const SizedBox(height: 16),
              Text(
                "Let's get you Login!",
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your information below',
                style: theme.textTheme.bodyMedium?.copyWith(color: _subtitle),
              ),
              const SizedBox(height: 20),

              // Email / Password first
              _LabeledField(
                label: 'Email Address',
                hint: 'curtis.weaver@example.com',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                prefix: Icons.email_outlined,
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: 'Password',
                hint: 'Enter Password',
                controller: passwordController,
                obscure: _obscureText,
                prefix: Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: _togglePasswordVisibility,
                ),
              ),
              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _canLogin ? login : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    disabledBackgroundColor: const Color(0xFFEAEAEA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Login'),
                ),
              ),

              // Divider and Google last
              const SizedBox(height: 20),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Or login with'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: _GoogleButton(onTap: signInWithGoogle),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  TextButton(
                    onPressed: widget.onTap,
                    child: const Text('Register Now'),
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

/* -------------------------- UI helpers (mock style) ------------------------- */

class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final IconData? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;

  static const _primary = Color(0xFF5E60F8);

  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.prefix,
    this.suffix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: Color(0xFFE2E5EE)),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Colored Google "G" logo
          Image.asset(
            'assets/icons/google.png',
            width: 20,
            height: 20,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          const Text('Google', style: TextStyle(color: Colors.black87)),
        ],
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
