class Product {
  final int id;
  final String name;
  final String barcode;
  final String category;
  final String unit;
  final bool isFavorite;
  final bool isActive;
  final String? colorHint; // 🔹 Satışta olmayanlar için renk etiketi (örneğin gri)

  Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.category,
    required this.unit,
    this.isFavorite = false,
    this.isActive = true,
    this.colorHint,
  });

  factory Product.fromMap(Map<String, Object?> map) => Product(
    id: (map['id'] as num).toInt(),
    name: map['name'] as String,
    barcode: map['barcode'] as String,
    category: map['category'] as String,
    unit: map['unit'] as String,
    isFavorite: (map['isFavorite'] ?? 0) == 1,
    isActive: (map['isActive'] ?? 1) == 1,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'barcode': barcode,
    'category': category,
    'unit': unit,
    'isFavorite': isFavorite ? 1 : 0,
    'isActive': isActive ? 1 : 0,
  };

  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    String? category,
    String? unit,
    bool? isFavorite,
    bool? isActive,
    String? colorHint, // 🔹 yeni alan eklendi
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      isFavorite: isFavorite ?? this.isFavorite,
      isActive: isActive ?? this.isActive,
      colorHint: colorHint ?? this.colorHint,
    );
  }
}
