import 'package:flutter/material.dart';

class AppConstants {
  static const List<Map<String, String>> categories = [
    {'name': 'Meyve', 'emoji': '🍎', 'color': 'red'},
    {'name': 'Sebze', 'emoji': '🥦', 'color': 'green'},
    {'name': 'Kuruyemiş', 'emoji': '🥜', 'color': 'orange'},
  ];

  static const List<String> units = ['kg', 'adet', 'gr'];

  static const List<Map<String, dynamic>> categoryTabs = [
    {'label': 'Satışta', 'emoji': '🛒', 'key': 'active'},
    {'label': 'Favoriler', 'emoji': '⭐', 'key': 'fav'},
    {'label': 'Satış Dışı', 'emoji': '🚫', 'key': 'inactive'},
    {'label': 'Meyve', 'emoji': '🍎', 'key': 'meyve'},
    {'label': 'Sebze', 'emoji': '🥦', 'key': 'sebze'},
    {'label': 'Kuruyemiş', 'emoji': '🥜', 'key': 'kuruyemis'},
  ];

  static const List<Map<String, dynamic>> markets = [
    {
      'name': 'Migros',
      'color': Color(0xFFFFB26B),
      'logo': 'assets/logos/migros.png'
    },
    {'name': 'BİM', 'color': Color(0xFFFF8A80), 'logo': 'assets/logos/bim.png'},
    {'name': 'ŞOK', 'color': Color(0xFFFFF176), 'logo': 'assets/logos/sok.png'},
    {'name': 'A101', 'color': Color(0xFF81D4FA), 'logo': 'assets/logos/a101.png'},
  ];

  static Map<String, dynamic> getMarketTheme(String market, {Color? customColor}) {
    switch (market) {
      case 'Migros':
        return {
          'color': const Color(0xFFFFC68A),
          'darkColor': const Color(0xFFB36A2E),
          'logo': 'assets/logos/migros.png'
        };
      case 'BİM':
        return {
          'color': const Color(0xFFFF9B9B),
          'darkColor': const Color(0xFF8C2B2B),
          'logo': 'assets/logos/bim.png'
        };
      case 'ŞOK':
        return {
          'color': const Color(0xFFFFE58A),
          'darkColor': const Color(0xFF8A6F0F),
          'logo': 'assets/logos/sok.png'
        };
      case 'A101':
        return {
          'color': const Color(0xFF90D6FF),
          'darkColor': const Color(0xFF246A8A),
          'logo': 'assets/logos/a101.png'
        };
      default:
        final color = customColor ?? Colors.grey;
        return {
          'color': color,
          'darkColor': Color.fromRGBO(
            (color.red * 0.6).toInt(),
            (color.green * 0.6).toInt(),
            (color.blue * 0.6).toInt(),
            1.0,
          ),
          'logo': '',
        };
    }
  }

  static getCategoryColor(String key, bool isDark) {
    if (isDark) {
      return {
            'meyve': Colors.red.shade700,
            'sebze': Colors.green.shade700,
            'kuruyemis': Colors.orange.shade700,
          }[key] ??
          const Color(0xFF505050);
    } else {
      return {
            'meyve': Colors.red.shade300,
            'sebze': Colors.green.shade300,
            'kuruyemis': Colors.orange.shade300,
          }[key] ??
          const Color(0xFFE1E1E1);
    }
  }

  static const int searchDebounceDuration = 300;
}

