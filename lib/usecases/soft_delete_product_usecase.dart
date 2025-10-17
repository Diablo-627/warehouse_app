import '../models/product.dart';
import '../services/product_service.dart';

class SoftDeleteProductUseCase {
  final ProductService _productService;

  SoftDeleteProductUseCase(this._productService);

  Future<void> execute(Product product) {
    return _productService.softDeleteProduct(product);
  }
}

