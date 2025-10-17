import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:warehouse_app/models/product.dart';
// ignore: unused_import
import '../services/product_service.dart';
import '../models/stock.dart';
import 'stock_form_screen.dart';
import 'package:get_it/get_it.dart';
import '../services/stock_service.dart';

class StockListScreen extends StatefulWidget {
  const StockListScreen({super.key});

  @override
  StockListScreenState createState() => StockListScreenState();
}

class StockListScreenState extends State<StockListScreen> {
  StockService get _stockService => GetIt.I<StockService>();
  List<Stock> _stocks = [];
  List<Stock> _filteredStocks = [];
  String? _selectedWarehouseFilter;
  Map<String, int> _totalQuantities = {};
  
  // ignore: non_constant_identifier_names
  get AppLocalizations => null;

  @override
  void initState() {
    super.initState();
    _loadStocks();
  }

  Future<void> _loadStocks() async {
    final allStocks = await _stockService.getAllStocks();
    setState(() {
      _stocks = allStocks;
      _applyFilterAndCalculateTotals();
    });
  }

  void _applyFilterAndCalculateTotals() {
    _filteredStocks = _stocks.where((stock) {
      return _selectedWarehouseFilter == null ||
          _selectedWarehouseFilter == 'All' ||
          stock.warehouse == _selectedWarehouseFilter;
    }).toList();

    _totalQuantities = {};
    for (var stock in _stocks) {
      _totalQuantities.update(stock.warehouse, (value) => value + stock.quantity, ifAbsent: () => stock.quantity);
    }
  }

  Future<void> _removeStock(Stock stock) async {
    final TextEditingController quantityToRemoveController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Убрать со склада'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Введите количество для GTIN ${stock.gtin} со склада ${stock.warehouse}'),
                TextFormField(
                  controller: quantityToRemoveController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Количество'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите количество';
                    }
                    final int? quantity = int.tryParse(value);
                    if (quantity == null || quantity <= 0) {
                      return 'Некорректное количество';
                    }
                    if (quantity > stock.quantity) {
                      return 'Недостаточно товара на складе';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Убрать'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final int quantityToRemove = int.parse(quantityToRemoveController.text);
      if (quantityToRemove == stock.quantity) {
        await _stockService.deleteStock(stock.key); // Remove completely if all stock is removed
      } else {
        stock.quantity -= quantityToRemove;
        await _stockService.updateStock(stock);
      }
      _loadStocks();
    }
  }

  // ignore: unused_element
  Future<void> _deleteStock(Stock stock) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirmDeleteProductTitle),
          content: Text("${AppLocalizations.of(context)!.confirmDeleteProductMessage} ${stock.quantity} ${AppLocalizations.of(context)!.unitsOf} GTIN ${stock.gtin} ${AppLocalizations.of(context)!.fromWarehouse} ${stock.warehouse}?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppLocalizations.of(context)!.removeStock),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _stockService.deleteStock(stock.key);
      _loadStocks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uniqueWarehouses = {'All', ..._stocks.map((s) => s.warehouse).toSet()};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Остатки'),
        actions: [
          DropdownButton<String>(
            value: _selectedWarehouseFilter ?? 'All',
            onChanged: (String? newValue) {
              setState(() {
                _selectedWarehouseFilter = newValue;
                _applyFilterAndCalculateTotals();
              });
            },
            items: uniqueWarehouses.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value == 'All' ? 'Все склады' : value),
              );
            }).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
children: _totalQuantities.entries.map((entry) => Text(
	                'Всего на складе ${entry.key}: ${entry.value}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              )).toList(),
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
                    itemCount: _filteredStocks.length,
                    itemBuilder: (context, index) {
                      final stock = _filteredStocks[index];
                      return Card(
                        margin: const EdgeInsets.all(4),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
Text(
	                                'Склад: ${stock.warehouse}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
Text(
	                                'GTIN: ${stock.gtin}',
	                              ),
Text(
	                                'Количество: ${stock.quantity}',
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
                                          builder: (context) => StockFormScreen(stock: stock),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadStocks();
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _removeStock(stock),
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
                    itemCount: _filteredStocks.length,
                    itemBuilder: (context, index) {
                      final stock = _filteredStocks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
title: Text(
	                            'Склад: ${stock.warehouse}',
	                          ),
subtitle: Text(
	                            'GTIN: ${stock.gtin}, Количество: ${stock.quantity}',
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
                                      builder: (context) => StockFormScreen(stock: stock),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadStocks();
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _removeStock(stock),
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
            MaterialPageRoute(builder: (context) => const StockFormScreen()),
          );
          if (result == true) {
            _loadStocks();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// StockService реализован в lib/services/stock_service.dart и доступен через GetIt

