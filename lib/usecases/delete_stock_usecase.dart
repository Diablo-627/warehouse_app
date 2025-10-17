import '../services/stock_service.dart';

class DeleteStockUseCase {
	final StockService _stockService;

	DeleteStockUseCase(this._stockService);

	Future<void> execute(dynamic key) {
		return _stockService.deleteStock(key);
	}
}

