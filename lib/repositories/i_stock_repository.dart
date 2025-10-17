import '../models/stock.dart';

abstract class IStockRepository {
  Future<void> addOrUpdateStock(String warehouse, String gtin, int quantity);
  Future<List<Stock>> getAllStocks();
  Future<Stock?> getStockByKey(dynamic key);
  Future<void> updateStock(Stock stock);
  Future<void> deleteStock(dynamic key);
  Future<void> decreaseStockQuantity(dynamic key, int amountToDecrease);
}

