
import 'package:flutter/material.dart';

import 'package:get_it/get_it.dart';
import '../usecases/soft_delete_product_usecase.dart';
import '../usecases/get_all_products_usecase.dart';
import '../models/product.dart';
import 'product_form_screen.dart';
import 'dart:io';

enum ProductSortKey { name, createdAt }

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  ProductListScreenState createState() => ProductListScreenState();
}

class ProductListScreenState extends State<ProductListScreen> {
  final GetAllProductsUseCase _getAllProductsUseCase = GetIt.I<GetAllProductsUseCase>();
  final SoftDeleteProductUseCase _softDeleteProductUseCase = GetIt.I<SoftDeleteProductUseCase>();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  ProductSortKey _sortKey = ProductSortKey.createdAt;
  bool _sortAscending = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProducts);
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadProducts() async {
    final allProducts = await _getAllProductsUseCase.execute(); // Получаем все, включая удаленные
    setState(() {
      _products = allProducts;
      _filterProducts(); // Apply current filter and sort
    });
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      // Фильтруем по GTIN или по имени, чтобы поиск был удобнее для пользователя
      _filteredProducts = _products.where((product) {
        final gtin = product.gtin.toLowerCase();
        final name = product.name.toLowerCase();
        return gtin.contains(query) || name.contains(query);
      }).toList();
      // После фильтрации применяем сортировку
      _sortProducts();
    });
  }

  void _sortProducts() {
    _filteredProducts.sort((a, b) {
      int comparison = 0;
      if (_sortKey == ProductSortKey.name) {
        comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      } else if (_sortKey == ProductSortKey.createdAt) {
        comparison = a.createdAt.compareTo(b.createdAt);
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  Future<void> _deleteProduct(Product product) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Подтверждение удаления'),
          content: Text('Вы уверены, что хотите удалить товар "${product.name}"? Он будет помечен как удаленный.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Пометить как Удаленный'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _softDeleteProductUseCase.execute(product);
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Товары (Активные и Удаленные)'),
        actions: [
          // Показываем текущую сортировку: ключ и направление
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                _sortKey == ProductSortKey.name
                    ? 'Сортировка: имя ${_sortAscending ? '↑' : '↓'}'
                    : 'Сортировка: дата ${_sortAscending ? '↑' : '↓'}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          PopupMenuButton<ProductSortKey>(
            onSelected: (ProductSortKey result) {
              setState(() {
                if (_sortKey == result) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortKey = result;
                  _sortAscending = true;
                }
                _sortProducts();
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<ProductSortKey>>[
              const PopupMenuItem<ProductSortKey>(
                value: ProductSortKey.name,
                child: Text('По названию'),
              ),
              const PopupMenuItem<ProductSortKey>(
                value: ProductSortKey.createdAt,
                child: Text('По дате создания'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск по GTIN',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  // Tablet or wider screen layout
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3 / 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return Card(
                        margin: const EdgeInsets.all(4),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Поддерживаем локальные пути (File) и URL
                                  if (product.imagePath != null && product.imagePath!.isNotEmpty)
                                    (product.imagePath!.toLowerCase().startsWith('http')
                                        ? Image.network(product.imagePath!, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                                        : Image.file(File(product.imagePath!), width: 60, height: 60, fit: BoxFit.cover))
                                  else
                                    const Icon(Icons.image, size: 60),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(product.name, style: Theme.of(context).textTheme.titleMedium)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('GTIN: ${product.gtin}'),
                              Text('Цена: ${product.price.toStringAsFixed(2)}'),
                              Text('Дата создания: ${product.createdAt.toLocal().toString().split(' ')[0]}'),
                              if (product.updatedAt != null)
                                Text('Дата редактирования: ${product.updatedAt!.toLocal().toString().split(' ')[0]}'),
                              Text(
                                'Статус: ${product.isActive ? 'Активен' : 'Удален'}',
                                style: TextStyle(
                                  color: product.isActive ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!product.isActive)
                                Text(
                                  'Дата удаления: ${product.deletedAt?.toLocal().toString().split(' ')[0] ?? 'N/A'}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductFormScreen(product: product),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadProducts();
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: product.isActive ? Colors.red : Colors.grey),
                                    onPressed: product.isActive
                                        ? () => _deleteProduct(product)
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  // Phone or narrower screen layout
                  return ListView.builder(
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Text(product.name),
              leading: product.imagePath != null && product.imagePath!.isNotEmpty
                ? (product.imagePath!.toLowerCase().startsWith('http')
                  ? Image.network(product.imagePath!, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                  : Image.file(File(product.imagePath!), width: 50, height: 50, fit: BoxFit.cover))
                : const Icon(Icons.image, size: 50),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('GTIN: ${product.gtin}'),
                              Text('Цена: ${product.price.toStringAsFixed(2)}'),
                              Text('Дата создания: ${product.createdAt.toLocal().toString().split(' ')[0]}'),
                              if (product.updatedAt != null)
                                Text('Дата редактирования: ${product.updatedAt!.toLocal().toString().split(' ')[0]}'),
                              Text(
                                'Статус: ${product.isActive ? 'Активен' : 'Удален'}',
                                style: TextStyle(
                                  color: product.isActive ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!product.isActive)
                                Text(
                                  'Дата удаления: ${product.deletedAt?.toLocal().toString().split(' ')[0] ?? 'N/A'}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductFormScreen(product: product),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadProducts();
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: product.isActive ? Colors.red : Colors.grey),
                                onPressed: product.isActive
                                    ? () => _deleteProduct(product)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductFormScreen()),
          );
          if (result == true) {
            _loadProducts();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// GetAllProductsUseCase реализован в usecases/get_all_products_usecase.dart


