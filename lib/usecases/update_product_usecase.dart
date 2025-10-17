import '../models/product.dart';
import '../services/product_service.dart';

class UpdateProductUseCase {
  final ProductService _productService;

  UpdateProductUseCase(this._productService);

  Future<void> execute(Product product) {
    return _productService.updateProduct(product);
  }
}

