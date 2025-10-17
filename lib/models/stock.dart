import 'package:hive/hive.dart';

part 'stock.g.dart';

@HiveType(typeId: 1)
class Stock extends HiveObject {
  @HiveField(0)
  String warehouse;

  @HiveField(1)
  String gtin; // Unique identifier for the product, not the Hive key

  @HiveField(2)
  int quantity;

  Stock({required this.warehouse, required this.gtin, required this.quantity});
}


