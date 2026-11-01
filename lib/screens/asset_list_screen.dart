import '../supabase_database_helper.dart';

import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'asset_detail_screen.dart';

class AssetListScreen extends StatefulWidget {
  final String userId;
  final String initialCategory;

  const AssetListScreen({
    super.key,
    required this.userId,
    this.initialCategory = 'Semua',
  });

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  static const Color _surface = Color(0xFFF8FAF6);
  static const Color _shadow = Color(0xFFD6DED4);

  static const List<String> _defaultCategories = [
    'Elektronik',
    'Kendaraan',
    'Perhiasan',
    'Lainnya',
    'Properti',
    'Rumah',
    'Tanah',
    'Apartemen',
    'Furnitur',
    'Pakaian',
    'Tas',
    'Sepatu',
    'Jam Tangan',
    'Buku',
    'Alat Musik',
    'Olahraga',
    'Koleksi',
    'Peralatan',
    'Kamera',
    'Investasi',
  ];

  static const Map<String, String> _sortOptions = {
    'newest': 'Terbaru ditambahkan',
    'oldest': 'Terlama ditambahkan',
    'az': 'Nama Aâ€“Z',
    'za': 'Nama Zâ€“A',
    'highest': 'Harga termahal',
    'lowest': 'Harga termurah',
    'purchase_newest': 'Tanggal pembelian terbaru',
    'purchase_oldest': 'Tanggal pembelian terlama',
  };

  final TextEditingController _searchController =
  TextEditingController();

  late Future<_AssetListData> _dataFuture;

  String _search = '';
  String _selectedCategory = 'Semua';
  String _selectedSort = 'newest';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _dataFuture = _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_AssetListData> _fetchData() async {
    final assets =
    await SupabaseDatabaseHelper.instance.getAssets(widget.userId);

    final customCategories =
    await SupabaseDatabaseHelper.instance.getCustomCategories(widget.userId);

    return _AssetListData(
      assets: assets,
      customCategories: customCategories,
    );
  }

  Future<void> _refresh() async {
    final future = _fetchData();

    setState(() {
      _dataFuture = future;
    });

    await future;
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

    await _refresh();
  }

  String _rupiah(int value) {
    final formatted = value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => '.',
    );

    return 'Rp $formatted';
  }

  int _assetValue(Map<String, dynamic> asset) {
    final raw = asset['value'];

    if (raw is num) return raw.toInt();

    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  String _assetCategory(Map<String, dynamic> asset) {
    final category = asset['category']?.toString().trim() ?? '';

    return category.isEmpty ? 'Lainnya' : category;
  }

  DateTime _dateValue(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime(1970);
  }

  List<String> _buildCategories(_AssetListData data) {
    final result = <String>['Semua', ..._defaultCategories];

    void add(String value) {
      final category = value.trim();

      if (category.isEmpty) return;

      final exists = result.any(
            (item) => item.toLowerCase() == category.toLowerCase(),
      );

      if (!exists) result.add(category);
    }

    for (final category in data.customCategories) {
      add(category);
    }

    for (final asset in data.assets) {
      add(_assetCategory(asset));
    }

    return result;
  }

  List<Map<String, dynamic>> _filteredAssets(
      List<Map<String, dynamic>> allAssets,
      ) {
    final keyword = _search.trim().toLowerCase();

    final result = allAssets.where((asset) {
      final name =
          asset['name']?.toString().toLowerCase() ?? '';

      final category = _assetCategory(asset).toLowerCase();

      final description =
          asset['description']?.toString().toLowerCase() ?? '';

      final matchesSearch = keyword.isEmpty ||
          name.contains(keyword) ||
          category.contains(keyword) ||
          description.contains(keyword);

      final matchesCategory =
          _selectedCategory == 'Semua' ||
              category == _selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();

    switch (_selectedSort) {
      case 'oldest':
        result.sort((a, b) {
          final compare = _dateValue(a['created_at'])
              .compareTo(_dateValue(b['created_at']));

          if (compare != 0) return compare;

          return _idValue(a).compareTo(_idValue(b));
        });
        break;

      case 'az':
        result.sort(
              (a, b) => (a['name']?.toString() ?? '')
              .toLowerCase()
              .compareTo(
            (b['name']?.toString() ?? '').toLowerCase(),
          ),
        );
        break;

      case 'za':
        result.sort(
              (a, b) => (b['name']?.toString() ?? '')
              .toLowerCase()
              .compareTo(
            (a['name']?.toString() ?? '').toLowerCase(),
          ),
        );
        break;

      case 'highest':
        result.sort(
              (a, b) => _assetValue(b).compareTo(_assetValue(a)),
        );
        break;

      case 'lowest':
        result.sort(
              (a, b) => _assetValue(a).compareTo(_assetValue(b)),
        );
        break;

      case 'purchase_newest':
        result.sort(
              (a, b) => _dateValue(b['purchase_date'])
              .compareTo(_dateValue(a['purchase_date'])),
        );
        break;

      case 'purchase_oldest':
        result.sort(
              (a, b) => _dateValue(a['purchase_date'])
              .compareTo(_dateValue(b['purchase_date'])),
        );
        break;

      case 'newest':
      default:
        result.sort((a, b) {
          final compare = _dateValue(b['created_at'])
              .compareTo(_dateValue(a['created_at']));

          if (compare != 0) return compare;

          return _idValue(b).compareTo(_idValue(a));
        });
    }

    return result;
  }

  int _idValue(Map<String, dynamic> asset) {
    final raw = asset['id'];

    if (raw is num) return raw.toInt();

    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  IconData _categoryIcon(String category) {
    final name = category.toLowerCase();

    if (name.contains('elektronik') ||
        name.contains('laptop') ||
        name.contains('komputer')) {
      return Icons.laptop_mac_outlined;
    }

    if (name.contains('kendaraan') ||
        name.contains('mobil') ||
        name.contains('motor')) {
      return Icons.directions_car_outlined;
    }

    if (name.contains('perhiasan') || name.contains('emas')) {
      return Icons.diamond_outlined;
    }

    if (name.contains('rumah')) {
      return Icons.home_outlined;
    }

    if (name.contains('properti') ||
        name.contains('apartemen')) {
      return Icons.apartment_outlined;
    }

    if (name.contains('tanah')) {
      return Icons.landscape_outlined;
    }

    if (name.contains('furnitur')) {
      return Icons.chair_outlined;
    }

    if (name.contains('pakaian')) {
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

    if (name.contains('buku')) {
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

  Widget _assetImage(Map<String, dynamic> asset) {
    final path = asset['image_path']?.toString() ?? '';

    final placeholder = Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(
        _categoryIcon(_assetCategory(asset)),
        color: AppColors.primaryGreen,
        size: 28,
      ),
    );

    if (path.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.file(
        File(path),
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }

  Widget _assetCard(Map<String, dynamic> asset) {
    final name = asset['name']?.toString() ?? 'Aset';
    final category = _assetCategory(asset);
    final value = _assetValue(asset);

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openAsset(asset),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: _softDecoration(),
            child: Row(
              children: [
                _assetImage(asset),
                const SizedBox(width: 13),
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
                      const SizedBox(height: 6),
                      Text(
                        _rupiah(value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                const SizedBox(width: 6),
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

  Widget _categoryChips(List<String> categories) {
    return SizedBox(
      height: 43,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];

          final selected = _selectedCategory.toLowerCase() ==
              category.toLowerCase();

          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedCategory = category;
              });
            },
            showCheckmark: false,
            backgroundColor: const Color(0xFFF8FAF6),
            selectedColor: AppColors.primaryGreen,
            side: BorderSide(
              color: selected
                  ? AppColors.primaryGreen
                  : const Color(0xFFE1E9DF),
            ),
            labelStyle: TextStyle(
              fontFamily: 'Iris',
              fontSize: 12,
              fontWeight:
              selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.white : Colors.black87,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showSortSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFFF8FAF6),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Urutkan Aset',
                  style: TextStyle(
                    fontFamily: 'Iris',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pilih urutan daftar aset yang kamu inginkan.',
                  style: TextStyle(
                    fontFamily: 'Iris',
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: _sortOptions.entries.map((entry) {
                      final active = _selectedSort == entry.key;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          entry.value,
                          style: const TextStyle(
                            fontFamily: 'Iris',
                            fontSize: 14,
                          ),
                        ),
                        trailing: active
                            ? const Icon(
                          Icons.check_circle,
                          color: AppColors.primaryGreen,
                        )
                            : const Icon(
                          Icons.circle_outlined,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          Navigator.pop(sheetContext, entry.key);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;

    setState(() {
      _selectedSort = selected;
    });
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: _softDecoration(radius: 18),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _search = value;
                  });
                },
                style: const TextStyle(
                  fontFamily: 'Iris',
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari aset...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Iris',
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primaryGreen,
                  ),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _search = '';
                      });
                    },
                    icon: const Icon(Icons.close, size: 18),
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showSortSheet,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 52,
                height: 52,
                decoration: _softDecoration(radius: 18),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(bool hasAssets) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 42,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              hasAssets
                  ? Icons.search_off_rounded
                  : Icons.inventory_2_outlined,
              color: AppColors.primaryGreen,
              size: 54,
            ),
            const SizedBox(height: 14),
            Text(
              hasAssets
                  ? 'Aset tidak ditemukan'
                  : 'Belum ada aset',
              style: const TextStyle(
                fontFamily: 'Iris',
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              hasAssets
                  ? 'Coba ubah pencarian atau kategori.'
                  : 'Tekan tombol (+) untuk menambahkan aset.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Iris',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: FutureBuilder<_AssetListData>(
          future: _dataFuture,
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
                    'Gagal memuat aset.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Iris'),
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            final categories = _buildCategories(data);
            final assets = _filteredAssets(data.assets);

            return RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.primaryGreen,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20, 18, 20, 18,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Image.asset(
                              'assets/logo_myasset.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'MyAsset',
                              style: TextStyle(
                                fontFamily: 'CustomMono',
                                fontSize: 29,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                      child: Text(
                        'Daftar Aset',
                        style: TextStyle(
                          fontFamily: 'Iris',
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20, 0, 20, 22,
                      ),
                      child: Text(
                        '${assets.length} dari ${data.assets.length} aset ditampilkan',
                        style: const TextStyle(
                          fontFamily: 'Iris',
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(child: _searchBar()),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),

                  SliverToBoxAdapter(
                    child: _categoryChips(categories),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20, 20, 20, 14,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Semua Aset',
                              style: TextStyle(
                                fontFamily: 'Iris',
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              _sortOptions[_selectedSort] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Iris',
                                fontSize: 10,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (assets.isEmpty)
                    SliverToBoxAdapter(
                      child: _emptyState(data.assets.isNotEmpty),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        20, 0, 20, 35,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) {
                            return _assetCard(assets[index]);
                          },
                          childCount: assets.length,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AssetListData {
  final List<Map<String, dynamic>> assets;
  final List<String> customCategories;

  const _AssetListData({
    required this.assets,
    required this.customCategories,
  });
}



