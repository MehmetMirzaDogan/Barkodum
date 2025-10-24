import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/app_constants.dart';

class CategoryManagePage extends StatefulWidget {
  final String market;
  const CategoryManagePage({super.key, required this.market});

  @override
  State<CategoryManagePage> createState() => _CategoryManagePageState();
}

class _CategoryManagePageState extends State<CategoryManagePage> {
  List<Map<String, String>> _categories = [];
  bool _hasChanges = false;
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    
    final marketCategoryKey = 'custom_categories_${widget.market}';
    final categoriesJson = prefs.getString(marketCategoryKey);
    
    final isCustomMarket = !['Migros', 'BİM', 'ŞOK', 'A101'].contains(widget.market);
    
    if (categoriesJson != null) {
      final List<dynamic> decoded = jsonDecode(categoriesJson);
      setState(() {
        _categories = decoded.map((e) => Map<String, String>.from(e)).toList();
      });
    } else {
      if (isCustomMarket) {
        setState(() {
          _categories = [];
        });
      } else {
        setState(() {
          _categories = List<Map<String, String>>.from(AppConstants.categories.map((cat) => {
            'name': cat['name']!,
            'emoji': cat['emoji']!,
            'color': cat['color']!, // Kırmızı, yeşil, turuncu
          }));
        });
      }
      await _saveCategories();
    }
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final marketCategoryKey = 'custom_categories_${widget.market}';
    await prefs.setString(marketCategoryKey, jsonEncode(_categories));
    _hasChanges = true;
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    String selectedEmoji = '📦';
    String selectedColor = 'blue';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni Kategori'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Kategori Adı',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Emoji: '),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final emoji = await _showEmojiPicker(context);
                      if (emoji != null) {
                        setDialogState(() => selectedEmoji = emoji);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(selectedEmoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Renk:'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'red', 'green', 'blue', 'orange', 'purple', 
                  'brown', 'teal', 'pink', 'grey', 'amber',
                  'cyan', 'indigo', 'lime', 'deepOrange', 'deepPurple',
                  'lightBlue', 'lightGreen', 'yellow', 'redAccent', 'blueAccent',
                  'greenAccent', 'orangeAccent', 'purpleAccent', 'pinkAccent', 'tealAccent'
                ].map((color) => GestureDetector(
                  onTap: () => setDialogState(() => selectedColor = color),
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: _getColor(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedColor == color ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                    ),
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
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _categories.add({
                      'name': nameController.text,
                      'emoji': selectedEmoji,
                      'color': selectedColor,
                    });
                  });
                  await _saveCategories();
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${nameController.text} eklendi!')),
                    );
                  }
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showEmojiPicker(BuildContext context) async {
    final emojis = [
      '🍎', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🫐', '🍈', '🍒',
      '🥦', '🥬', '🥒', '🌶️', '🫑', '🥕', '🧄', '🧅', '🥔', '🍠',
      '🥜', '🌰', '🫘', '🫚', '🌿', '🍃', '🪴', '🌾', '🪵', '🍄',
      '🥖', '🥐', '🍞', '🥨', '🧀', '🥚', '🥓', '🥩', '🍗', '🍖',
      '🐟', '🦐', '🦞', '🦀', '🐙', '🍵', '☕', '🥤', '🧃', '🧺',
    ];

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emoji Seç'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: GridView.count(
            crossAxisCount: 5,
            children: emojis.map((emoji) => GestureDetector(
              onTap: () => Navigator.pop(context, emoji),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              ),
            )).toList(),
          ),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori Yönetimi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _hasChanges),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        itemBuilder: (context, i) {
          final cat = _categories[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getColor(cat['color'] ?? 'grey').withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(cat['emoji'] ?? '📦', style: const TextStyle(fontSize: 24)),
              ),
              title: Text(cat['name'] ?? ''),
              subtitle: Text('Renk: ${cat['color']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditDialog(i),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() => _categories.removeAt(i));
                      _saveCategories();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditDialog(int index) {
    final cat = _categories[index];
    final nameController = TextEditingController(text: cat['name']);
    String selectedEmoji = cat['emoji'] ?? '📦';
    String selectedColor = cat['color'] ?? 'grey';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Kategoriyi Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Kategori Adı',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Emoji: '),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final emoji = await _showEmojiPicker(context);
                      if (emoji != null) {
                        setDialogState(() => selectedEmoji = emoji);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(selectedEmoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Renk:'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'red', 'green', 'blue', 'orange', 'purple',
                  'brown', 'teal', 'pink', 'grey', 'amber',
                  'cyan', 'indigo', 'lime', 'deepOrange', 'deepPurple',
                  'lightBlue', 'lightGreen', 'yellow', 'redAccent', 'blueAccent',
                  'greenAccent', 'orangeAccent', 'purpleAccent', 'pinkAccent', 'tealAccent'
                ].map((color) => GestureDetector(
                  onTap: () => setDialogState(() => selectedColor = color),
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: _getColor(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedColor == color ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                    ),
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
                    _categories[index] = {
                      'name': nameController.text,
                      'emoji': selectedEmoji,
                      'color': selectedColor,
                    };
                  });
                  _saveCategories();
                  Navigator.pop(context);
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

