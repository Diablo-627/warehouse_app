import '../models/product.dart';
import '../services/product_service.dart';

class AddProductUseCase {
  final ProductService _productService;

  AddProductUseCase(this._productService);

  Future<void> execute(Product product) {
    return _productService.addProduct(product);
  }
}

