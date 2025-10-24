import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/product_repository.dart';
import 'data/product.dart';
import 'constants/app_constants.dart';
import 'screens/category_manage_page.dart';

class AddProductPage extends StatefulWidget {
  final String market;
  const AddProductPage({super.key, required this.market});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> with SingleTickerProviderStateMixin {
  late final ProductRepository _repo;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  String _category = 'Meyve';
  String _unit = 'kg';
  List<Map<String, String>> _allCategories = [];

  @override
  void initState() {
    super.initState();
    _repo = ProductRepository(widget.market);
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
      
      if (_allCategories.isNotEmpty) {
        if (!_allCategories.any((c) => c['name'] == _category)) {
          _category = _allCategories[0]['name']!;
        }
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

    final existing = await _repo.findByBarcode(_barcodeController.text.trim());
    if (existing != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Bu barkod zaten kayıtlı: ${existing.name}'),
                ),
              ],
            ),
          ),
        );
      }
      return;
    }

    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch,
      name: _nameController.text.trim(),
      barcode: _barcodeController.text.trim(),
      category: _category,
      unit: _unit,
    );

    await _repo.insert(product);
    if (!mounted) return;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('✅ Ürün başarıyla eklendi!'),
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
        title: const Text('Yeni Ürün Ekle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Kategori Yönetimi',
            onPressed: () async {
              final hasChanges = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => CategoryManagePage(market: widget.market)),
              );
              if (hasChanges == true && mounted) {
                await _loadCategories();
                setState(() {});
              }
            },
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
                hintText: 'Örn: Domates',
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
                hintText: 'Örn: 8690504012345',
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
              label: const Text('Kaydet'),
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
