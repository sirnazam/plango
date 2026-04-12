import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://ywkzosryqzoikweswubt.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3a3pvc3J5cXpvaWt3ZXN3dWJ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU4OTIyNzgsImV4cCI6MjA5MTQ2ODI3OH0.u0JMRwXBDyKayqg6IUysr_8X-2N3QZRkuhp02V6_UFs',
    );
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plango',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BCD4),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}