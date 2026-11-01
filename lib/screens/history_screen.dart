import '../supabase_database_helper.dart';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HistoryScreen extends StatefulWidget {
  final String userId;

  const HistoryScreen({
    super.key,
    required this.userId,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const Color _surface = Color(0xFFF8FAF6);
  static const Color _shadow = Color(0xFFD6DED4);

  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows =
      await SupabaseDatabaseHelper.instance.getAssetHistory(widget.userId);

      if (!mounted) return;

      setState(() {
        _history = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
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

  String _formatDate(dynamic raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '');

    if (date == null) return '-';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day $month $year â€¢ $hour:$minute';
  }

  String _actionTitle(String action) {
    switch (action) {
      case 'added':
        return 'Aset Ditambahkan';
      case 'updated':
        return 'Aset Diedit';
      case 'deleted':
        return 'Aset Dihapus';
      default:
        return 'Aktivitas Aset';
    }
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'added':
        return Icons.add_circle_outline_rounded;
      case 'updated':
        return Icons.edit_outlined;
      case 'deleted':
        return Icons.delete_outline_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'deleted':
        return const Color(0xFFD67A7A);
      case 'updated':
        return const Color(0xFFB18A45);
      default:
        return AppColors.primaryGreen;
    }
  }

  Widget _historyCard(Map<String, dynamic> item) {
    final action = item['action']?.toString() ?? '';
    final name = item['asset_name']?.toString() ?? '-';
    final category = item['category']?.toString() ?? '-';
    final color = _actionColor(action);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: _softDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              _actionIcon(action),
              color: color,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _actionTitle(action),
                  style: const TextStyle(
                    fontFamily: 'Iris',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263C2D),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Iris',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF405747),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  category,
                  style: const TextStyle(
                    fontFamily: 'Iris',
                    fontSize: 12,
                    color: Color(0xFF7B8C7D),
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Color(0xFF8A998B),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _formatDate(item['created_at']),
                        style: const TextStyle(
                          fontFamily: 'Iris',
                          fontSize: 11,
                          color: Color(0xFF8A998B),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 48,
      ),
      decoration: _softDecoration(),
      child: const Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 58,
            color: AppColors.primaryGreen,
          ),
          SizedBox(height: 16),
          Text(
            'Belum Ada Riwayat',
            style: TextStyle(
              fontFamily: 'Iris',
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263C2D),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Aktivitas tambah, edit, dan hapus aset '
                'akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Iris',
              fontSize: 13,
              color: Color(0xFF7B8C7D),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: _loadHistory,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
          children: [
            const Text(
              'Riwayat Aktivitas',
              style: TextStyle(
                fontFamily: 'Iris',
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263C2D),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pantau perubahan aset kamu di sini',
              style: TextStyle(
                fontFamily: 'Iris',
                fontSize: 13,
                color: Color(0xFF7B8C7D),
              ),
            ),
            const SizedBox(height: 28),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                  ),
                ),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: _softDecoration(),
                child: Column(
                  children: [
                    const Text(
                      'Gagal memuat riwayat.',
                      style: TextStyle(fontFamily: 'Iris'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loadHistory,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              )
            else if (_history.isEmpty)
                _emptyState()
              else
                ..._history.map(_historyCard),
          ],
        ),
      ),
    );
  }
}



