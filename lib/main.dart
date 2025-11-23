import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:homehunt/components/bottompagenav.dart';
import 'package:homehunt/firebase_options.dart'; // ensure this exists

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5E60F8);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
          background: const Color(0xFFF5F6FA),
          surface: Colors.white,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: primary.withOpacity(.15),
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            final sel = states.contains(MaterialState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: sel ? primary : Colors.black54,
            );
          }),
          iconTheme: MaterialStateProperty.resolveWith((states) {
            final sel = states.contains(MaterialState.selected);
            return IconThemeData(color: sel ? primary : Colors.black54);
          }),
        ),
        cardColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black54),
      ),
      home: const Bottompagenav(),
    );
  }
}
