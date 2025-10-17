
import 'package:flutter/material.dart';

import '../models/product.dart';
import 'package:get_it/get_it.dart';
import '../services/product_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  ProductFormScreenState createState() => ProductFormScreenState();
}

class ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _gtinController = TextEditingController();
  final _priceController = TextEditingController();
  // Храним путь к изображению в переменной. Может быть URL или локальный абсолютный путь.
  String? _imagePath;
  
  ProductService get _productService => GetIt.I<ProductService>();
 

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _imagePath = widget.product!.imagePath;
      _nameController.text = widget.product!.name;
      _gtinController.text = widget.product!.gtin;
      _priceController.text = widget.product!.price.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gtinController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final gtin = _gtinController.text;
      final price = double.parse(_priceController.text);
      final imagePath = (_imagePath ?? '').isEmpty ? null : _imagePath;

      if (widget.product == null) {
        // Add new product
        final newProduct = Product(
          name: name,
          gtin: gtin,
          price: price,
          createdAt: DateTime.now(),
          imagePath: imagePath, id: '',
        );
        await _productService.addProduct(newProduct);
      } else {
        // Edit existing product
        widget.product!.name = name;
        widget.product!.gtin = gtin;
        widget.product!.price = price;
        widget.product!.imagePath = imagePath;
        widget.product!.updatedAt = DateTime.now();
        await _productService.updateProduct(widget.product!); // Update the product using its HiveObject methods
      }
      // ignore: use_build_context_synchronously
      Navigator.pop(context, true); // Return true to indicate success and refresh list
    }
  }

  // Выбор изображения из галереи и копирование в каталог приложения.
  // Храним абсолютный путь к файлу в product.imagePath.
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
      if (picked == null) return;

      final tempPath = picked.path;
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(tempPath)}';
      final destPath = p.join(appDir.path, fileName);

      final copied = await File(tempPath).copy(destPath);
      setState(() {
        _imagePath = copied.path; // сохраняем локальный путь
      });
    } catch (e) {
      // Если что-то пошло не так — показываем SnackBar, но только если виджет всё ещё в дереве
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка при выборе изображения: $e')));
      }
    }
  }

  // Позволяет ввести URL вручную — полезно, если изображение хранится в сети.
  Future<void> _enterImageUrl() async {
    final ctrl = TextEditingController(text: _imagePath ?? '');
    final res = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Вставьте URL изображения'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'https://...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('OK')),
        ],
      ),
    );
    if (res != null) {
      setState(() {
        _imagePath = res.isEmpty ? null : res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Добавить Товар' : 'Редактировать Товар'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Название'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите название товара';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _gtinController,
                decoration: const InputDecoration(labelText: 'GTIN (13 цифр)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите GTIN';
                  }
                  if (value.length != 13 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'GTIN должен содержать 13 цифр';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Цена'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите цену';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Пожалуйста, введите корректную положительную цену';
                  }
                  return null;
                },
              ),
              // Блок выбора/предпросмотра изображения. Поддерживаем локальный файл и URL.
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Предпросмотр
                  Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: _imagePath != null && _imagePath!.isNotEmpty
                        ? (_imagePath!.toLowerCase().startsWith('http')
                            ? Image.network(_imagePath!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                            : Image.file(File(_imagePath!), fit: BoxFit.cover))
                        : const Icon(Icons.image, size: 40),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Выбрать из галереи'),
                          onPressed: _pickImage,
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.link),
                          label: const Text('Вставить URL'),
                          onPressed: _enterImageUrl,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProduct,
                child: Text(widget.product == null ? 'Добавить' : 'Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

