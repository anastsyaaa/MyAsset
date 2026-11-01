import '../supabase_database_helper.dart';

import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'asset_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final String userId;
  final ValueChanged<String>? onCategoryTap;
  final VoidCallback? onProfileTap;

  const DashboardScreen({
    super.key,
    required this.userName,
    required this.userId,
    this.onCategoryTap,
    this.onProfileTap,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> _dashboardFuture;

  static const Color _surface = Color(0xFFF8FAF6);
  static const Color _shadow = Color(0xFFD6DED4);

  static const List<String> _defaultCategories = [
    'Elektronik',
    'Kendaraan',
    'Perhiasan',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  void _loadDashboard() {
    _dashboardFuture = _fetchDashboardData();
  }

  Future<_DashboardData> _fetchDashboardData() async {
    final assets =
    await SupabaseDatabaseHelper.instance.getAssets(widget.userId);

    final customCategories =
    await SupabaseDatabaseHelper.instance.getCustomCategories(widget.userId);

    final profile =
    await SupabaseDatabaseHelper.instance.getUserProfile(widget.userId);

    return _DashboardData(
      assets: assets,
      customCategories: customCategories,
      profile: profile,
    );
  }

  Future<void> _refreshDashboard() async {
    setState(_loadDashboard);
    await _dashboardFuture;
  }

  Future<void> _openAsset(Map<String, dynamic> asset) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AssetDetailScreen(
          userId: widget.userId,
          asset: asset,
        ),
      ),
    );

    if (!mounted) return;

    await _refreshDashboard();
  }

  String _rupiah(int value) {
    final formatted = value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => '.',
    );

    return 'Rp $formatted';
  }

  IconData _categoryIcon(String category) {
    final name = category.trim().toLowerCase();

    if (name.contains('elektronik') ||
        name.contains('laptop') ||
        name.contains('komputer') ||
        name.contains('gadget') ||
        name.contains('handphone')) {
      return Icons.laptop_mac_outlined;
    }

    if (name.contains('kendaraan') ||
        name.contains('mobil') ||
        name.contains('motor') ||
        name.contains('sepeda')) {
      return Icons.directions_car_outlined;
    }

    if (name.contains('perhiasan') ||
        name.contains('emas') ||
        name.contains('berlian')) {
      return Icons.diamond_outlined;
    }

    if (name.contains('rumah') || name.contains('hunian')) {
      return Icons.home_outlined;
    }

    if (name.contains('properti') ||
        name.contains('apartemen') ||
        name.contains('gedung') ||
        name.contains('ruko')) {
      return Icons.apartment_outlined;
    }

    if (name.contains('tanah') ||
        name.contains('lahan') ||
        name.contains('kebun')) {
      return Icons.landscape_outlined;
    }

    if (name.contains('furnitur') ||
        name.contains('furniture') ||
        name.contains('mebel') ||
        name.contains('kursi')) {
      return Icons.chair_outlined;
    }

    if (name.contains('pakaian') || name.contains('baju')) {
      return Icons.checkroom_outlined;
    }

    if (name.contains('sepatu')) {
      return Icons.hiking_outlined;
    }

    if (name.contains('jam')) {
      return Icons.watch_outlined;
    }

    if (name.contains('tas')) {
      return Icons.shopping_bag_outlined;
    }

    if (name.contains('buku') || name.contains('novel')) {
      return Icons.menu_book_outlined;
    }

    if (name.contains('musik')) {
      return Icons.music_note_outlined;
    }

    if (name.contains('olahraga')) {
      return Icons.sports_soccer_outlined;
    }

    if (name.contains('koleksi')) {
      return Icons.collections_bookmark_outlined;
    }

    if (name.contains('peralatan')) {
      return Icons.handyman_outlined;
    }

    if (name.contains('kamera')) {
      return Icons.camera_alt_outlined;
    }

    if (name.contains('investasi')) {
      return Icons.trending_up_outlined;
    }

    return Icons.category_outlined;
  }

  List<String> _categories(
      List<Map<String, dynamic>> assets,
      List<String> customCategories,
      ) {
    final result = <String>[..._defaultCategories];

    void addCategory(String value) {
      final name = value.trim();

      if (name.isEmpty) return;

      final exists = result.any(
            (item) => item.toLowerCase() == name.toLowerCase(),
      );

      if (!exists) result.add(name);
    }

    for (final category in customCategories) {
      addCategory(category);
    }

    for (final asset in assets) {
      addCategory(asset['category']?.toString() ?? '');
    }

    return result;
  }

  int _categoryCount(
      List<Map<String, dynamic>> assets,
      String category,
      ) {
    return assets.where((asset) {
      final name =
          asset['category']?.toString().trim().toLowerCase() ?? '';

      return name == category.trim().toLowerCase();
    }).length;
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

  Widget _categoryCard(
      String category,
      int count,
      ) {
    return InkWell(
      onTap: () => widget.onCategoryTap?.call(category),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: _softDecoration(),
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 12,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _categoryIcon(category),
              color: AppColors.primaryGreen,
              size: 26,
            ),
            const SizedBox(height: 7),
            Text(
              category,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Iris',
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count aset',
              style: const TextStyle(
                fontFamily: 'Iris',
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _softDecoration(radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Iris',
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Iris',
                fontSize: title == 'Total Nilai Aset' ? 16 : 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Iris',
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _assetCard(Map<String, dynamic> asset) {
    final name = asset['name']?.toString() ?? 'Aset';
    final category =
        asset['category']?.toString() ?? 'Lainnya';
    final value = (asset['value'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openAsset(asset),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: _softDecoration(),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _categoryIcon(category),
                    color: AppColors.primaryGreen,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Iris',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: const TextStyle(
                          fontFamily: 'Iris',
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _rupiah(value),
                        style: const TextStyle(
                          fontFamily: 'Iris',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primaryGreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dashboardAvatar(String? imagePath) {
    final hasImage = imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();

    return Tooltip(
      message: 'Buka Profil',
      child: InkWell(
        onTap: widget.onProfileTap,
        customBorder: const CircleBorder(),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white,
          backgroundImage: hasImage
              ? FileImage(File(imagePath))
              : null,
          child: hasImage
              ? null
              : const Icon(
            Icons.person_outline,
            color: AppColors.primaryGreen,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: FutureBuilder<_DashboardData>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryGreen,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Gagal mengambil data Dashboard.\n'
                        '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Iris'),
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            final assets = data.assets;

            final categories = _categories(
              assets,
              data.customCategories,
            );

            final profile = data.profile;

            final profileName =
                profile?['name']?.toString() ?? widget.userName;

            final profileImagePath =
            profile?['profile_image_path']?.toString();

            final totalAssets = assets.length;

            final totalValue = assets.fold<int>(
              0,
                  (sum, asset) =>
              sum + ((asset['value'] as num?)?.toInt() ?? 0),
            );

            final recentAssets = assets.take(3).toList();

            return RefreshIndicator(
              onRefresh: _refreshDashboard,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  // HEADER
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Image.asset(
                            'assets/logo_myasset.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'MyAsset',
                          style: TextStyle(
                            fontFamily: 'CustomMono',
                            fontSize: 30,
                            fontWeight: FontWeight.normal,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                      _dashboardAvatar(profileImagePath),
                    ],
                  ),

                  const SizedBox(height: 26),

                  Text(
                    'Halo, $profileName!',
                    style: const TextStyle(
                      fontFamily: 'Iris',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Berikut ringkasan aset pribadi kamu',
                    style: TextStyle(
                      fontFamily: 'Iris',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // RINGKASAN
                  Row(
                    children: [
                      _summaryCard(
                        title: 'Total Aset',
                        value: '$totalAssets barang',
                        subtitle: totalAssets == 0
                            ? 'Belum ada data'
                            : 'Aset tersimpan',
                        icon: Icons.inventory_2_outlined,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 12),
                      _summaryCard(
                        title: 'Total Nilai Aset',
                        value: _rupiah(totalValue),
                        subtitle: 'Nilai seluruh aset kamu',
                        icon: Icons.monetization_on_outlined,
                        color: Colors.amber.shade800,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Kategori Aset',
                    style: TextStyle(
                      fontFamily: 'Iris',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 104,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];

                      return _categoryCard(
                        category,
                        _categoryCount(assets, category),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Aset Terbaru',
                    style: TextStyle(
                      fontFamily: 'Iris',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (recentAssets.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 28,
                      ),
                      decoration: _softDecoration(radius: 22),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: AppColors.primaryGreen,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Belum ada aset tersimpan.',
                            style: TextStyle(
                              fontFamily: 'Iris',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Tekan tombol (+) untuk menambahkan aset.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Iris',
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...recentAssets.map(_assetCard),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardData {
  final List<Map<String, dynamic>> assets;
  final List<String> customCategories;
  final Map<String, dynamic>? profile;

  const _DashboardData({
    required this.assets,
    required this.customCategories,
    required this.profile,
  });
}



