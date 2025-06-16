import '../models/product.dart';
import '../utils/database_helper.dart';

class ProductRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertProduct(Product product) async {
    return await dbHelper.insert('products', product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    final rows = await dbHelper.queryAllRows('products');
    return rows.map((row) => Product.fromMap(row)).toList();
  }

  Future<List<Product>> getActiveProducts() async {
    final rows = await dbHelper.queryWhere('products', 'is_active = ?', [1]);
    return rows.map((row) => Product.fromMap(row)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final rows = await dbHelper.queryWhere('products', 'id = ?', [id]);
    return rows.isNotEmpty ? Product.fromMap(rows.first) : null;
  }

  Future<int> updateProduct(Product product) async {
    return await dbHelper.update(
      'products',
      product.toMap(),
      'id = ?',
      [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    return await dbHelper.delete('products', 'id = ?', [id]);
  }

  Future<int> updateStock(int productId, int quantity) async {
    final product = await getProductById(productId);
    if (product == null) return 0;
    
    final updatedProduct = product.copyWith(stock: product.stock + quantity);
    return await updateProduct(updatedProduct);
  }
}
