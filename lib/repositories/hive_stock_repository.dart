import 'package:hive/hive.dart';
import '../models/stock.dart';
import 'i_stock_repository.dart';

class HiveStockRepository implements IStockRepository {
  static const String _boxName = 'stocks';

  Future<Box<Stock>> _openBox() async {
    return await Hive.openBox<Stock>(_boxName);
  }

  @override
  Future<void> addOrUpdateStock(String warehouse, String gtin, int quantity) async {
    final box = await _openBox();
    Stock? existingStock;

    for (var entry in box.toMap().entries) {
      if (entry.value.warehouse == warehouse && entry.value.gtin == gtin) {
        existingStock = entry.value;
        break;
      }
    }

    if (existingStock != null) {
      existingStock.quantity += quantity;
      await existingStock.save();
    } else {
      final newStock = Stock(warehouse: warehouse, gtin: gtin, quantity: quantity);
      await box.add(newStock);
    }
  }

  @override
  Future<List<Stock>> getAllStocks() async {
    final box = await _openBox();
    return box.values.toList();
  }

  @override
  Future<Stock?> getStockByKey(dynamic key) async {
    final box = await _openBox();
    return box.get(key);
  }

  @override
  Future<void> updateStock(Stock stock) async {
    await stock.save();
  }

  @override
  Future<void> deleteStock(dynamic key) async {
    final box = await _openBox();
    await box.delete(key);
  }

  @override
  Future<void> decreaseStockQuantity(dynamic key, int amountToDecrease) async {
    final box = await _openBox();
    Stock? stock = box.get(key);

    if (stock != null) {
      if (stock.quantity >= amountToDecrease) {
        stock.quantity -= amountToDecrease;
        await stock.save();
      } else {
        throw Exception("Cannot decrease stock by more than available quantity.");
      }
    }
  }
}

