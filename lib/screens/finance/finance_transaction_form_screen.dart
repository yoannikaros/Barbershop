import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/finance_transaction.dart';
import '../../models/finance_category.dart';
import '../../models/outlet.dart';
import '../../repositories/finance_transaction_repository.dart';
import '../../repositories/finance_category_repository.dart';
import '../../repositories/outlet_repository.dart';
import '../../providers/auth_provider.dart';
import '../../screens/finance/finance_category_form_screen.dart';

class FinanceTransactionFormScreen extends StatefulWidget {
  final String type; // 'income' atau 'expense'
  final FinanceTransaction? transaction;

  const FinanceTransactionFormScreen({
    Key? key,
    required this.type,
    this.transaction,
  }) : super(key: key);

  @override
  _FinanceTransactionFormScreenState createState() => _FinanceTransactionFormScreenState();
}

class _FinanceTransactionFormScreenState extends State<FinanceTransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _referenceIdController = TextEditingController();

  final FinanceTransactionRepository _transactionRepository = FinanceTransactionRepository();
  final FinanceCategoryRepository _categoryRepository = FinanceCategoryRepository();
  final OutletRepository _outletRepository = OutletRepository();

  bool _isLoading = false;
  bool _isInitializing = true;

  List<FinanceCategory> _categories = [];
  List<Outlet> _outlets = [];

  FinanceCategory? _selectedCategory;
  Outlet? _selectedOutlet;
  String _selectedPaymentMethod = 'cash';
  DateTime _selectedDate = DateTime.now();

  final List<String> _paymentMethods = ['cash', 'transfer', 'debit', 'credit'];

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
      final categories = await _categoryRepository.getActiveCategoriesByType(widget.type);
      final outlets = await _outletRepository.getAllOutlets();

      setState(() {
        _categories = categories;
        _outlets = outlets;

        if (widget.transaction != null) {
          _amountController.text = widget.transaction!.amount.toString();
          _descriptionController.text = widget.transaction!.description ?? '';
          _referenceIdController.text = widget.transaction!.referenceId ?? '';
          _selectedPaymentMethod = widget.transaction!.paymentMethod ?? 'cash';
          _selectedDate = DateTime.parse(widget.transaction!.date);

          // Find selected category
          for (var category in categories) {
            if (category.id == widget.transaction!.categoryId) {
              _selectedCategory = category;
              break;
            }
          }

          // Find selected outlet
          if (widget.transaction!.outletId != null) {
            for (var outlet in outlets) {
              if (outlet.id == widget.transaction!.outletId) {
                _selectedOutlet = outlet;
                break;
              }
            }
          }
        }

        // Set defaults if not set and categories exist
        if (_selectedCategory == null && categories.isNotEmpty) {
          _selectedCategory = categories.first;
        }

        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _referenceIdController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan pilih kategori'),
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
        final transaction = FinanceTransaction(
          id: widget.transaction?.id,
          date: DateFormat('yyyy-MM-dd').format(_selectedDate),
          categoryId: _selectedCategory!.id!,
          amount: int.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')),
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          paymentMethod: _selectedPaymentMethod,
          referenceId: _referenceIdController.text.isEmpty ? null : _referenceIdController.text,
          userId: currentUser?.id,
          outletId: _selectedOutlet?.id,
        );

        if (widget.transaction == null) {
          await _transactionRepository.insertTransaction(transaction);
        } else {
          await _transactionRepository.updateTransaction(transaction);
        }

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.transaction == null
                    ? 'Transaksi berhasil ditambahkan'
                    : 'Transaksi berhasil diperbarui',
              ),
              backgroundColor: Colors.green,
            ),
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
    final String title = widget.type == 'income'
        ? (widget.transaction == null ? 'Tambah Pemasukan' : 'Edit Pemasukan')
        : (widget.transaction == null ? 'Tambah Pengeluaran' : 'Edit Pengeluaran');

    final Color themeColor = widget.type == 'income' ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada kategori ${widget.type == 'income' ? 'pemasukan' : 'pengeluaran'}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FinanceCategoryFormScreen(
                      type: widget.type,
                    ),
                  ),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.add),
              label: Text(
                'Tambah Kategori ${widget.type == 'income' ? 'Pemasukan' : 'Pengeluaran'}',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      )
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Amount field
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Jumlah',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.attach_money),
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.isEmpty) {
                    return newValue;
                  }
                  final int? value = int.tryParse(newValue.text);
                  if (value == null) {
                    return oldValue;
                  }
                  final formatter = NumberFormat('#,###', 'id');
                  final newText = formatter.format(value);
                  return TextEditingValue(
                    text: newText,
                    selection: TextSelection.collapsed(offset: newText.length),
                  );
                }),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Silakan masukkan jumlah';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category dropdown
            DropdownButtonFormField<FinanceCategory>(
              decoration: InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
              value: _selectedCategory,
              items: _categories.map((category) {
                return DropdownMenuItem<FinanceCategory>(
                  value: category,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Silakan pilih kategori';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date picker
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Tanggal',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('dd MMMM yyyy').format(_selectedDate),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payment method dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Metode Pembayaran',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.payment),
              ),
              value: _selectedPaymentMethod,
              items: _paymentMethods.map((method) {
                String label;
                IconData icon;

                switch (method) {
                  case 'cash':
                    label = 'Tunai';
                    icon = Icons.money;
                    break;
                  case 'transfer':
                    label = 'Transfer Bank';
                    icon = Icons.account_balance;
                    break;
                  case 'debit':
                    label = 'Kartu Debit';
                    icon = Icons.credit_card;
                    break;
                  case 'credit':
                    label = 'Kartu Kredit';
                    icon = Icons.credit_card;
                    break;
                  default:
                    label = method.substring(0, 1).toUpperCase() + method.substring(1);
                    icon = Icons.payment;
                }

                return DropdownMenuItem<String>(
                  value: method,
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Outlet dropdown
            if (_outlets.isNotEmpty)
              DropdownButtonFormField<Outlet?>(
                decoration: InputDecoration(
                  labelText: 'Outlet',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.store),
                ),
                value: _selectedOutlet,
                items: [
                  const DropdownMenuItem<Outlet?>(
                    value: null,
                    child: Text('Tidak Ada Outlet'),
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
              ),
            if (_outlets.isNotEmpty) const SizedBox(height: 16),

            // Reference ID field
            TextFormField(
              controller: _referenceIdController,
              decoration: InputDecoration(
                labelText: 'ID Referensi (Opsional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Deskripsi (Opsional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Submit button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveTransaction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
                  : Text(
                widget.transaction == null ? 'Simpan' : 'Perbarui',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
