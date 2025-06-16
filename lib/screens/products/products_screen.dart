import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../repositories/product_repository.dart';
import '../../screens/products/product_form_screen.dart';
import 'package:provider/provider.dart';
import '../../repositories/finance_transaction_repository.dart';
import '../../repositories/finance_category_repository.dart';
import '../../models/finance_transaction.dart';
import '../../providers/auth_provider.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductRepository _productRepository = ProductRepository();
  final FinanceTransactionRepository _financeTransactionRepository =
      FinanceTransactionRepository();
  final FinanceCategoryRepository _financeCategoryRepository =
      FinanceCategoryRepository();
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _productRepository.getAllProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load products');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    try {
      await _productRepository.deleteProduct(product.id!);
      _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to delete product');
      }
    }
  }

  Future<void> _updateStock(Product product) async {
    final TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Update Stock'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current stock: ${product.stock} ${product.unit}'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Add/Remove Stock',
                    hintText: 'Enter positive or negative value',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(signed: true),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    final quantity = int.tryParse(controller.text);
                    if (quantity != null) {
                      Navigator.pop(context);
                      await _productRepository.updateStock(
                        product.id!,
                        quantity,
                      );
                      final productId = product.id;
                      final stockRef =
                          'product-$productId-stock-${DateTime.now().millisecondsSinceEpoch}';
                      final existingTransactions =
                          await _financeTransactionRepository
                              .getAllTransactions();
                      final alreadyInserted = existingTransactions.any(
                        (t) => t.referenceId == stockRef,
                      );
                      if (!alreadyInserted) {
                        final categories = await _financeCategoryRepository
                            .getActiveCategoriesByType('expense');
                        final productCategory = categories.firstWhere(
                          (c) => c.name == 'Pembelian Stok',
                          orElse: () => categories.first,
                        );
                        final authProvider = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        final userId = authProvider.currentUser?.id;
                        await _financeTransactionRepository.insertTransaction(
                          FinanceTransaction(
                            date: DateTime.now().toIso8601String().substring(
                              0,
                              10,
                            ),
                            categoryId: productCategory.id!,
                            amount: product.price,
                            description:
                                'Pengeluaran update stok produk #$productId',
                            paymentMethod: 'cash',
                            referenceId: stockRef,
                            userId: userId,
                            outletId: null,
                          ),
                        );
                      }
                      _loadProducts();
                    }
                  }
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No products found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProductFormScreen(),
                          ),
                        );
                        _loadProducts();
                      },
                      child: const Text('Add Product'),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(
                        product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: product.isActive == 1 ? null : Colors.grey,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Price: Rp${product.price}'),
                          Text(
                            'Stock: ${product.stock} ${product.unit}',
                            style: TextStyle(
                              color:
                                  product.stock > 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (product.description != null &&
                              product.description!.isNotEmpty)
                            Text('Description: ${product.description}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.inventory,
                              color: Colors.green,
                            ),
                            onPressed: () => _updateStock(product),
                            tooltip: 'Update Stock',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          ProductFormScreen(product: product),
                                ),
                              );
                              _loadProducts();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('Delete Product'),
                                      content: Text(
                                        'Are you sure you want to delete ${product.name}?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteProduct(product);
                                          },
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          );
          _loadProducts();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
