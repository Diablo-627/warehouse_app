import 'package:hive/hive.dart';

part 'product.g.dart'; // Р“РµРЅРµСЂРёСЂСѓРµРјС‹Р№ Р°РґР°РїС‚РµСЂ

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String gtin; // 13 С†РёС„СЂ (unique identifier, but not Hive key)

  @HiveField(2)
  bool isActive;

  @HiveField(3)
  double price;

  @HiveField(4)
  // Путь к изображению. Может быть URL (http...) или локальный абсолютный путь к файлу.
  String? imagePath;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime? updatedAt;

  @HiveField(7)
  DateTime? deletedAt;

  Product({
    required this.name,
    required this.gtin,
    this.isActive = true,
    required this.price,
    this.imagePath,
    DateTime? createdAt,
    this.updatedAt,
    this.deletedAt,
    String? id,
  }) : createdAt = createdAt ?? DateTime.now();
}



