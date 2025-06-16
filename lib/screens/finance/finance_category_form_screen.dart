import 'package:flutter/material.dart';
import '../../models/finance_category.dart';
import '../../repositories/finance_category_repository.dart';

class FinanceCategoryFormScreen extends StatefulWidget {
  final String type; // 'income' atau 'expense'
  final FinanceCategory? category;

  const FinanceCategoryFormScreen({
    Key? key,
    required this.type,
    this.category,
  }) : super(key: key);

  @override
  _FinanceCategoryFormScreenState createState() => _FinanceCategoryFormScreenState();
}

class _FinanceCategoryFormScreenState extends State<FinanceCategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FinanceCategoryRepository _categoryRepository = FinanceCategoryRepository();
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description ?? '';
      _isActive = widget.category!.isActive == 1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final category = FinanceCategory(
          id: widget.category?.id,
          name: _nameController.text,
          type: widget.type,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          isActive: _isActive ? 1 : 0,
        );

        if (widget.category == null) {
          await _categoryRepository.insertCategory(category);
        } else {
          await _categoryRepository.updateCategory(category);
        }

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.category == null
                    ? 'Kategori berhasil ditambahkan'
                    : 'Kategori berhasil diperbarui',
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
        ? (widget.category == null ? 'Tambah Kategori Pemasukan' : 'Edit Kategori Pemasukan')
        : (widget.category == null ? 'Tambah Kategori Pengeluaran' : 'Edit Kategori Pengeluaran');

    final Color themeColor = widget.type == 'income' ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Kategori',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Silakan masukkan nama kategori';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Aktif'),
              subtitle: const Text('Kategori tidak aktif tidak akan muncul saat membuat transaksi'),
              value: _isActive,
              activeColor: themeColor,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveCategory,
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
                      widget.category == null ? 'Simpan' : 'Perbarui',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
