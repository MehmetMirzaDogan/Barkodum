import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/product_repository.dart';
import 'data/product.dart';
import 'constants/app_constants.dart';

class EditProductPage extends StatefulWidget {
  final Product product;
  final String market;

  const EditProductPage({
    super.key,
    required this.product,
    required this.market,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> with SingleTickerProviderStateMixin {
  late final ProductRepository _repo;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late String _category;
  late String _unit;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  List<Map<String, String>> _allCategories = [];

  @override
  void initState() {
    super.initState();
    _repo = ProductRepository(widget.market);
    _nameController = TextEditingController(text: widget.product.name);
    _barcodeController = TextEditingController(text: widget.product.barcode);
    _category = widget.product.category;
    _unit = widget.product.unit;
    
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    
    final marketCategoryKey = 'custom_categories_${widget.market}';
    final categoriesJson = prefs.getString(marketCategoryKey);
    
    final isCustomMarket = !['Migros', 'BİM', 'ŞOK', 'A101'].contains(widget.market);
    
    setState(() {
      if (categoriesJson != null) {
        final List<dynamic> decoded = jsonDecode(categoriesJson);
        _allCategories = decoded.map((e) => Map<String, String>.from(e)).toList();
      } else if (isCustomMarket) {
        _allCategories = [
          {'name': 'Genel', 'emoji': '🧺'},
        ];
      } else {
        _allCategories = List<Map<String, String>>.from(AppConstants.categories);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.product.copyWith(
      name: _nameController.text.trim(),
      barcode: _barcodeController.text.trim(),
      category: _category,
      unit: _unit,
    );

    await _repo.update(updated);
    if (!mounted) return;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Row(
            children: [
              Icon(Icons.edit_outlined, color: Colors.white),
              SizedBox(width: 12),
              Text('✏️ Ürün güncellendi!'),
            ],
          ),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürünü Düzenle'),
        actions: [
          if (widget.product.isFavorite)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Chip(label: Text('⭐ Favori', style: TextStyle(fontSize: 11))),
            ),
          if (!widget.product.isActive)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Chip(label: Text('🚫 Satış Dışı', style: TextStyle(fontSize: 11))),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ürün Adı',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_bag),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Bu alan zorunlu' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: 'Barkod Numarası',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Bu alan zorunlu' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _allCategories.any((c) => c['name'] == _category) ? _category : (_allCategories.isNotEmpty ? _allCategories[0]['name'] : 'Meyve'),
              items: _allCategories.map((cat) {
                return DropdownMenuItem(
                  value: cat['name'],
                  child: Row(
                    children: [
                      Text(cat['emoji']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(cat['name']!),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _category = v ?? (_allCategories.isNotEmpty ? _allCategories[0]['name']! : 'Meyve')),
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _unit,
              items: AppConstants.units.map((unit) {
                return DropdownMenuItem(value: unit, child: Text(unit));
              }).toList(),
              onChanged: (v) => setState(() => _unit = v ?? 'kg'),
              decoration: const InputDecoration(
                labelText: 'Birim',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.scale),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Güncelle'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
