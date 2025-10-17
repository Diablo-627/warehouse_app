import '../models/product.dart';
import '../services/product_service.dart';

class GetActiveProductsUseCase {
  final ProductService _productService;

  GetActiveProductsUseCase(this._productService);

  Future<List<Product>> execute() async {
    final allProducts = await _productService.getAllProducts();
    return allProducts.where((p) => p.isActive).toList();
  }
}

