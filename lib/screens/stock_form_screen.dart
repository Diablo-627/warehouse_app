
import 'package:flutter/material.dart';

import 'package:warehouse_app/models/product.dart';
import '../models/stock.dart';
import 'package:get_it/get_it.dart';
import '../services/stock_service.dart';
import '../services/product_service.dart';
class StockFormScreen extends StatefulWidget {
  final Stock? stock;

  const StockFormScreen({super.key, this.stock});

  @override
  StockFormScreenState createState() => StockFormScreenState();
}

class StockFormScreenState extends State<StockFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _warehouseController = TextEditingController();
  final _gtinController = TextEditingController();
  final _quantityController = TextEditingController();
  StockService get _stockService => GetIt.I<StockService>();
  
  List<Product> _availableProducts = [];
  Product? _selectedProduct;
  
  ProductService get _productService => GetIt.I<ProductService>();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    if (widget.stock != null) {
      _warehouseController.text = widget.stock!.warehouse;
      _gtinController.text = widget.stock!.gtin;
      _quantityController.text = widget.stock!.quantity.toString();
    }
  }

  Future<void> _loadProducts() async {
    final products = await _productService.getAllProducts();
    setState(() {
      _availableProducts = products;
      if (widget.stock != null) {
        _selectedProduct = products.firstWhere(
          (p) => p.gtin == widget.stock!.gtin,
          orElse: () => products.first, // Fallback if product not found
        );
      }
    });
  }

  @override
  void dispose() {
    _warehouseController.dispose();
    _gtinController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _saveStock() async {
    if (_formKey.currentState!.validate()) {
      final warehouse = _warehouseController.text;
      final gtin = _gtinController.text;
      final quantity = int.parse(_quantityController.text);

      if (widget.stock == null) {
        // Add new stock or update existing quantity
        await _stockService.addOrUpdateStock(warehouse, gtin, quantity);
      } else {
        // Edit existing stock (only quantity and warehouse can be updated, GTIN is fixed)
        widget.stock!.warehouse = warehouse;
        widget.stock!.quantity = quantity;
        await _stockService.updateStock(widget.stock!); // Assuming updateStock handles this
      }
      // ignore: use_build_context_synchronously
      Navigator.pop(context, true); // Return true to indicate success and refresh list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stock == null ? 'Добавить Остаток' : 'Редактировать Остаток'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _warehouseController,
                decoration: const InputDecoration(labelText: 'Склад'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите название склада';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              if (widget.stock == null) // Only allow selecting product for new stock entries
                DropdownButtonFormField<Product>(
                  initialValue: _selectedProduct,
                  decoration: const InputDecoration(labelText: 'Выберите Товар (GTIN)'),
                  items: _availableProducts.map((product) {
                    return DropdownMenuItem<Product>(
                      value: product,
                      child: Text('${product.name} (${product.gtin})'),
                    );
                  }).toList(),
                  onChanged: (Product? newValue) {
                    setState(() {
                      _selectedProduct = newValue;
                      _gtinController.text = newValue?.gtin ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Пожалуйста, выберите товар';
                    }
                    return null;
                  },
                )
              else
                TextFormField(
                  controller: _gtinController,
                  decoration: const InputDecoration(labelText: 'GTIN'),
                  readOnly: true, // GTIN is not editable for existing stock
                ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Количество'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите количество';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Количество должно быть положительным целым числом';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveStock,
                child: Text(widget.stock == null ? 'Добавить' : 'Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// StockService реализован в lib/services/stock_service.dart и доступен через GetIt

