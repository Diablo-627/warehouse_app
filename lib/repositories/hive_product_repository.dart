import 'package:hive/hive.dart';
import '../models/product.dart';
import 'i_product_repository.dart';

/// Репозиторий для работы с продуктами в Hive.
///
/// Простая обертка над коробкой Hive. Сохраняет пути к изображениям
/// как строки (это может быть URL или локальный абсолютный путь).
class HiveProductRepository implements IProductRepository {
  static const String _boxName = 'products';

  // Открываем коробку (создастся при первом вызове).
  Future<Box<Product>> _openBox() async {
    return await Hive.openBox<Product>(_boxName);
  }

  @override
  Future<void> addProduct(Product product) async {
    final box = await _openBox();
    await box.add(product);
  }

  @override
  Future<List<Product>> getAllProducts() async {
    try {
      final box = await _openBox();
      // Возвращаем все значения как список. Если коробка пуста — вернется пустой список.
      return box.values.toList();
    } catch (e) {
      // На случай ошибки при чтении — возвращаем пустой список
      return <Product>[];
    }
  }

  @override
  Future<Product?> getProductByKey(dynamic key) async {
    final box = await _openBox();
    return box.get(key);
  }

  @override
  Future<void> updateProduct(Product product) async {
    // У объекта Product есть метод save() от HiveObject — используем его.
    await product.save();
  }

  @override
  Future<void> deleteProduct(dynamic key) async {
    final box = await _openBox();
    await box.delete(key);
  }

  @override
  Future<void> softDeleteProduct(Product product) async {
    // Помечаем как неактивный и записываем время удаления.
    product.isActive = false;
    product.deletedAt = DateTime.now();
    await product.save();
  }
}

