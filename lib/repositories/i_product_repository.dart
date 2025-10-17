import '../models/product.dart';

abstract class IProductRepository {
  Future<void> addProduct(Product product);
  Future<List<Product>> getAllProducts();
  Future<Product?> getProductByKey(dynamic key);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(dynamic key); // Hard delete (for completeness)
  Future<void> softDeleteProduct(Product product); // Soft delete
}

