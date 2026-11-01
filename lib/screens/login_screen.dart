import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_gradient_background.dart';
import 'register_screen.dart';
import 'main_navigation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller untuk form input
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomGradientBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Logo & Teks "MyAsset" yang Sejajar di Tengah
                Center(
                  child: Transform.translate(
                    offset: const Offset(-10, 0), // Penyesuaian posisi tengah visual
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logo_myasset.png',
                          height: 100,
                        ),

                        const SizedBox(width: 16),

                        const Text(
                            'MyAsset',
                            style: const TextStyle(
                              fontFamily: 'CustomMono',
                              fontSize: 38,
                              fontWeight: FontWeight.normal,
                              color: AppColors.primaryGreen,
                            ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 0),
                const Text(
                  'Aset tertata, hidup lebih tenang.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryGreen,
                  ),
                ),

                const SizedBox(height: 50),

                const Text(
                  'Selamat datang kembali',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 0),
                const Text(
                  'Masuk untuk melihat aset pribadi kamu.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30), // Jarak sebelum kotak Email muncul


                // 2. Input Email dengan Shadow
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryGreen),
                      hintText: 'Email',
                      filled: true,
                      fillColor: const Color(0xFFF8FAF6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Input Password dengan Shadow
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAF6),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFFD6DED4),
                        offset: Offset(4, 4),
                        blurRadius: 10,
                      ),
                      BoxShadow(
                        color: Colors.white,
                        offset: Offset(-4, -4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.key_outlined, color: AppColors.primaryGreen),
                      hintText: 'Password',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // 4. Tombol Masuk dengan Gradasi & Shadow + SQLite Validation
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFFFFFFFF),
                        offset: Offset(-5, -5),
                        blurRadius: 12,
                      ),
                      BoxShadow(
                        color: Color(0xFF9EBFA8),
                        offset: Offset(5, 5),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: ElevatedButton(

                    onPressed: () async {
                      final email = _emailController.text.trim();
                      final password = _passwordController.text;

                      if (email.isEmpty || password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email dan Password harus diisi!'),
                          ),
                        );
                        return;
                      }

                      try {
                        final response =
                        await Supabase.instance.client.auth.signInWithPassword(
                          email: email,
                          password: password,
                        );

                        if (!context.mounted) return;

                        if (response.user != null && response.session != null) {
                          final userId = response.user!.id;

                          final profile = await Supabase.instance.client
                              .from('users')
                              .select('name')
                              .eq('id', userId)
                              .maybeSingle();

                          if (!context.mounted) return;

                          final savedName = (profile?['name'] as String?)?.trim() ?? '';
                          final userName = savedName.isNotEmpty
                              ? savedName
                              : (response.user!.email?.split('@').first ?? 'Pengguna');

                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => MainNavigation(
                                userId: userId,
                                userName: userName,
                              ),
                            ),
                                (route) => false,
                          );
                        }


                      } on AuthException catch (e) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Login gagal: ${e.message}')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gagal terhubung. Periksa koneksi internet.'),
                          ),
                        );
                      }
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Tautan Navigasi Register
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Belum Punya Akun? '),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                      child: const Text('Daftar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}