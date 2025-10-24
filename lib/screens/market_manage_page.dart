import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/app_constants.dart';

class MarketManagePage extends StatefulWidget {
  const MarketManagePage({super.key});

  @override
  State<MarketManagePage> createState() => _MarketManagePageState();
}

class _MarketManagePageState extends State<MarketManagePage> {
  List<Map<String, dynamic>> _allMarkets = [];
  List<Map<String, String>> _customMarkets = [];
  List<String> _hiddenDefaultMarkets = [];
  
  @override
  void initState() {
    super.initState();
    _loadMarkets();
  }

  Future<void> _loadMarkets() async {
    final prefs = await SharedPreferences.getInstance();
    
    final customMarketsJson = prefs.getString('custom_markets');
    if (customMarketsJson != null) {
      final List<dynamic> decoded = jsonDecode(customMarketsJson);
      _customMarkets = decoded.map((e) => Map<String, String>.from(e)).toList();
    }
    
    final hiddenMarketsJson = prefs.getString('hidden_default_markets');
    if (hiddenMarketsJson != null) {
      final List<dynamic> decoded = jsonDecode(hiddenMarketsJson);
      _hiddenDefaultMarkets = decoded.map((e) => e.toString()).toList();
    }
    
    final visibleDefaultMarkets = AppConstants.markets
        .where((market) => !_hiddenDefaultMarkets.contains(market['name']))
        .toList();
    
    setState(() {
      _allMarkets = [
        ...visibleDefaultMarkets.map((market) => {
          'name': market['name'],
          'color': market['color'],
          'logo': market['logo'],
          'isDefault': true,
        }),
        ..._customMarkets.map((market) => {
          'name': market['name'],
          'color': _getColor(market['color'] ?? 'grey'),
          'logo': '',
          'isDefault': false,
        }),
      ];
    });
  }

  Future<void> _saveCustomMarkets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_markets', jsonEncode(_customMarkets));
  }

  Future<void> _saveHiddenDefaultMarkets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hidden_default_markets', jsonEncode(_hiddenDefaultMarkets));
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    String selectedColor = 'blue';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_business, color: Colors.blue, size: 28),
              ),
              const SizedBox(width: 12),
              const Text('Yeni Market Ekle', style: TextStyle(fontSize: 20)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Market Adı',
                    hintText: 'Örn: Carrefour',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.05),
                    prefixIcon: const Icon(Icons.store),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Renk Seç:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        'red', 'green', 'blue', 'orange', 'purple', 
                        'pink', 'teal', 'cyan', 'brown', 'amber',
                        'indigo', 'lime', 'yellow', 'grey',
                        'deepOrange', 'deepPurple', 
                        'lightBlue', 'lightGreen', 'lightPink',
                        'darkBlue', 'darkGreen', 'darkRed', 'darkOrange', 'darkPurple',
                        'blueGrey', 'tealAccent', 'purpleAccent', 'pinkAccent',
                      ].map((color) => GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = color),
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: _getColor(color),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColor == color ? Colors.white : Colors.grey.shade600,
                              width: selectedColor == color ? 3 : 1,
                            ),
                            boxShadow: selectedColor == color ? [
                              BoxShadow(
                                color: _getColor(color).withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ] : null,
                          ),
                          child: selectedColor == color 
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : null,
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            SizedBox(
              width: 100,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('İptal'),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 100,
              child: ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    setState(() {
                      _customMarkets.add({
                        'name': nameController.text,
                        'color': selectedColor,
                      });
                    });
                    _saveCustomMarkets();
                    _loadMarkets(); // Listeyi yenile
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 10),
                            Text('${nameController.text} eklendi!'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Ekle', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Yönetimi'),
      ),
      body: _allMarkets.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Henüz market eklenmemiş',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sağ alttaki + butonuna tıklayın',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _allMarkets.length,
              itemBuilder: (context, i) {
                final market = _allMarkets[i];
                final isDefault = market['isDefault'] as bool;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDefault 
                            ? market['color'] as Color
                            : market['color'] as Color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: market['logo'] != null && market['logo'].toString().isNotEmpty
                          ? Image.asset(
                              market['logo'],
                              width: 40,
                              height: 40,
                              errorBuilder: (context, error, stackTrace) => Text(
                                market['name'].toString().substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : Text(
                              market['name'].toString().substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    title: Text(
                      market['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      isDefault ? 'Varsayılan Market' : 'Özel Market',
                      style: TextStyle(
                        color: isDefault ? Colors.blue : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isDefault) // Sadece custom marketler düzenlenebilir
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditDialog(i),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteDialog(i, market),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Market Ekle'),
      ),
    );
  }

  void _showDeleteDialog(int index, Map<String, dynamic> market) {
    final isDefault = market['isDefault'] as bool;
    final marketName = market['name'] as String;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Market Sil'),
        content: Text(
          isDefault 
              ? '$marketName varsayılan marketini gizlemek istediğinize emin misiniz?\n\nBu marketi tekrar görmek için uygulamayı sıfırlamanız gerekir.'
              : '$marketName marketini silmek istediğinize emin misiniz?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (isDefault) {
                setState(() {
                  _hiddenDefaultMarkets.add(marketName);
                });
                _saveHiddenDefaultMarkets();
              } else {
                setState(() {
                  _customMarkets.removeAt(index - _allMarkets.where((m) => m['isDefault'] == true).length);
                });
                _saveCustomMarkets();
              }
              _loadMarkets(); // Listeyi yenile
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isDefault 
                        ? '$marketName gizlendi!'
                        : '$marketName silindi!'
                  ),
                ),
              );
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(int index) {
    final customIndex = index - _allMarkets.where((m) => m['isDefault'] == true).length;
    final market = _customMarkets[customIndex];
    final nameController = TextEditingController(text: market['name']);
    String selectedColor = market['color'] ?? 'grey';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Marketi Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Market Adı',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Renk:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'red', 'green', 'blue', 'orange', 'purple',
                  'brown', 'teal', 'pink', 'amber', 'indigo',
                  'cyan', 'lime', 'deepOrange', 'lightBlue'
                ].map((color) => GestureDetector(
                  onTap: () => setDialogState(() => selectedColor = color),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getColor(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedColor == color ? Colors.black : Colors.grey.shade300,
                        width: selectedColor == color ? 3 : 1,
                      ),
                    ),
                    child: selectedColor == color
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _customMarkets[customIndex] = {
                      'name': nameController.text,
                      'color': selectedColor,
                    };
                  });
                  _saveCustomMarkets();
                  _loadMarkets(); // Listeyi yenile
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${nameController.text} güncellendi!')),
                  );
                }
              },
              child: const Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }
}

