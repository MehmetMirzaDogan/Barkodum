import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/product_repository.dart';
import '../data/product.dart';
import '../data/seed.dart';
import '../add_product_page.dart';
import '../edit_product_page.dart';
import '../market_select_page.dart';
import '../controllers/theme_controller.dart';
import '../constants/app_constants.dart';
import 'category_manage_page.dart';

class SearchPage extends StatefulWidget {
  final String market;
  const SearchPage({super.key, required this.market});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with TickerProviderStateMixin {
  late final ProductRepository _repo;
  final _controller = TextEditingController();
  TabController? _tabController; // nullable yaptık
  Timer? _debounce;

  List<Product> _results = [];
  Map<String, int> _counts = {};
  List<Map<String, dynamic>> _categoryTabs = [];
  List<Map<String, String>> _allCategories = [];

  bool _selectionMode = false;
  final Set<int> _selectedIds = {};
  bool _isLoading = true; // Başlangıçta true
  String? _errorMessage;

  Map<String, dynamic> _marketTheme = {};

  @override
  void initState() {
    super.initState();
    _repo = ProductRepository(widget.market);
    
    _initialize();
  }
  
  Future<void> _initialize() async {
    try {
      await Seeder().runIfNeeded(widget.market);
      await _loadMarketTheme();
      await _initializeTabs();
    } catch (e) {
      if (mounted) {
        _showError('Başlangıç hatası: ${e.toString()}');
      }
    }
  }

  Future<void> _initializeTabs() async {
    final prefs = await SharedPreferences.getInstance();
    
    final marketCategoryKey = 'custom_categories_${widget.market}';
    final categoriesJson = prefs.getString(marketCategoryKey);
    
    final isCustomMarket = !['Migros', 'BİM', 'ŞOK', 'A101'].contains(widget.market);
    
    if (isCustomMarket) {
      if (categoriesJson != null) {
        final List<dynamic> decoded = jsonDecode(categoriesJson);
        _allCategories = decoded.map((e) => Map<String, String>.from(e)).toList();
      } else {
        _allCategories = [];
      }
    } else {
      if (categoriesJson != null) {
        final List<dynamic> decoded = jsonDecode(categoriesJson);
        _allCategories = decoded.map((e) => Map<String, String>.from(e)).toList();
      } else {
        _allCategories = List<Map<String, String>>.from(AppConstants.categories);
      }
    }

    _categoryTabs = [
      {'label': 'Satışta', 'emoji': '🛒', 'key': 'active', 'category': null},
      {'label': 'Favoriler', 'emoji': '⭐', 'key': 'fav', 'category': null},
      {'label': 'Satış Dışı', 'emoji': '🚫', 'key': 'inactive', 'category': null},
    ];

    for (var cat in _allCategories) {
      final key = _turkishToEnglish(cat['name']!.toLowerCase()).replaceAll(' ', '_');
      _categoryTabs.add({
        'label': cat['name']!,
        'emoji': cat['emoji']!,
        'key': key,
        'category': cat['name']!,
      });
    }

    _counts = {};
    for (var tab in _categoryTabs) {
      _counts[tab['key'] as String] = 0;
    }

    _tabController?.dispose();
    
    _tabController = TabController(length: _categoryTabs.length, vsync: this);
    
    final counts = await _repo.getCounts();
    await _loadTabData(0);
    
    if (mounted) {
      setState(() {
        _counts = counts;
        _isLoading = false; // Yükleme tamamlandı
      });
    }
  }

  String _turkishToEnglish(String text) {
    return text
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'I')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'G')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'U')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 'S')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'O')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'C');
  }

  Future<void> _loadMarketTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final customMarketsJson = prefs.getString('custom_markets');
    
    Color? customColor;
    if (customMarketsJson != null) {
      final List<dynamic> decoded = jsonDecode(customMarketsJson);
      final customMarket = decoded.firstWhere(
        (m) => m['name'] == widget.market,
        orElse: () => null,
      );
      
      if (customMarket != null) {
        customColor = _getColor(customMarket['color'] ?? 'grey');
      }
    }
    
    setState(() {
      _marketTheme = AppConstants.getMarketTheme(widget.market, customColor: customColor);
    });
  }

  Color _getColor(String colorName) {
    switch (colorName) {
      case 'red': return Colors.red;
      case 'green': return Colors.green;
      case 'blue': return Colors.blue;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      case 'brown': return Colors.brown;
      case 'teal': return Colors.teal;
      case 'pink': return Colors.pink;
      case 'grey': return Colors.grey;
      case 'amber': return Colors.amber;
      case 'cyan': return Colors.cyan;
      case 'indigo': return Colors.indigo;
      case 'lime': return Colors.lime;
      case 'deepOrange': return Colors.deepOrange;
      case 'deepPurple': return Colors.deepPurple;
      case 'lightBlue': return Colors.lightBlue;
      case 'lightGreen': return Colors.lightGreen;
      case 'yellow': return Colors.yellow;
      case 'redAccent': return Colors.redAccent;
      case 'blueAccent': return Colors.blueAccent;
      case 'greenAccent': return Colors.greenAccent;
      case 'orangeAccent': return Colors.orangeAccent;
      case 'purpleAccent': return Colors.purpleAccent;
      case 'pinkAccent': return Colors.pinkAccent;
      case 'tealAccent': return Colors.tealAccent;
      default: return Colors.grey;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController?.dispose(); // Null kontrolü
    _debounce?.cancel();
    super.dispose();
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    if (_tabController == null) return; // Null kontrolü
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final counts = await _repo.getCounts();
      await _loadTabData(_tabController!.index);
      
      if (mounted) {
        setState(() {
          _counts = counts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Veri yüklenirken hata: ${e.toString()}');
      }
    }
  }
  
  Future<void> _rebuildTabs() async {
    if (_tabController == null) return;
    
    try {
      setState(() => _isLoading = true);
      
      final currentIndex = _tabController!.index;
      await _initializeTabs();
      
      if (currentIndex < _categoryTabs.length && mounted) {
        _tabController!.animateTo(currentIndex);
      }
    } catch (e) {
      if (mounted) {
        _showError('Tab güncelleme hatası: ${e.toString()}');
      }
    }
  }

  Future<void> _loadTabData(int index, {String query = ''}) async {
    if (index >= _categoryTabs.length) return;
    
    try {
      setState(() => _isLoading = true);
      
      final tab = _categoryTabs[index];
      List<Product> res = [];
      
      if (tab['key'] == 'active') {
        res = await _repo.searchByFilter(query, onlyActive: true);
      } else if (tab['key'] == 'fav') {
        res = await _repo.searchByFilter(query, onlyFavorites: true);
      } else if (tab['key'] == 'inactive') {
        res = await _repo.searchByFilter(query, onlyActive: false);
      } else if (tab['category'] != null) {
        res = await _repo.searchByFilter(query, category: tab['category']);
      }
      
      setState(() {
        _results = res;
        _selectedIds.clear();
        _selectionMode = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Arama hatası: ${e.toString()}');
    }
  }

  void _onSearchChanged(String query) {
    if (_tabController == null) return; // Null kontrolü
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceDuration),
      () => _loadTabData(_tabController!.index, query: query),
    );
  }

  Future<void> _showActions(Product p) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Düzenle'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: Text(p.isFavorite ? 'Favoriden Kaldır' : 'Favorilere Ekle'),
              onTap: () async {
                try {
                  await _repo.update(p.copyWith(isFavorite: !p.isFavorite));
                  if (mounted) {
                    Navigator.pop(context);
                    _refreshData();
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    _showError('Güncelleme hatası: ${e.toString()}');
                  }
                }
              },
            ),
            ListTile(
              leading: Icon(p.isActive ? Icons.visibility_off : Icons.visibility,
                  color: Colors.purple),
              title: Text(p.isActive ? 'Satış Dışı Yap' : 'Satışa Al'),
              onTap: () async {
                try {
                  await _repo.update(p.copyWith(isActive: !p.isActive));
                  if (mounted) {
                    Navigator.pop(context);
                    _refreshData();
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    _showError('Güncelleme hatası: ${e.toString()}');
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Sil'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.check_box, color: Colors.teal),
              title: const Text('Seçim Moduna Geç'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectionMode = true);
              },
            ),
          ],
        ),
      ),
    );

    if (action == 'delete') {
      _confirmDelete([p.id]);
    } else if (action == 'edit' && mounted) {
      final updated = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditProductPage(product: p, market: widget.market),
        ),
      );
      if (updated == true) _refreshData();
    }
  }

  void _confirmDelete(List<int> ids) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Silme Onayı", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("${ids.length} ürün silinecek. Emin misiniz?"),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: const EdgeInsets.only(bottom: 10, right: 10, left: 10),
        actions: [
          SizedBox(
            width: 110,
            height: 40,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("İptal"),
            ),
          ),
          SizedBox(
            width: 110,
            height: 40,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await _repo.deleteMultiple(ids);
                  if (mounted) {
                    Navigator.pop(context);
                    _refreshData();
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    _showError('Silme hatası: ${e.toString()}');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Evet, Sil", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkToggleFavorite() async {
    try {
      for (final id in _selectedIds) {
        final product = _results.firstWhere((p) => p.id == id);
        await _repo.update(product.copyWith(isFavorite: !product.isFavorite));
      }
      setState(() {
        _selectionMode = false;
        _selectedIds.clear();
      });
      _refreshData();
    } catch (e) {
      _showError('Toplu işlem hatası: ${e.toString()}');
    }
  }

  Future<void> _bulkToggleActive() async {
    try {
      for (final id in _selectedIds) {
        final product = _results.firstWhere((p) => p.id == id);
        await _repo.update(product.copyWith(isActive: !product.isActive));
      }
      setState(() {
        _selectionMode = false;
        _selectedIds.clear();
      });
      _refreshData();
    } catch (e) {
      _showError('Toplu işlem hatası: ${e.toString()}');
    }
  }

  Future<void> _bulkSetActive(bool active) async {
    try {
      for (final id in _selectedIds) {
        final product = _results.firstWhere((p) => p.id == id);
        await _repo.update(product.copyWith(isActive: active));
      }
      setState(() {
        _selectionMode = false;
        _selectedIds.clear();
      });
      _refreshData();
    } catch (e) {
      _showError('Toplu işlem hatası: ${e.toString()}');
    }
  }

  Color _getCategoryColor(String category) {
    if (_allCategories.isEmpty) {
      return Colors.grey;
    }
    
    final customCat = _allCategories.firstWhere(
      (cat) => cat['name'] == category,
      orElse: () => {'color': 'grey'},
    );
    
    return _getColor(customCat['color'] ?? 'grey');
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color marketColor = _marketTheme.isEmpty 
        ? (isDark ? Colors.grey.shade800 : Colors.grey.shade400)
        : (isDark ? _marketTheme['darkColor'] : _marketTheme['color']);
    final String logoPath = _marketTheme.isEmpty ? '' : (_marketTheme['logo'] ?? '');
    final bool hasLogo = logoPath.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: marketColor,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MarketSelectPage()),
            );
          },
        ),
        centerTitle: true,
        title: hasLogo 
            ? SizedBox(height: 50, child: Image.asset(logoPath, fit: BoxFit.contain))
            : Text(
                widget.market,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: "Seçim modunu kapat",
              onPressed: () => setState(() {
                _selectionMode = false;
                _selectedIds.clear();
              }),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.category, color: Colors.white),
              tooltip: 'Kategori Yönetimi',
              onPressed: () async {
                final hasChanges = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => CategoryManagePage(market: widget.market)),
                );
                if (hasChanges == true && mounted) {
                  await _rebuildTabs();
                }
              },
            ),
            IconButton(
              tooltip: ThemeController.I.isDark ? 'Aydınlık tema' : 'Karanlık tema',
              icon: Icon(
                ThemeController.I.isDark ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white,
              ),
              onPressed: () => ThemeController.I.toggleTheme(),
            ),
          ],
        ],
        bottom: (!_selectionMode && _tabController != null)
            ? PreferredSize(
                preferredSize: const Size.fromHeight(58),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  color: marketColor.withValues(alpha: 0.1),
                  child: TabBar(
                    controller: _tabController!,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    labelPadding: EdgeInsets.zero,
                    indicatorPadding: EdgeInsets.zero,
                    padding: const EdgeInsets.only(left: 8),
                    indicator: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    tabs: List.generate(_categoryTabs.length, (i) {
                      final cat = _categoryTabs[i];
                      Color color;
                      
                      if (i < 3) {
                        color = AppConstants.getCategoryColor(cat['key'], isDark);
                      } else {
                        final customCat = _allCategories.firstWhere(
                          (c) => c['name'] == cat['category'],
                          orElse: () => {'color': 'grey'},
                        );
                        final baseColor = _getColor(customCat['color'] ?? 'grey');
                        color = isDark 
                            ? baseColor.withValues(alpha: 0.3)
                            : baseColor.withValues(alpha: 0.2);
                      }
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        margin: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${cat['emoji']} ${cat['label']} (${_counts[cat['key']] ?? 0})",
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ),
                      );
                    }),
                    onTap: (i) => _loadTabData(i, query: _controller.text),
                  ),
                ),
              )
            : null,
      ),
      body: _tabController == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Ürün adı veya barkod girin...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade900
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: _results.isEmpty && !_isLoading
                  ? const Center(
                      child: Text('Ürün bulunamadı 😕',
                          style: TextStyle(fontSize: 16, color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final p = _results[i];
                        final isFruit = p.category == 'Meyve';
                        final bool isInactive =
                            (p.colorHint == 'grey') || !p.isActive;

                        final categoryColor = _getCategoryColor(p.category);
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isInactive 
                                ? Colors.grey.withValues(alpha: 0.4)
                                : isDark 
                                  ? categoryColor.withValues(alpha: 0.8)
                                  : categoryColor.withValues(alpha: 0.7),
                              width: 3,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            leading: _selectionMode
                                ? Checkbox(
                                    value: _selectedIds.contains(p.id),
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          _selectedIds.add(p.id);
                                        } else {
                                          _selectedIds.remove(p.id);
                                        }
                                      });
                                    },
                                  )
                                : Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isDark 
                                        ? categoryColor.withValues(alpha: 0.3)
                                        : categoryColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      _allCategories.isEmpty
                                          ? '🧺'
                                          : _allCategories
                                              .firstWhere(
                                                (cat) => cat['name'] == p.category,
                                                orElse: () => {'emoji': '🧺'},
                                              )['emoji']!,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark 
                                      ? categoryColor.withValues(alpha: 0.25)
                                      : categoryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isDark 
                                        ? categoryColor.withValues(alpha: 0.6)
                                        : categoryColor.withValues(alpha: 0.5),
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    'Barkod: ${p.barcode}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: categoryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${p.category} • ${p.unit}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (p.isFavorite) const Icon(Icons.star, color: Colors.amber, size: 18),
                                if (p.isFavorite && !p.isActive) const SizedBox(width: 4),
                                if (!p.isActive) const Icon(Icons.visibility_off, color: Colors.red, size: 18),
                              ],
                            ),
                            onTap: _selectionMode
                                ? () {
                                    setState(() {
                                      if (_selectedIds.contains(p.id)) {
                                        _selectedIds.remove(p.id);
                                      } else {
                                        _selectedIds.add(p.id);
                                      }
                                    });
                                  }
                                : null,
                            onLongPress: !_selectionMode ? () => _showActions(p) : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: !_selectionMode
          ? FloatingActionButton(
              backgroundColor: marketColor,
              onPressed: () async {
                final added = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddProductPage(market: widget.market)),
                );
                if (added == true) _refreshData();
              },
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            )
          : null,
      bottomNavigationBar: _selectionMode && _selectedIds.isNotEmpty
          ? BottomAppBar(
              height: 60,
              color: isDark ? Colors.grey.shade900 : Colors.white,
              elevation: 8,
              padding: EdgeInsets.zero,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                    onTap: _bulkToggleFavorite,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          SizedBox(height: 2),
                          Text('Favori', style: TextStyle(fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _bulkSetActive(true),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(height: 2),
                          Text('Satışta', style: TextStyle(fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _bulkSetActive(false),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.remove_circle, color: Colors.orange, size: 20),
                          SizedBox(height: 2),
                          Text('Satış Dışı', style: TextStyle(fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _confirmDelete(_selectedIds.toList()),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.delete, color: Colors.red, size: 20),
                          const SizedBox(height: 2),
                          Text('Sil (${_selectedIds.length})', style: const TextStyle(fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

