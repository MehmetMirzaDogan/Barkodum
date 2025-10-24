import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final Map<String, Database> _instances = {};

  static Future<Database> instance(String market) async {
    if (_instances.containsKey(market)) return _instances[market]!;

    final dir = await getApplicationDocumentsDirectory();
    final dbName = 'products_${market.toLowerCase()}.db';
    final path = join(dir.path, dbName);

    final db = await openDatabase(
      path,
      version: 3, // 🔹 versiyon 3: indexler ve UNIQUE constraint eklendi
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL COLLATE NOCASE,
            barcode TEXT NOT NULL UNIQUE,
            category TEXT NOT NULL,
            unit TEXT NOT NULL,
            isFavorite INTEGER NOT NULL DEFAULT 0,
            isActive INTEGER NOT NULL DEFAULT 1,
            createdAt INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
            updatedAt INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
          )
        ''');
        
        await db.execute('CREATE INDEX idx_barcode ON products(barcode)');
        await db.execute('CREATE INDEX idx_category_active ON products(category, isActive)');
        await db.execute('CREATE INDEX idx_favorite ON products(isFavorite, isActive)');
        await db.execute('CREATE INDEX idx_name ON products(name COLLATE NOCASE)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE products ADD COLUMN isFavorite INTEGER NOT NULL DEFAULT 0');
          await db.execute('ALTER TABLE products ADD COLUMN isActive INTEGER NOT NULL DEFAULT 1');
        }
        if (oldVersion < 3) {
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          await db.execute('ALTER TABLE products ADD COLUMN createdAt INTEGER NOT NULL DEFAULT $now');
          await db.execute('ALTER TABLE products ADD COLUMN updatedAt INTEGER NOT NULL DEFAULT $now');
          
          await db.execute('CREATE INDEX IF NOT EXISTS idx_barcode ON products(barcode)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_category_active ON products(category, isActive)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_favorite ON products(isFavorite, isActive)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_name ON products(name COLLATE NOCASE)');
        }
      },
    );

    _instances[market] = db;
    return db;
  }

  static Future<void> closeAll() async {
    for (var db in _instances.values) {
      await db.close();
    }
    _instances.clear();
  }
}
