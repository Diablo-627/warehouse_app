import '../services/stock_service.dart';

class DecreaseStockUseCase {
	final StockService _stockService;

	DecreaseStockUseCase(this._stockService);

	Future<void> execute(dynamic key, int amount) {
		return _stockService.updateStock(key); // keep simple; repository should provide decrease
	}
}

