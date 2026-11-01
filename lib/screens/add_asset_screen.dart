import '../supabase_database_helper.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../widgets/dashboard_gradient_background.dart';

class AddAssetScreen extends StatefulWidget {
  final String userId;

  const AddAssetScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _descriptionController = TextEditingController();

  static const _galleryChannel = MethodChannel('myasset/gallery');

  static const Color darkGreen = Color(0xFF174F34);
  static const Color surface = Color(0xFFF8FAF6);
  static const Color shadow = Color(0xFFD6DED4);
  static const Color muted = Color(0xFF82968B);

  final List<String> _defaultCategories = [
    'Elektronik',
    'Kendaraan',
    'Perhiasan',
    'Lainnya',
  ];

  List<String> _categories = [];

  String _category = 'Elektronik';
  String? _imagePath;

  DateTime _purchaseDate = DateTime.now();

  bool _isSaving = false;
  bool _isLoadingCategories = true;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final custom = await SupabaseDatabaseHelper.instance.getCustomCategories(widget.userId);

      if (!mounted) return;

      final combined = [..._defaultCategories];

      for (final name in custom) {
        if (!combined.any(
              (item) => item.toLowerCase() == name.toLowerCase(),
        )) {
          combined.add(name);
        }
      }

      setState(() {
        _categories = combined;
        _isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _categories = [..._defaultCategories];
        _isLoadingCategories = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat kategori tambahan: $e'),
        ),
      );
    }
  }

  Future<void> _addCategory() async {
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String categoryInput = '';

        return AlertDialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Kategori Baru',
            style: TextStyle(
              fontFamily: 'Iris',
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),
          content: TextField(
            autofocus: true,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              fontFamily: 'Iris',
              color: darkGreen,
            ),
            decoration: InputDecoration(
              hintText: 'Contoh: Properti',
              hintStyle: const TextStyle(
                fontFamily: 'Iris',
                color: muted,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              categoryInput = value;
            },
            onSubmitted: (value) {
              Navigator.pop(dialogContext, value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Batal',
                style: TextStyle(fontFamily: 'Iris'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  categoryInput.trim(),
                );
              },
              child: const Text(
                'Tambahkan',
                style: TextStyle(
                  fontFamily: 'Iris',
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || name == null || name.trim().isEmpty) {
      return;
    }

    final cleanName = name.trim();

    for (final existing in _categories) {
      if (existing.toLowerCase() == cleanName.toLowerCase()) {
        setState(() {
          _category = existing;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori tersebut sudah tersedia.'),
          ),
        );
        return;
      }
    }

    try {
      await SupabaseDatabaseHelper.instance.addCustomCategory(
        widget.userId,
        cleanName,
      );

      if (!mounted) return;

      setState(() {
        _categories.add(cleanName);
        _category = cleanName;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kategori "$cleanName" berhasil ditambahkan.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan kategori: $e'),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;

    setState(() {
      _isPickingImage = true;
    });

    try {
      final path = await _galleryChannel.invokeMethod<String>(
        'pickImage',
      );

      if (!mounted || path == null) return;

      setState(() {
        _imagePath = path;
      });
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
          _isPickingImage = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: darkGreen,
              onPrimary: Colors.white,
              surface: surface,
              onSurface: darkGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _purchaseDate = selected;
      });
    }
  }

  Future<void> _saveAsset() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) return;

    if (_isLoadingCategories) return;

    setState(() {
      _isSaving = true;
    });

    try {

      final value = int.parse(_valueController.text);

      await SupabaseDatabaseHelper.instance.addAsset({
        'user_id': widget.userId,
        'name': _nameController.text.trim(),
        'category': _category,
        'value': value,
        'purchase_date':
        '${_purchaseDate.year}-'
            '${_purchaseDate.month.toString().padLeft(2, '0')}-'
            '${_purchaseDate.day.toString().padLeft(2, '0')}',
        'description': _descriptionController.text.trim(),
        'image_path': _imagePath,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan aset: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  BoxDecoration _softDecoration({
    double radius = 18,
  }) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [
        BoxShadow(
          color: Colors.white,
          offset: Offset(-4, -4),
          blurRadius: 11,
        ),
        BoxShadow(
          color: shadow,
          offset: Offset(4, 4),
          blurRadius: 11,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
      String hint,
      IconData icon,
      ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Iris',
        fontSize: 13,
        color: muted,
      ),
      prefixIcon: Icon(
        icon,
        color: darkGreen,
        size: 21,
      ),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFF81AE89),
          width: 1.2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Iris',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: darkGreen,
        ),
      ),
    );
  }

  Widget _softField(Widget child) {
    return Container(
      decoration: _softDecoration(),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF8),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 76,
        leadingWidth: 66,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: _softDecoration(radius: 15),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: darkGreen,
                  size: 19,
                ),
                onPressed: _isSaving
                    ? null
                    : () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        titleSpacing: 12,
        title: const Text(
          'Tambah Aset',
          style: TextStyle(
            fontFamily: 'Iris',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: darkGreen,
          ),
        ),
      ),
      body: DashboardGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FOTO DARI GALERI

                  GestureDetector(
                    onTap: _isPickingImage ? null : _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 164,
                      decoration: BoxDecoration(
                        color: surface.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFFA9CDB3),
                          width: 1.1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.white,
                            offset: Offset(-4, -4),
                            blurRadius: 11,
                          ),
                          BoxShadow(
                            color: shadow,
                            offset: Offset(4, 4),
                            blurRadius: 11,
                          ),
                        ],
                      ),
                      child: _imagePath != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(21),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(_imagePath!),
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.92),
                                  borderRadius:
                                  BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Ganti Foto',
                                  style: TextStyle(
                                    fontFamily: 'Iris',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: darkGreen,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isPickingImage)
                            const CircularProgressIndicator(
                              color: darkGreen,
                            )
                          else
                            const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 38,
                              color: darkGreen,
                            ),
                          const SizedBox(height: 10),
                          const Text(
                            'Tambah Foto',
                            style: TextStyle(
                              fontFamily: 'Iris',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: darkGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Pilih dari Galeri (Opsional)',
                            style: TextStyle(
                              fontFamily: 'Iris',
                              fontSize: 12,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // NAMA BARANG

                  _label('Nama Barang'),

                  _softField(
                    TextFormField(
                      controller: _nameController,
                      textCapitalization:
                      TextCapitalization.sentences,
                      style: const TextStyle(
                        fontFamily: 'Iris',
                        color: darkGreen,
                      ),
                      decoration: _inputDecoration(
                        'Contoh: iPhone 13',
                        Icons.inventory_2_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama barang wajib diisi';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 22),

                  // KATEGORI

                  _label('Kategori'),

                  _softField(
                    _isLoadingCategories
                        ? const Padding(
                      padding: EdgeInsets.all(18),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: darkGreen,
                        ),
                      ),
                    )
                        : DropdownButtonFormField<String>(
                      value: _category,
                      isExpanded: true,
                      dropdownColor: surface,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: darkGreen,
                      ),
                      style: const TextStyle(
                        fontFamily: 'Iris',
                        fontSize: 14,
                        color: darkGreen,
                      ),
                      decoration: _inputDecoration(
                        'Pilih kategori',
                        Icons.category_outlined,
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontFamily: 'Iris',
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _category = value;
                          });
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 9),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _isLoadingCategories
                          ? null
                          : _addCategory,
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Tambah kategori baru',
                        style: TextStyle(
                          fontFamily: 'Iris',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: darkGreen,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // TANGGAL PEMBELIAN

                  _label('Tanggal Pembelian'),

                  _softField(
                    InkWell(
                      onTap: _chooseDate,
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 18,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: darkGreen,
                              size: 21,
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Text(
                                _formatDate(_purchaseDate),
                                style: const TextStyle(
                                  fontFamily: 'Iris',
                                  fontSize: 14,
                                  color: darkGreen,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: darkGreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // HARGA BELI

                  _label('Harga Beli'),

                  _softField(
                    TextFormField(
                      controller: _valueController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: const TextStyle(
                        fontFamily: 'Iris',
                        color: darkGreen,
                      ),
                      decoration: _inputDecoration(
                        'Contoh: 8000000',
                        Icons.payments_outlined,
                      ).copyWith(
                        prefixText: 'Rp  ',
                        prefixStyle: const TextStyle(
                          fontFamily: 'Iris',
                          fontWeight: FontWeight.w600,
                          color: darkGreen,
                        ),
                      ),
                      validator: (value) {
                        final number = int.tryParse(value ?? '');

                        if (number == null || number <= 0) {
                          return 'Masukkan harga beli yang valid';
                        }

                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 22),

                  // CATATAN

                  _label('Catatan'),

                  _softField(
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      textCapitalization:
                      TextCapitalization.sentences,
                      style: const TextStyle(
                        fontFamily: 'Iris',
                        color: darkGreen,
                      ),
                      decoration: _inputDecoration(
                        'Tambah keterangan...',
                        Icons.description_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(height: 34),

                  // TOMBOL SIMPAN

                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.white,
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
                      onPressed: _isSaving ||
                          _isLoadingCategories ||
                          _isPickingImage
                          ? null
                          : _saveAsset,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                          : const Text(
                        'Simpan',
                        style: TextStyle(
                          fontFamily: 'Iris',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}




