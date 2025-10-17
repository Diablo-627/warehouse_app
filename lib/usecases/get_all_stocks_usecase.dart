import '../models/stock.dart';
import '../services/stock_service.dart';

class GetAllStocksUseCase {
	final StockService _stockService;

	GetAllStocksUseCase(this._stockService);

	Future<List<Stock>> execute() {
		return _stockService.getAllStocks();
	}
}


