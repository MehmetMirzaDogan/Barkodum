import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'screens/search_page.dart';
import 'screens/market_manage_page.dart';
import 'controllers/theme_controller.dart';
import 'constants/app_constants.dart';
import 'data/seed.dart';
import 'data/database.dart';
import 'main.dart' as main_app;

class MarketSelectPage extends StatefulWidget {
  const MarketSelectPage({super.key});

  @override
  State<MarketSelectPage> createState() => _MarketSelectPageState();
}

class _MarketSelectPageState extends State<MarketSelectPage> {
  List<Map<String, dynamic>> _allMarkets = [];

  @override
  void initState() {
    super.initState();
    _loadMarkets();
  }

  Future<void> _loadMarkets() async {
    final prefs = await SharedPreferences.getInstance();
    
    final customMarketsJson = prefs.getString('custom_markets');
    List<Map<String, dynamic>> customMarkets = [];
    if (customMarketsJson != null) {
      final List<dynamic> decoded = jsonDecode(customMarketsJson);
      customMarkets = decoded.map((e) {
        final map = Map<String, dynamic>.from(e);
        return {
          'name': map['name'],
          'color': _getColor(map['color'] ?? 'grey'),
          'logo': '',
        };
      }).toList();
    }

    final hiddenMarketsJson = prefs.getString('hidden_default_markets');
    List<String> hiddenDefaultMarkets = [];
    if (hiddenMarketsJson != null) {
      final List<dynamic> decoded = jsonDecode(hiddenMarketsJson);
      hiddenDefaultMarkets = decoded.map((e) => e.toString()).toList();
    }

    final visibleDefaultMarkets = AppConstants.markets
        .where((market) => !hiddenDefaultMarkets.contains(market['name']))
        .toList();

    List<Map<String, dynamic>> allMarkets = [...visibleDefaultMarkets, ...customMarkets];
    
    final marketOrderJson = prefs.getString('market_order');
    if (marketOrderJson != null) {
      final List<dynamic> orderList = jsonDecode(marketOrderJson);
      final orderedMarkets = <Map<String, dynamic>>[];
      for (var name in orderList) {
        final market = allMarkets.firstWhere(
          (m) => m['name'] == name,
          orElse: () => <String, dynamic>{},
        );
        if (market.isNotEmpty) orderedMarkets.add(market);
      }
      for (var market in allMarkets) {
        if (!orderedMarkets.contains(market)) {
          orderedMarkets.add(market);
        }
      }
      allMarkets = orderedMarkets;
    }

    setState(() {
      _allMarkets = allMarkets;
    });
  }
  
  Future<void> _saveMarketOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final orderList = _allMarkets.map((m) => m['name'] as String).toList();
    await prefs.setString('market_order', jsonEncode(orderList));
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
      case 'amber': return Colors.amber;
      case 'cyan': return Colors.cyan;
      case 'indigo': return Colors.indigo;
      case 'lime': return Colors.lime;
      case 'yellow': return Colors.yellow;
      case 'grey': return Colors.grey;
      case 'deepOrange': return Colors.deepOrange;
      case 'deepPurple': return Colors.deepPurple;
      case 'lightBlue': return Colors.lightBlue;
      case 'lightGreen': return Colors.lightGreen;
      case 'lightPink': return const Color(0xFFFFB6C1);
      case 'darkBlue': return const Color(0xFF00008B);
      case 'darkGreen': return const Color(0xFF006400);
      case 'darkRed': return const Color(0xFF8B0000);
      case 'darkOrange': return const Color(0xFFFF8C00);
      case 'darkPurple': return const Color(0xFF9400D3);
      case 'blueGrey': return Colors.blueGrey;
      case 'tealAccent': return Colors.tealAccent;
      case 'purpleAccent': return Colors.purpleAccent;
      case 'pinkAccent': return Colors.pinkAccent;
      default: return Colors.grey;
    }
  }

  Future<void> _factoryReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('Fabrika Ayarları', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'TAMAMEN FABRİKA AYARLARINA DÖNÜLECEK!\n\n'
          '• Tüm veritabanları silinecek\n'
          '• Tüm özel marketler silinecek\n'
          '• Tüm özel kategoriler silinecek\n'
          '• Sadece 4 ana market kalacak (Migros, BİM, ŞOK, A101)\n'
          '• CSV başlangıç verileri otomatik yüklenecek\n\n'
          'Bu işlem geri alınamaz! Emin misiniz?',
          style: TextStyle(fontSize: 15),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: const EdgeInsets.only(bottom: 10, right: 10, left: 10),
        actions: [
          SizedBox(
            width: 110,
            height: 40,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('İptal'),
            ),
          ),
          SizedBox(
            width: 110,
            height: 40,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Sıfırla', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      await AppDatabase.closeAll();
      debugPrint('✓ Tüm veritabanı bağlantıları kapatıldı');
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      final appDir = await getApplicationDocumentsDirectory();
      final dbDir = Directory(appDir.path);
      
      int deletedDbCount = 0;
      if (await dbDir.exists()) {
        await for (var entity in dbDir.list()) {
          if (entity is File && entity.path.endsWith('.db')) {
            try {
              await entity.delete();
              deletedDbCount++;
              debugPrint('Veritabanı silindi: ${entity.path}');
            } catch (e) {
              debugPrint('Veritabanı silinemedi: ${entity.path}, Hata: $e');
            }
          }
        }
      }

      await prefs.remove('custom_markets');
      debugPrint('Özel marketler silindi');

      await prefs.remove('hidden_default_markets');
      debugPrint('Gizli marketler listesi temizlendi');

      final allKeys = prefs.getKeys();
      for (var key in allKeys) {
        if (key.startsWith('custom_categories_')) {
          await prefs.remove(key);
          debugPrint('Kategori silindi: $key');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Fabrika ayarlarına sıfırlandı!\n$deletedDbCount veritabanı silindi.\nUygulama yeniden başlatılıyor...'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(seconds: 1));
        
        main_app.restartApp();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Hoşgeldiniz Market Seçiniz', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(ThemeController.I.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => ThemeController.I.toggleTheme(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'reset') {
                _factoryReset();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore, size: 20, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Fabrika Ayarları', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allMarkets.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = _allMarkets.removeAt(oldIndex);
            _allMarkets.insert(newIndex, item);
          });
          _saveMarketOrder();
        },
        itemBuilder: (context, i) {
          final m = _allMarkets[i];
          final hasLogo = (m['logo'] as String).isNotEmpty;
          
          return Card(
            key: ValueKey(m['name']),
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: (m['color'] as Color).withValues(alpha: hasLogo ? 0.1 : 1.0),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                child: hasLogo
                    ? Image.asset(m['logo'] as String, fit: BoxFit.contain)
                    : Center(
                        child: Text(
                          (m['name'] as String).substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              title: Text(
                m['name'] as String,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.drag_handle, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => SearchPage(market: m['name'] as String)),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MarketManagePage()),
          );
          _loadMarkets(); // Yeniden yükle
        },
        icon: const Icon(Icons.add),
        label: const Text('Yeni Market'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
