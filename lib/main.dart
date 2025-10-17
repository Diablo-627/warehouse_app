import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';


import 'package:hive_flutter/hive_flutter.dart';
import 'package:get_it/get_it.dart';
import 'models/product.dart';
import 'models/stock.dart';
import 'screens/product_list_screen.dart';
import 'screens/stock_list_screen.dart';
import 'repositories/i_product_repository.dart';
import 'repositories/i_stock_repository.dart';
import 'repositories/hive_product_repository.dart';
import 'repositories/hive_stock_repository.dart';
import 'services/product_service.dart';
import 'services/stock_service.dart';
import 'usecases/add_product_usecase.dart';
import 'usecases/update_product_usecase.dart';
import 'usecases/soft_delete_product_usecase.dart';
import 'usecases/get_active_products_usecase.dart';
import 'usecases/get_all_products_usecase.dart';
import 'usecases/get_all_stocks_usecase.dart';
import 'usecases/add_or_update_stock_usecase.dart';
import 'usecases/delete_stock_usecase.dart';
import 'usecases/decrease_stock_usecase.dart';

final GetIt sl = GetIt.instance; // Service Locator

void setupServiceLocator() {
  // Repositories
  sl.registerLazySingleton<IProductRepository>(() => HiveProductRepository());
  sl.registerLazySingleton<IStockRepository>(() => HiveStockRepository());

  // Services
  sl.registerLazySingleton(() => ProductService(sl()));
  sl.registerLazySingleton(() => StockService(sl()));


  // Use Cases
  sl.registerLazySingleton(() => AddProductUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProductUseCase(sl()));
  sl.registerLazySingleton(() => SoftDeleteProductUseCase(sl()));
  sl.registerLazySingleton(() => GetActiveProductsUseCase(sl()));
  sl.registerLazySingleton(() => GetAllProductsUseCase(sl()));

  // Stocks usecases
  sl.registerLazySingleton(() => GetAllStocksUseCase(sl()));
  sl.registerLazySingleton(() => AddOrUpdateStockUseCase(sl()));
  sl.registerLazySingleton(() => DeleteStockUseCase(sl()));
  sl.registerLazySingleton(() => DecreaseStockUseCase(sl()));

}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Регистрация адаптеров Hive
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(StockAdapter());
  await Hive.openBox<Product>('products');
  await Hive.openBox<Stock>('stocks');

  setupServiceLocator(); // Setup dependencies

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
    @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Складской Учет',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black54),
        scaffoldBackgroundColor: Colors.grey[900],
        cardColor: Colors.grey[800],
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.white70),
          titleMedium: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey[700], foregroundColor: Colors.white),
        ),
      ),
      themeMode: Provider.of<ThemeProvider>(context).themeMode,
      home: const HomeScreen(),
    );
  }
}



class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная'),
        actions: [
          IconButton(
            icon: Icon(Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false)
                  .toggleTheme(Theme.of(context).brightness == Brightness.light);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Товары'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductListScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Остатки'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StockListScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
