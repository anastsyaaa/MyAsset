import '../supabase_database_helper.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../widgets/dashboard_gradient_background.dart';

class AssetDetailScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> asset;

  const AssetDetailScreen({
    super.key,
    required this.userId,
    required this.asset,
  });

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  late Map<String, dynamic> _asset;
  bool _busy = false;

  static const _green = Color(0xFF174F34);
  static const _surface = Color(0xFFF8FAF6);
  static const _shadow = Color(0xFFD6DED4);

  @override
  void initState() {
    super.initState();
    _asset = Map<String, dynamic>.from(widget.asset);
  }

  int get _assetId => (_asset['id'] as num).toInt();

  String _rupiah(int value) {
    final formatted = value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => '.',
    );
    return 'Rp $formatted';
  }

  BoxDecoration _decoration() {
    return BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Colors.white,
          offset: Offset(-4, -4),
          blurRadius: 11,
        ),
        BoxShadow(
          color: _shadow,
          offset: Offset(4, 4),
          blurRadius: 11,
        ),
      ],
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Iris',
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontFamily: 'Iris',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editAsset() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditAssetScreen(
          userId: widget.userId,
          asset: _asset,
        ),
      ),
    );

    if (!mounted || changed != true) return;

    final assets = await SupabaseDatabaseHelper.instance.getAssets(
      widget.userId,
    );

    if (!mounted) return;

    final updated = assets.where(
          (item) => item['id'] == _asset['id'],
    );

    if (updated.isNotEmpty) {
      setState(() {
        _asset = Map<String, dynamic>.from(updated.first);
      });
    }
  }

  Future<void> _deleteAsset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface,
        title: const Text(
          'Hapus Aset?',
          style: TextStyle(
            fontFamily: 'Iris',
            color: _green,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Yakin ingin menghapus "${_asset['name']}"? '
              'Data aset yang dihapus tidak dapat dikembalikan.',
          style: const TextStyle(fontFamily: 'Iris'),
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
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);

    try {
      final deleted = await SupabaseDatabaseHelper.instance.deleteAsset(
        _assetId,
        widget.userId,
      );

      if (!mounted) return;

      if (deleted > 0) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aset tidak ditemukan.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus aset: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _asset['name']?.toString() ?? 'Aset';
    final category =
        _asset['category']?.toString() ?? 'Lainnya';
    final value = (_asset['value'] as num?)?.toInt() ?? 0;
    final date = _asset['purchase_date']?.toString() ?? '-';
    final description =
        _asset['description']?.toString() ?? '';
    final imagePath = _asset['image_path']?.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF8),
      appBar: AppBar(
        title: const Text(
          'Detail Aset',
          style: TextStyle(
            fontFamily: 'Iris',
            fontWeight: FontWeight.bold,
            color: _green,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: _green,
        elevation: 0,
      ),
      body: DashboardGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 210,
                  width: double.infinity,
                  decoration: _decoration(),
                  clipBehavior: Clip.antiAlias,
                  child: imagePath != null &&
                      imagePath.isNotEmpty &&
                      File(imagePath).existsSync()
                      ? Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                  )
                      : const Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 62,
                        color: _green,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Belum ada foto aset',
                        style: TextStyle(
                          fontFamily: 'Iris',
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Iris',
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: _green,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _rupiah(value),
                  style: const TextStyle(
                    fontFamily: 'Iris',
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: _green,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _decoration(),
                  child: Column(
                    children: [
                      _info('Kategori', category),
                      const Divider(),
                      _info('Tanggal Pembelian', date),
                      const Divider(),
                      _info('Catatan', description),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _busy ? null : _editAsset,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text(
                        'Edit Aset',
                        style: TextStyle(
                          fontFamily: 'Iris',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _deleteAsset,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text(
                      'Hapus Aset',
                      style: TextStyle(
                        fontFamily: 'Iris',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(
                        color: Colors.red.shade300,
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
  }
}

class EditAssetScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> asset;

  const EditAssetScreen({
    super.key,
    required this.userId,
    required this.asset,
  });

  @override
  State<EditAssetScreen> createState() => _EditAssetScreenState();
}

class _EditAssetScreenState extends State<EditAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _value = TextEditingController();
  final _description = TextEditingController();

  static const _gallery = MethodChannel('myasset/gallery');
  static const _green = Color(0xFF174F34);
  static const _surface = Color(0xFFF8FAF6);
  static const _shadow = Color(0xFFD6DED4);

  final List<String> _defaults = [
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

  List<String> _categories = [];
  late String _category;
  late DateTime _date;
  String? _imagePath;
  bool _saving = false;
  bool _loading = true;
  bool _picking = false;

  @override
  void initState() {
    super.initState();

    _name.text = widget.asset['name']?.toString() ?? '';
    _value.text = widget.asset['value']?.toString() ?? '';
    _description.text =
        widget.asset['description']?.toString() ?? '';

    _category =
        widget.asset['category']?.toString() ?? 'Lainnya';

    _imagePath = widget.asset['image_path']?.toString();

    _date = DateTime.tryParse(
      widget.asset['purchase_date']?.toString() ?? '',
    ) ??
        DateTime.now();

    _loadCategories();
  }

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final custom = await SupabaseDatabaseHelper.instance.getCustomCategories(widget.userId);

      final combined = [..._defaults];

      for (final item in [...custom, _category]) {
        if (!combined.any(
              (name) =>
          name.toLowerCase() == item.toLowerCase(),
        )) {
          combined.add(item);
        }
      }

      if (!mounted) return;

      // Pastikan kategori lama tetap valid di dropdown.
      _category = combined.firstWhere(
            (item) =>
        item.toLowerCase() == _category.toLowerCase(),
      );

      setState(() {
        _categories = combined;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _categories = [..._defaults, _category].toSet().toList();
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat kategori: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    if (_picking) return;

    setState(() => _picking = true);

    try {
      final path =
      await _gallery.invokeMethod<String>('pickImage');

      if (!mounted || path == null) return;

      setState(() => _imagePath = path);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih foto: $e')),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(DateTime.now())
          ? DateTime.now()
          : _date,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selected != null && mounted) {
      setState(() => _date = selected);
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final id = (widget.asset['id'] as num).toInt();

      final updated = await SupabaseDatabaseHelper.instance.updateAsset(
        id,
        widget.userId,
        {
          'name': _name.text.trim(),
          'category': _category,
          'value': int.parse(_value.text),
          'purchase_date':
          '${_date.year}-'
              '${_date.month.toString().padLeft(2, '0')}-'
              '${_date.day.toString().padLeft(2, '0')}',
          'description': _description.text.trim(),
          'image_path': _imagePath,
        },
      );

      if (!mounted) return;

      if (updated > 0) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aset tidak ditemukan.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui aset: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  BoxDecoration _decoration() {
    return BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Colors.white,
          offset: Offset(-4, -4),
          blurRadius: 11,
        ),
        BoxShadow(
          color: _shadow,
          offset: Offset(4, 4),
          blurRadius: 11,
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Iris',
          fontWeight: FontWeight.w600,
          color: _green,
        ),
      ),
    );
  }

  InputDecoration _input(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Iris',
        fontSize: 13,
      ),
      prefixIcon: Icon(icon, color: _green),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
    );
  }

  Widget _box(Widget child) {
    return Container(
      decoration: _decoration(),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF8),
      appBar: AppBar(
        title: const Text(
          'Edit Aset',
          style: TextStyle(
            fontFamily: 'Iris',
            fontWeight: FontWeight.bold,
            color: _green,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: _green,
        elevation: 0,
      ),
      body: DashboardGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _picking ? null : _pickImage,
                    child: Container(
                      height: 164,
                      width: double.infinity,
                      decoration: _decoration(),
                      clipBehavior: Clip.antiAlias,
                      child: _imagePath != null &&
                          _imagePath!.isNotEmpty &&
                          File(_imagePath!).existsSync()
                          ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(_imagePath!),
                            fit: BoxFit.cover,
                          ),
                          const Positioned(
                            bottom: 12,
                            right: 12,
                            child: Chip(
                              label: Text(
                                'Ganti Foto',
                                style: TextStyle(
                                  fontFamily: 'Iris',
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                          : Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          if (_picking)
                            const CircularProgressIndicator()
                          else
                            const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 40,
                              color: _green,
                            ),
                          const SizedBox(height: 10),
                          const Text(
                            'Pilih Foto dari Galeri',
                            style: TextStyle(
                              fontFamily: 'Iris',
                              color: _green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _fieldLabel('Nama Barang'),
                  _box(
                    TextFormField(
                      controller: _name,
                      style: const TextStyle(
                        fontFamily: 'Iris',
                      ),
                      decoration: _input(
                        'Nama barang',
                        Icons.inventory_2_outlined,
                      ),
                      validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Nama barang wajib diisi'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _fieldLabel('Kategori'),
                  _box(
                    _loading
                        ? const Padding(
                      padding: EdgeInsets.all(18),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                        : DropdownButtonFormField<String>(
                      value: _category,
                      isExpanded: true,
                      decoration: _input(
                        'Kategori',
                        Icons.category_outlined,
                      ),
                      style: const TextStyle(
                        fontFamily: 'Iris',
                        color: _green,
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontFamily: 'Iris',
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _category = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                  _fieldLabel('Tanggal Pembelian'),
                  _box(
                    ListTile(
                      leading: const Icon(
                        Icons.calendar_month_outlined,
                        color: _green,
                      ),
                      title: Text(
                        '${_date.day}/${_date.month}/${_date.year}',
                        style: const TextStyle(
                          fontFamily: 'Iris',
                          color: _green,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.keyboard_arrow_down,
                        color: _green,
                      ),
                      onTap: _chooseDate,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _fieldLabel('Harga Beli'),
                  _box(
                    TextFormField(
                      controller: _value,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: const TextStyle(
                        fontFamily: 'Iris',
                      ),
                      decoration: _input(
                        'Harga beli',
                        Icons.payments_outlined,
                      ).copyWith(prefixText: 'Rp  '),
                      validator: (value) {
                        final number = int.tryParse(value ?? '');
                        if (number == null || number <= 0) {
                          return 'Masukkan harga yang valid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                  _fieldLabel('Catatan'),
                  _box(
                    TextFormField(
                      controller: _description,
                      maxLines: 3,
                      style: const TextStyle(
                        fontFamily: 'Iris',
                      ),
                      decoration: _input(
                        'Tambah keterangan...',
                        Icons.description_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: ElevatedButton(
                        onPressed:
                        _saving || _loading || _picking
                            ? null
                            : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                        ),
                        child: _saving
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontFamily: 'Iris',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



