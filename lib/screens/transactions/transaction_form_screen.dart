import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../models/service.dart';
import '../../models/product.dart';
import '../../models/outlet.dart';
import '../../models/transaction.dart';
import '../../models/transaction_detail.dart';
import '../../repositories/customer_repository.dart';
import '../../repositories/service_repository.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/outlet_repository.dart';
import '../../repositories/transaction_repository.dart';
import '../../repositories/finance_transaction_repository.dart';
import '../../repositories/finance_category_repository.dart';
import '../../models/finance_transaction.dart';
import '../../providers/auth_provider.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({Key? key}) : super(key: key);

  @override
  _TransactionFormScreenState createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  final CustomerRepository _customerRepository = CustomerRepository();
  final ServiceRepository _serviceRepository = ServiceRepository();
  final ProductRepository _productRepository = ProductRepository();
  final OutletRepository _outletRepository = OutletRepository();
  final TransactionRepository _transactionRepository = TransactionRepository();
  final FinanceTransactionRepository _financeTransactionRepository =
      FinanceTransactionRepository();
  final FinanceCategoryRepository _financeCategoryRepository =
      FinanceCategoryRepository();

  bool _isLoading = false;
  bool _isInitializing = true;

  List<Customer> _customers = [];
  List<Service> _services = [];
  List<Product> _products = [];
  List<Outlet> _outlets = [];

  Customer? _selectedCustomer;
  Outlet? _selectedOutlet;
  String _selectedPaymentMethod = 'cash';

  final List<String> _paymentMethods = ['cash', 'transfer', 'ewallet', 'card'];

  List<TransactionItem> _selectedServices = [];
  List<TransactionItem> _selectedProducts = [];

  int _total = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      final customers = await _customerRepository.getAllCustomers();
      final services = await _serviceRepository.getActiveServices();
      final products = await _productRepository.getActiveProducts();
      final outlets = await _outletRepository.getAllOutlets();

      setState(() {
        _customers = customers;
        _services = services;
        _products = products;
        _outlets = outlets;

        if (customers.isNotEmpty) _selectedCustomer = customers.first;
        if (outlets.isNotEmpty) _selectedOutlet = outlets.first;

        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    int total = 0;

    for (var item in _selectedServices) {
      total += item.price * item.quantity;
    }

    for (var item in _selectedProducts) {
      total += item.price * item.quantity;
    }

    setState(() {
      _total = total;
    });
  }

  void _addService(Service service) {
    // Check if service already exists in the list
    final existingIndex = _selectedServices.indexWhere(
      (item) => item.id == service.id,
    );

    if (existingIndex >= 0) {
      // Update quantity if already exists
      setState(() {
        _selectedServices[existingIndex].quantity += 1;
      });
    } else {
      // Add new service
      setState(() {
        _selectedServices.add(
          TransactionItem(
            id: service.id!,
            name: service.name,
            price: service.price,
            quantity: 1,
          ),
        );
      });
    }

    _calculateTotal();
  }

  void _addProduct(Product product) {
    // Check if product already exists in the list
    final existingIndex = _selectedProducts.indexWhere(
      (item) => item.id == product.id,
    );

    if (existingIndex >= 0) {
      // Update quantity if already exists
      setState(() {
        _selectedProducts[existingIndex].quantity += 1;
      });
    } else {
      // Add new product
      setState(() {
        _selectedProducts.add(
          TransactionItem(
            id: product.id!,
            name: product.name,
            price: product.price,
            quantity: 1,
          ),
        );
      });
    }

    _calculateTotal();
  }

  void _removeService(int index) {
    setState(() {
      _selectedServices.removeAt(index);
    });
    _calculateTotal();
  }

  void _removeProduct(int index) {
    setState(() {
      _selectedProducts.removeAt(index);
    });
    _calculateTotal();
  }

  void _updateServiceQuantity(int index, int quantity) {
    if (quantity <= 0) {
      _removeService(index);
      return;
    }

    setState(() {
      _selectedServices[index].quantity = quantity;
    });
    _calculateTotal();
  }

  void _updateProductQuantity(int index, int quantity) {
    if (quantity <= 0) {
      _removeProduct(index);
      return;
    }

    setState(() {
      _selectedProducts[index].quantity = quantity;
    });
    _calculateTotal();
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedServices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan tambahkan minimal satu layanan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;

        // Create transaction
        final transaction = Transaction(
          date: DateTime.now().toIso8601String(),
          customerId: _selectedCustomer?.id,
          userId: currentUser?.id,
          outletId: _selectedOutlet?.id,
          total: _total,
          paymentMethod: _selectedPaymentMethod,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

        // Insert transaction and get the ID
        final transactionId = await _transactionRepository.insertTransaction(
          transaction,
        );

        // Insert transaction details for services
        for (var service in _selectedServices) {
          final detail = TransactionDetail(
            transactionId: transactionId,
            itemType: 'service',
            itemId: service.id,
            quantity: service.quantity,
            price: service.price,
            subtotal: service.price * service.quantity,
          );

          await _transactionRepository.insertTransactionDetail(detail);
        }

        // Insert transaction details for products
        for (var product in _selectedProducts) {
          final detail = TransactionDetail(
            transactionId: transactionId,
            itemType: 'product',
            itemId: product.id,
            quantity: product.quantity,
            price: product.price,
            subtotal: product.price * product.quantity,
          );

          await _transactionRepository.insertTransactionDetail(detail);

          // Update product stock
          await _productRepository.updateStock(product.id, -product.quantity);
        }

        // Update customer points if customer is selected
        if (_selectedCustomer != null) {
          // Add 1 point for every 10000 spent
          final pointsEarned = _total ~/ 10000;
          if (pointsEarned > 0) {
            await _customerRepository.updateCustomerPoints(
              _selectedCustomer!.id!,
              pointsEarned,
            );
          }
        }

        // Insert pemasukan keuangan otomatis
        final existingTransactions =
            await _financeTransactionRepository.getAllTransactions();
        final alreadyInserted = existingTransactions.any(
          (t) => t.referenceId == 'transaction-$transactionId',
        );
        if (!alreadyInserted) {
          final categories = await _financeCategoryRepository
              .getActiveCategoriesByType('income');
          final serviceCategory = categories.firstWhere(
            (c) => c.name == 'Penjualan Layanan',
            orElse: () => categories.first,
          );
          if (serviceCategory != null) {
            final userId = authProvider.currentUser?.id;
            await _financeTransactionRepository.insertTransaction(
              FinanceTransaction(
                date: DateTime.now().toIso8601String().substring(0, 10),
                categoryId: serviceCategory.id!,
                amount: _total,
                description: 'Pendapatan dari transaksi #$transactionId',
                paymentMethod: _selectedPaymentMethod,
                referenceId: 'transaction-$transactionId',
                userId: userId,
                outletId: _selectedOutlet?.id,
              ),
            );
          }
        }

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi berhasil dibuat')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Transaksi'),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body:
          _isInitializing
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Header with steps
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStepIndicator(1, 'Pelanggan', true),
                          _buildStepConnector(true),
                          _buildStepIndicator(
                            2,
                            'Layanan',
                            _selectedServices.isNotEmpty,
                          ),
                          _buildStepConnector(_selectedServices.isNotEmpty),
                          _buildStepIndicator(3, 'Pembayaran', false),
                        ],
                      ),
                    ),

                    // Form content
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          // Customer section
                          _buildSectionHeader(
                            'Customer Information',
                            Icons.person,
                          ),
                          const SizedBox(height: 16),
                          _buildCustomerDropdown(),
                          const SizedBox(height: 16),
                          _buildOutletDropdown(),

                          const SizedBox(height: 24),

                          // Services section
                          _buildSectionHeader('Services', Icons.content_cut),
                          const SizedBox(height: 16),
                          _buildServicesSection(),

                          const SizedBox(height: 24),

                          // Products section
                          _buildSectionHeader(
                            'Products (Optional)',
                            Icons.shopping_bag,
                          ),
                          const SizedBox(height: 16),
                          _buildProductsSection(),

                          const SizedBox(height: 24),

                          // Payment section
                          _buildSectionHeader('Payment Details', Icons.payment),
                          const SizedBox(height: 16),
                          _buildPaymentMethodDropdown(),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              labelText: 'Notes',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.note),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),

                    // Total section
                    _buildTotalSection(currencyFormat),
                  ],
                ),
              ),
    );
  }

  Widget _buildCustomerDropdown() {
    return DropdownButtonFormField<Customer?>(
      decoration: InputDecoration(
        labelText: 'Pelanggan',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.person),
      ),
      value: _selectedCustomer,
      items: [
        const DropdownMenuItem<Customer?>(
          value: null,
          child: Text('Pelanggan Langsung'),
        ),
        ..._customers.map((customer) {
          return DropdownMenuItem<Customer>(
            value: customer,
            child: Text(customer.name),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _selectedCustomer = value;
        });
      },
    );
  }

  Widget _buildOutletDropdown() {
    return DropdownButtonFormField<Outlet?>(
      decoration: InputDecoration(
        labelText: 'Outlet',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.store),
      ),
      value: _selectedOutlet,
      items: [
        const DropdownMenuItem<Outlet?>(
          value: null,
          child: Text('Tanpa Outlet'),
        ),
        ..._outlets.map((outlet) {
          return DropdownMenuItem<Outlet>(
            value: outlet,
            child: Text(outlet.name),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _selectedOutlet = value;
        });
      },
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Metode Pembayaran',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.payment),
      ),
      value: _selectedPaymentMethod,
      items:
          _paymentMethods.map((method) {
            IconData icon;
            switch (method) {
              case 'cash':
                icon = Icons.money;
                break;
              case 'transfer':
                icon = Icons.account_balance;
                break;
              case 'ewallet':
                icon = Icons.account_balance_wallet;
                break;
              case 'card':
                icon = Icons.credit_card;
                break;
              default:
                icon = Icons.payment;
            }

            return DropdownMenuItem<String>(
              value: method,
              child: Row(
                children: [
                  Icon(icon, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    method == 'cash'
                        ? 'Tunai'
                        : method == 'transfer'
                        ? 'Transfer'
                        : method == 'ewallet'
                        ? 'E-Wallet'
                        : method == 'card'
                        ? 'Kartu'
                        : method.substring(0, 1).toUpperCase() +
                            method.substring(1),
                  ),
                ],
              ),
            );
          }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedPaymentMethod = value!;
        });
      },
    );
  }

  Widget _buildServicesSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected services list
            if (_selectedServices.isNotEmpty) ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedServices.length,
                itemBuilder: (context, index) {
                  final item = _selectedServices[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Rp${item.price} × ${item.quantity} = Rp${item.price * item.quantity}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed:
                                  () => _updateServiceQuantity(
                                    index,
                                    item.quantity - 1,
                                  ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              onPressed:
                                  () => _updateServiceQuantity(
                                    index,
                                    item.quantity + 1,
                                  ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () => _removeService(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(),
            ],

            // Add service button
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<Service>(
                hint: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Tambah Layanan'),
                ),
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(Icons.add_circle),
                ),
                items:
                    _services.map((service) {
                      return DropdownMenuItem<Service>(
                        value: service,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('${service.name} - Rp${service.price}'),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _addService(value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected products list
            if (_selectedProducts.isNotEmpty) ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedProducts.length,
                itemBuilder: (context, index) {
                  final item = _selectedProducts[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Rp${item.price} × ${item.quantity} = Rp${item.price * item.quantity}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed:
                                  () => _updateProductQuantity(
                                    index,
                                    item.quantity - 1,
                                  ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              onPressed:
                                  () => _updateProductQuantity(
                                    index,
                                    item.quantity + 1,
                                  ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () => _removeProduct(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(),
            ],

            // Add product button
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<Product>(
                hint: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Tambah Produk'),
                ),
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(Icons.add_circle),
                ),
                items:
                    _products.map((product) {
                      return DropdownMenuItem<Product>(
                        value: product,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '${product.name} - Rp${product.price} (Stock: ${product.stock})',
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    if (value.stock > 0) {
                      _addProduct(value);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${value.name} stok habis'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection(NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  currencyFormat.format(_total),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed:
                _isLoading || _selectedServices.isEmpty
                    ? null
                    : _saveTransaction,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text('Simpan Transaksi'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    final labels = ['Pelanggan', 'Layanan', 'Pembayaran'];
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.blue.shade700 : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          labels[step - 1],
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Container(
      width: 30,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final map = {
      'Customer Information': 'Informasi Pelanggan',
      'Services': 'Layanan',
      'Products (Optional)': 'Produk (Opsional)',
      'Payment Details': 'Detail Pembayaran',
    };
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          map[title] ?? title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
      ],
    );
  }
}

class TransactionItem {
  final int id;
  final String name;
  final int price;
  int quantity;

  TransactionItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });
}
