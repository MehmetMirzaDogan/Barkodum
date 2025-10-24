import 'package:sqflite/sqflite.dart';
import 'database.dart';
import 'product.dart';

class ProductRepository {
  final String market;
  ProductRepository(this.market);

  Future<void> insert(Product product) async {
    final db = await AppDatabase.instance(market);
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Product>> search(String query) async {
    final db = await AppDatabase.instance(market);
    String normalize(String text) {
      return text
          .toLowerCase()
          .replaceAll('ı', 'i')
          .replaceAll('İ', 'i')
          .replaceAll('ö', 'o')
          .replaceAll('ü', 'u')
          .replaceAll('ş', 's')
          .replaceAll('ç', 'c')
          .replaceAll('ğ', 'g');
    }

    final q = normalize(query);
    final result = await db.rawQuery('''
      SELECT * FROM products
      WHERE (
        LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(name,
          'ı','i'),'İ','i'),'ş','s'),'ç','c'),'ö','o'),'ü','u'),'ğ','g')) LIKE ?
        OR LOWER(name) LIKE ?
        OR barcode LIKE ?
      )
      AND isActive = 1
      ORDER BY name COLLATE NOCASE ASC
    ''', ['%$q%', '%${query.toLowerCase()}%', '%$q%']);
    return result.map((e) => Product.fromMap(e)).toList();
  }

  Future<bool> isEmpty() async {
    final db = await AppDatabase.instance(market);
    final result = await db.query('products', limit: 1);
    return result.isEmpty;
  }

  Future<void> insertAll(List<Product> items) async {
    final db = await AppDatabase.instance(market);
    final batch = db.batch();
    for (var p in items) {
      batch.insert('products', p.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance(market);
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> update(Product product) async {
    final db = await AppDatabase.instance(market);
    await db.update('products', product.toMap(),
        where: 'id = ?', whereArgs: [product.id]);
  }

  Future<void> deleteMultiple(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await AppDatabase.instance(market);
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.rawDelete('DELETE FROM products WHERE id IN ($placeholders)', ids);
  }

  Future<void> updateMultiple(List<int> ids, Map<String, dynamic> values) async {
    if (ids.isEmpty) return;
    final db = await AppDatabase.instance(market);
    final placeholders = List.filled(ids.length, '?').join(',');
    final sets = values.keys.map((k) => "$k = ?").join(',');
    final args = [...values.values, ...ids];
    await db.rawUpdate('UPDATE products SET $sets WHERE id IN ($placeholders)', args);
  }

  Future<Product?> findByBarcode(String barcode) async {
    final db = await AppDatabase.instance(market);
    final result = await db.query('products',
        where: 'barcode = ?', whereArgs: [barcode], limit: 1);
    if (result.isEmpty) return null;
    return Product.fromMap(result.first);
  }

  Future<List<Product>> getFavorites() async {
    final db = await AppDatabase.instance(market);
    final result =
    await db.query('products', where: 'isFavorite = 1 AND isActive = 1', orderBy: 'name COLLATE NOCASE ASC');
    return result.map((e) => Product.fromMap(e)).toList();
  }

  Future<List<Product>> getInactive() async {
    final db = await AppDatabase.instance(market);
    final result = await db.query('products', where: 'isActive = 0', orderBy: 'name COLLATE NOCASE ASC');
    return result.map((e) => Product.fromMap(e)).toList();
  }

  Future<Map<String, int>> getCounts() async {
    final db = await AppDatabase.instance(market);
    
    final basicRes = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN isActive = 1 THEN 1 ELSE 0 END) AS activeCount,
        SUM(CASE WHEN isFavorite = 1 AND isActive = 1 THEN 1 ELSE 0 END) AS favCount,
        SUM(CASE WHEN isActive = 0 THEN 1 ELSE 0 END) AS inactiveCount
      FROM products
    ''');
    final basicRow = basicRes.first;
    
    final categoryRes = await db.rawQuery('''
      SELECT category, COUNT(*) as count
      FROM products
      WHERE isActive = 1 AND category IS NOT NULL AND category != ''
      GROUP BY category
    ''');
    
    final counts = {
      'active': (basicRow['activeCount'] as int?) ?? 0,
      'fav': (basicRow['favCount'] as int?) ?? 0,
      'inactive': (basicRow['inactiveCount'] as int?) ?? 0,
    };
    
    for (var row in categoryRes) {
      final category = row['category'] as String;
      final count = (row['count'] as int?) ?? 0;
      
      String normalize(String text) {
        return text
            .toLowerCase()
            .replaceAll('ı', 'i')
            .replaceAll('İ', 'i')
            .replaceAll('ö', 'o')
            .replaceAll('ü', 'u')
            .replaceAll('ş', 's')
            .replaceAll('ç', 'c')
            .replaceAll('ğ', 'g')
            .replaceAll(' ', '_');
      }
      
      final key = normalize(category);
      counts[key] = count;
    }
    
    return counts;
  }

  Future<List<Product>> searchByFilter(
      String query, {
        String? category,
        bool? onlyActive,
        bool? onlyFavorites,
      }) async {
    final db = await AppDatabase.instance(market);
    
    String normalize(String text) {
      return text
          .toLowerCase()
          .replaceAll('ı', 'i')
          .replaceAll('İ', 'i')
          .replaceAll('ö', 'o')
          .replaceAll('ü', 'u')
          .replaceAll('ş', 's')
          .replaceAll('ç', 'c')
          .replaceAll('ğ', 'g');
    }
    
    final buffer = StringBuffer("SELECT * FROM products WHERE 1=1");
    final params = <dynamic>[];
    
    if (query.isNotEmpty) {
      final normalized = normalize(query);
      buffer.write(''' AND (
        LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(name,
          'ı','i'),'İ','i'),'ş','s'),'ç','c'),'ö','o'),'ü','u'),'ğ','g')) LIKE ?
        OR LOWER(name) LIKE ?
        OR barcode LIKE ?
      )''');
      params.addAll(['%$normalized%', '%${query.toLowerCase()}%', '%$normalized%']);
    }
    if (category != null) buffer.write(" AND category = '$category'");
    if (onlyActive != null) buffer.write(" AND isActive = ${onlyActive ? 1 : 0}");
    if (onlyFavorites == true) buffer.write(" AND isFavorite = 1");
    buffer.write(" ORDER BY name COLLATE NOCASE ASC");
    
    final result = await db.rawQuery(buffer.toString(), params);
    return result.map((e) {
      final product = Product.fromMap(e);
      return product.copyWith(colorHint: product.isActive ? null : 'grey');
    }).toList();
  }
}
