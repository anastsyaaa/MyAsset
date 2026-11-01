
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    throw StateError(
      'Konfigurasi Supabase belum tersedia. '
          'Jalankan Flutter dengan SUPABASE_URL dan '
          'SUPABASE_PUBLISHABLE_KEY.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyAsset',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Iris',
        primarySwatch: Colors.green,
      ),
      home: const LoginScreen(),
    );
  }
}
