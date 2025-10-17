import '../models/product.dart';
import '../repositories/i_product_repository.dart';

class ProductService {
  final IProductRepository _repository;

  ProductService(this._repository);

  Future<void> addProduct(Product product) => _repository.addProduct(product);
  Future<List<Product>> getAllProducts() => _repository.getAllProducts();
  Future<Product?> getProductByKey(dynamic key) => _repository.getProductByKey(key);
  Future<void> updateProduct(Product product) => _repository.updateProduct(product);
  Future<void> deleteProduct(dynamic key) => _repository.deleteProduct(key);
  Future<void> softDeleteProduct(Product product) => _repository.softDeleteProduct(product);
}

