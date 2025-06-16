import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../models/transaction_detail.dart';
import '../../repositories/transaction_repository.dart';
import '../../screens/transactions/transaction_receipt_screen.dart';
import 'package:provider/provider.dart';
import '../../repositories/finance_transaction_repository.dart';
import '../../repositories/finance_category_repository.dart';
import '../../providers/auth_provider.dart';
import '../../models/finance_transaction.dart';

class TransactionDetailScreen extends StatefulWidget {
  final int transactionId;

  const TransactionDetailScreen({Key? key, required this.transactionId})
    : super(key: key);

  @override
  _TransactionDetailScreenState createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final TransactionRepository _transactionRepository = TransactionRepository();
  final FinanceTransactionRepository _financeTransactionRepository =
      FinanceTransactionRepository();
  final FinanceCategoryRepository _financeCategoryRepository =
      FinanceCategoryRepository();
  Transaction? _transaction;
  List<TransactionDetail> _details = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  Future<void> _loadTransaction() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transaction = await _transactionRepository.getTransactionById(
        widget.transactionId,
      );
      final details = await _transactionRepository.getTransactionDetails(
        widget.transactionId,
      );

      setState(() {
        _transaction = transaction;
        _details = details;
        _isLoading = false;
      });
      if (transaction != null) {
        await _insertFinanceIncomeIfNeeded(transaction);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load transaction details');
    }
  }

  Future<void> _insertFinanceIncomeIfNeeded(Transaction transaction) async {
    // Cek apakah sudah pernah insert transaksi untuk transaksi ini (berdasarkan referenceId = 'transaction-<id>')
    final existingTransactions =
        await _financeTransactionRepository.getAllTransactions();
    final alreadyInserted = existingTransactions.any(
      (t) => t.referenceId == 'transaction-${transaction.id}',
    );
    if (!alreadyInserted) {
      final categories = await _financeCategoryRepository
          .getActiveCategoriesByType('income');
      final serviceCategory = categories.firstWhere(
        (c) => c.name == 'Penjualan Layanan',
        orElse: () => categories.first,
      );
      if (serviceCategory != null) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.currentUser?.id;
        await _financeTransactionRepository.insertTransaction(
          FinanceTransaction(
            date: DateTime.now().toIso8601String().substring(0, 10),
            categoryId: serviceCategory.id!,
            amount: transaction.total,
            description: 'Pendapatan dari transaksi #${transaction.id}',
            paymentMethod: transaction.paymentMethod ?? 'cash',
            referenceId: 'transaction-${transaction.id}',
            userId: userId,
            outletId: transaction.outletId,
          ),
        );
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showReceipt() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                TransactionReceiptScreen(transactionId: widget.transactionId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _transaction == null
              ? const Center(child: Text('Transaction not found'))
              : CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    expandedHeight: 200.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.blue.shade700,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        'Transaction #${_transaction!.id}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.shade800,
                              Colors.blue.shade500,
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -50,
                              top: -50,
                              child: CircleAvatar(
                                radius: 100,
                                backgroundColor: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            Positioned(
                              left: -30,
                              bottom: -30,
                              child: CircleAvatar(
                                radius: 80,
                                backgroundColor: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 40),
                                  Text(
                                    currencyFormat.format(_transaction!.total),
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _transaction!.paymentMethod
                                              ?.toUpperCase() ??
                                          'CASH',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                        ),
                        onPressed: _showReceipt,
                        tooltip: 'Show Receipt',
                      ),
                    ],
                  ),

                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoCard(),
                          const SizedBox(height: 16),
                          _buildCustomerCard(),
                          const SizedBox(height: 16),
                          _buildItemsCard(currencyFormat),
                          const SizedBox(height: 16),
                          if (_transaction!.notes != null &&
                              _transaction!.notes!.isNotEmpty)
                            _buildNotesCard(),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _showReceipt,
                            icon: const Icon(Icons.receipt_long),
                            label: const Text('View Receipt'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildInfoCard() {
    final transactionDate = DateTime.parse(_transaction!.date);
    final formattedDate = DateFormat(
      'EEEE, MMMM d, yyyy',
    ).format(transactionDate);
    final formattedTime = DateFormat('h:mm a').format(transactionDate);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.calendar_today, 'Date', formattedDate),
            _buildDetailRow(Icons.access_time, 'Time', formattedTime),
            if (_transaction!.outletName != null)
              _buildDetailRow(Icons.store, 'Outlet', _transaction!.outletName!),
            if (_transaction!.userName != null)
              _buildDetailRow(Icons.person, 'Cashier', _transaction!.userName!),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(
                    _transaction!.customerName != null
                        ? Icons.person
                        : Icons.person_outline,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _transaction!.customerName ?? 'Walk-in Customer',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(NumberFormat currencyFormat) {
    final serviceItems =
        _details.where((detail) => detail.itemType == 'service').toList();
    final productItems =
        _details.where((detail) => detail.itemType == 'product').toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),

            if (serviceItems.isNotEmpty) ...[
              _buildSectionHeader('Services', Icons.content_cut, Colors.blue),
              const SizedBox(height: 8),
              ...serviceItems.map(
                (item) => _buildItemRow(
                  item.itemName ?? 'Unknown Service',
                  item.quantity,
                  item.price,
                  item.subtotal,
                  currencyFormat,
                  Colors.blue.shade50,
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (productItems.isNotEmpty) ...[
              _buildSectionHeader('Products', Icons.shopping_bag, Colors.green),
              const SizedBox(height: 8),
              ...productItems.map(
                (item) => _buildItemRow(
                  item.itemName ?? 'Unknown Product',
                  item.quantity,
                  item.price,
                  item.subtotal,
                  currencyFormat,
                  Colors.green.shade50,
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  currencyFormat.format(_transaction!.total),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(_transaction!.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text('$label:', style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(
    String name,
    int quantity,
    int price,
    int subtotal,
    NumberFormat currencyFormat,
    Color backgroundColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '${currencyFormat.format(price)} × $quantity',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Text(
            currencyFormat.format(subtotal),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
