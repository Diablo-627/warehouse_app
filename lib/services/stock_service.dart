import '../models/stock.dart';
import '../repositories/i_stock_repository.dart';

/// Простая реализация сервиса складских операций, использующая репозиторий
class StockService {
	final IStockRepository _repository;

	StockService(this._repository);
	Future<void> addOrUpdateStock(String warehouse, String gtin, int quantity) async {
		return _repository.addOrUpdateStock(warehouse, gtin, quantity);
	}

	Future<void> updateStock(Stock stock) async {
		return _repository.updateStock(stock);
	}

	Future<List<Stock>> getAllStocks() async {
		return _repository.getAllStocks();
	}

	Future<void> deleteStock(dynamic key) async {
		return _repository.deleteStock(key);
	}
}
