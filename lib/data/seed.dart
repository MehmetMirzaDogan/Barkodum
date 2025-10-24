import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'product.dart';
import 'product_repository.dart';

class Seeder {
  Future<void> runIfNeeded(String market) async {
    final repo = ProductRepository(market);
    final empty = await repo.isEmpty();
    if (!empty) return;

    final path = _getCsvPath(market);
    if (path == null) {
      return;
    }

    try {
      final csv = await rootBundle.loadString(path);

      final lines = const LineSplitter().convert(csv);
      if (lines.isEmpty) return;

      final items = <Product>[];
      for (var i = 1; i < lines.length; i++) {
        final cols = _safeSplit(lines[i]);
        if (cols.length < 5) continue;
        items.add(Product(
          id: int.tryParse(cols[0]) ?? i,
          name: cols[1],
          barcode: cols[2],
          category: cols[3],
          unit: cols[4],
        ));
      }
      await repo.insertAll(items);
    } catch (e) {
      return;
    }
  }

  String? _getCsvPath(String market) {
    switch (market) {
      case 'Migros':
        return 'assets/data/products_migros.csv';
      case 'BİM':
        return 'assets/data/products_bim.csv';
      case 'ŞOK':
        return 'assets/data/products_sok.csv';
      case 'A101':
        return 'assets/data/products_a101.csv';
      default:
        return null;
    }
  }

  List<String> _safeSplit(String line) => line.split(';');
}
