import '../models/product.dart';
import '../services/product_service.dart';

class GetAllProductsUseCase {
	final ProductService _productService;

	GetAllProductsUseCase(this._productService);

	Future<List<Product>> execute() {
		return _productService.getAllProducts();
	}
}