
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/dashboard_gradient_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard_screen.dart';
import 'asset_list_screen.dart';
import 'add_asset_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class MainNavigation extends StatefulWidget {
  final String userName;
  final String userId;

  const MainNavigation({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  String _selectedAssetCategory = 'Semua';
  int _dashboardVersion = 0;
  int _assetListVersion = 0;
  int _historyVersion = 0;
  int _profileVersion = 0;

  void _refreshPages() {
    setState(() {
      _dashboardVersion++;
      _assetListVersion++;
    });
  }

  void _openProfileTab() {
    setState(() {
      _selectedIndex = 3;
      _profileVersion++;
    });
  }

  void _openAssetCategory(String category) {
    setState(() {
      _selectedAssetCategory = category;
      _selectedIndex = 1;
      _assetListVersion++;
    });
  }

  void _onProfileUpdated() {
    setState(() {
      _dashboardVersion++;
    });
  }

  Future<void> _openAddAsset() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddAssetScreen(
          userId: widget.userId,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      setState(() {
        _dashboardVersion++;
        _assetListVersion++;
        _profileVersion++;
        _selectedIndex = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aset berhasil ditambahkan!',
            style: TextStyle(fontFamily: 'Iris'),
          ),
        ),
      );
    }
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final selected = _selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;

            if (index == 1) {
              _selectedAssetCategory = 'Semua';
              _assetListVersion++;
            }

            if (index == 2) {
              _historyVersion++;
            }

            if (index == 3) {
              _profileVersion++;
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected
                    ? AppColors.primaryGreen
                    : Colors.grey,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Iris',
                  fontSize: 10,
                  color: selected
                      ? AppColors.primaryGreen
                      : Colors.grey,
                  fontWeight: selected
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardScreen(
        key: ValueKey(_dashboardVersion),
        userName: widget.userName,
        userId: widget.userId,
        onProfileTap: _openProfileTab,
        onCategoryTap: _openAssetCategory,
      ),

      AssetListScreen(
        key: ValueKey(_assetListVersion),
        userId: widget.userId,
        initialCategory: _selectedAssetCategory,
      ),

      HistoryScreen(
        key: ValueKey(_historyVersion),
        userId: widget.userId,
      ),

      ProfileScreen(
        key: ValueKey(_profileVersion),
        userId: widget.userId,
        userName: widget.userName,
        onProfileUpdated: _onProfileUpdated,
        onLogout: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => LoginScreen(),
            ),
                (route) => false,
          );
        },
      ),
    ];

    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: false,
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            14,
          ),
          child: SizedBox(
            height: 78,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FFF8),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen
                            .withValues(alpha: 0.12),
                        blurRadius: 22,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Row(
                      children: [
                        _navItem(
                          icon: Icons.home_outlined,
                          label: 'Beranda',
                          index: 0,
                        ),
                        _navItem(
                          icon: Icons.inventory_2_outlined,
                          label: 'Aset',
                          index: 1,
                        ),
                        const Expanded(
                          child: SizedBox(),
                        ),
                        _navItem(
                          icon: Icons.history,
                          label: 'Riwayat',
                          index: 2,
                        ),
                        _navItem(
                          icon: Icons.person_outline,
                          label: 'Profil',
                          index: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: FloatingActionButton(
                      heroTag: 'main_add_asset',
                      onPressed: _openAddAsset,
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 5,
                      tooltip: 'Tambah Aset',
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return DashboardGradientBackground(
      child: scaffold,
    );
  }
}

