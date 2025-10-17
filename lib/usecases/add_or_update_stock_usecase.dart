import '../services/stock_service.dart';

class AddOrUpdateStockUseCase {
	final StockService _stockService;

	AddOrUpdateStockUseCase(this._stockService);

	Future<void> execute(String warehouse, String gtin, int quantity) {
		return _stockService.addOrUpdateStock(warehouse, gtin, quantity);
	}
}

