import '../supabase_database_helper.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final VoidCallback onLogout;
  final VoidCallback? onProfileUpdated;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.onLogout,
    this.onProfileUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _surface = Color(0xFFF8FAF6);
  static const Color _shadow = Color(0xFFD6DED4);

  static const MethodChannel _galleryChannel =
  MethodChannel('myasset/gallery');

  int _assetCount = 0;
  int _totalValue = 0;

  bool _loading = true;
  bool _saving = false;
  bool _pickingImage = false;

  late String _name;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _name = widget.userName;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final assets =
      await SupabaseDatabaseHelper.instance.getAssets(widget.userId);

      final profile =
      await SupabaseDatabaseHelper.instance.getUserProfile(widget.userId);

      int total = 0;

      for (final asset in assets) {
        total += (asset['value'] as num?)?.toInt() ?? 0;
      }

      if (!mounted) return;

      setState(() {
        _assetCount = assets.length;
        _totalValue = total;

        if (profile != null) {
          _name = (profile['name'] ?? widget.userName).toString();
          _imagePath = profile['profile_image_path']?.toString();
        }

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat profil: $e')),
      );
    }
  }

  Future<void> _saveProfile({
    required String name,
    String? imagePath,
  }) async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final updated =
      await SupabaseDatabaseHelper.instance.updateUserProfile(
        userId: widget.userId,
        name: name,
        imagePath: imagePath,
      );

      if (!mounted) return;

      if (updated == 0) {
        throw Exception('Akun tidak ditemukan');
      }

      setState(() {
        _name = name.trim();

        if (imagePath != null) {
          _imagePath = imagePath;
        }
      });

      widget.onProfileUpdated?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan profil: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _name);

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Ubah Nama',
            style: TextStyle(
              fontFamily: 'Iris',
              fontWeight: FontWeight.bold,
              color: Color(0xFF263C2D),
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 50,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama pengguna',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              Navigator.pop(dialogContext, value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted || newName == null) return;

    if (newName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama tidak boleh kosong'),
        ),
      );
      return;
    }

    if (newName.trim() == _name) return;

    await _saveProfile(name: newName);
  }

  Future<void> _pickProfileImage() async {
    if (_pickingImage || _saving) return;

    setState(() {
      _pickingImage = true;
    });

    try {
      final path =
      await _galleryChannel.invokeMethod<String>('pickImage');

      if (!mounted || path == null || path.isEmpty) return;

      await _saveProfile(
        name: _name,
        imagePath: path,
      );
    } on PlatformException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal membuka galeri: ${e.message ?? e.code}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih foto: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _pickingImage = false;
        });
      }
    }
  }

  BoxDecoration _softDecoration({double radius = 20}) {
    return BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [
        BoxShadow(
          color: Colors.white,
          offset: Offset(-4, -4),
          blurRadius: 10,
        ),
        BoxShadow(
          color: _shadow,
          offset: Offset(4, 4),
          blurRadius: 10,
        ),
      ],
    );
  }

  String _rupiah(int value) {
    final formatted = value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
    );

    return 'Rp$formatted';
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _softDecoration(),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Iris',
                    fontSize: 12,
                    color: Color(0xFF819083),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Iris',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263C2D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileAvatar() {
    final initial = _name.trim().isNotEmpty
        ? _name.trim()[0].toUpperCase()
        : 'U';

    final imagePath = _imagePath;
    final hasImage =
        imagePath != null && File(imagePath).existsSync();

    return GestureDetector(
      onTap: _pickingImage || _saving
          ? null
          : _pickProfileImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? Image.file(
              File(imagePath),
              fit: BoxFit.cover,
            )
                : Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontFamily: 'Iris',
                  fontSize: 39,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Keluar dari MyAsset?',
          style: TextStyle(fontFamily: 'Iris'),
        ),
        content: const Text(
          'Kamu bisa login kembali kapan saja. '
              'Data aset kamu tidak akan dihapus.',
          style: TextStyle(fontFamily: 'Iris'),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 32),
          children: [
            const Text(
              'Profil Saya',
              style: TextStyle(
                fontFamily: 'Iris',
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263C2D),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Informasi akun MyAsset kamu',
              style: TextStyle(
                fontFamily: 'Iris',
                fontSize: 13,
                color: Color(0xFF7B8C7D),
              ),
            ),
            const SizedBox(height: 28),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 28,
              ),
              decoration: _softDecoration(radius: 24),
              child: Column(
                children: [
                  _profileAvatar(),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _pickingImage || _saving
                        ? null
                        : _pickProfileImage,
                    icon: const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 18,
                    ),
                    label: Text(
                      _pickingImage
                          ? 'Membuka galeri...'
                          : 'Ganti Foto',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Iris',
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263C2D),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pengguna MyAsset',
                    style: TextStyle(
                      fontFamily: 'Iris',
                      fontSize: 13,
                      color: Color(0xFF819083),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _saving ? null : _editName,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 17,
                    ),
                    label: const Text('Ubah Nama'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            const Text(
              'Informasi Aset',
              style: TextStyle(
                fontFamily: 'Iris',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263C2D),
              ),
            ),
            const SizedBox(height: 16),

            _infoCard(
              icon: Icons.inventory_2_outlined,
              title: 'Jumlah Aset',
              value: _loading
                  ? 'Memuat...'
                  : '$_assetCount aset',
            ),
            const SizedBox(height: 16),

            _infoCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Total Nilai Aset',
              value: _loading
                  ? 'Memuat...'
                  : _rupiah(_totalValue),
            ),

            const SizedBox(height: 28),

            const Text(
              'Pengaturan Akun',
              style: TextStyle(
                fontFamily: 'Iris',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263C2D),
              ),
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: _confirmLogout,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: _softDecoration(),
                child: const Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFD16C6C),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Keluar dari Akun',
                        style: TextStyle(
                          fontFamily: 'Iris',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD16C6C),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFD16C6C),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




