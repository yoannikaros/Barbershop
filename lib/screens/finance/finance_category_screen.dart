import 'package:flutter/material.dart';
import '../../models/finance_category.dart';
import '../../repositories/finance_category_repository.dart';
import '../../screens/finance/finance_category_form_screen.dart';

class FinanceCategoryScreen extends StatefulWidget {
  const FinanceCategoryScreen({Key? key}) : super(key: key);

  @override
  _FinanceCategoryScreenState createState() => _FinanceCategoryScreenState();
}

class _FinanceCategoryScreenState extends State<FinanceCategoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FinanceCategoryRepository _categoryRepository = FinanceCategoryRepository();
  List<FinanceCategory> _incomeCategories = [];
  List<FinanceCategory> _expenseCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final incomeCategories = await _categoryRepository.getCategoriesByType('income');
      final expenseCategories = await _categoryRepository.getCategoriesByType('expense');
      
      setState(() {
        _incomeCategories = incomeCategories;
        _expenseCategories = expenseCategories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Gagal memuat kategori');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori Keuangan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pemasukan'),
            Tab(text: 'Pengeluaran'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Income categories tab
                _buildCategoryList(
                  _incomeCategories,
                  'income',
                  Colors.green,
                ),
                
                // Expense categories tab
                _buildCategoryList(
                  _expenseCategories,
                  'expense',
                  Colors.red,
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FinanceCategoryFormScreen(
                type: _tabController.index == 0 ? 'income' : 'expense',
              ),
            ),
          ).then((_) => _loadCategories());
        },
        child: const Icon(Icons.add),
        tooltip: 'Tambah Kategori',
      ),
    );
  }

  Widget _buildCategoryList(List<FinanceCategory> categories, String type, Color color) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              type == 'income'
                  ? 'Belum ada kategori pemasukan'
                  : 'Belum ada kategori pengeluaran',
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
                      type: type,
                    ),
                  ),
                ).then((_) => _loadCategories());
              },
              icon: const Icon(Icons.add),
              label: Text(
                type == 'income'
                    ? 'Tambah Kategori Pemasukan'
                    : 'Tambah Kategori Pengeluaran',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: type == 'income'
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              child: Icon(
                type == 'income'
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                color: type == 'income'
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            title: Text(
              category.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: category.isActive == 1 ? null : Colors.grey,
              ),
            ),
            subtitle: category.description != null && category.description!.isNotEmpty
                ? Text(category.description!)
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: category.isActive == 1,
                  activeColor: color,
                  onChanged: (value) async {
                    final updatedCategory = category.copyWith(
                      isActive: value ? 1 : 0,
                    );
                    await _categoryRepository.updateCategory(updatedCategory);
                    _loadCategories();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FinanceCategoryFormScreen(
                          type: type,
                          category: category,
                        ),
                      ),
                    ).then((_) => _loadCategories());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Hapus Kategori'),
                        content: Text(
                          'Apakah Anda yakin ingin menghapus kategori "${category.name}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              try {
                                await _categoryRepository.deleteCategory(category.id!);
                                _loadCategories();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Kategori berhasil dihapus'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  _showErrorSnackBar('Gagal menghapus kategori');
                                }
                              }
                            },
                            child: const Text(
                              'Hapus',
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
    );
  }
}
