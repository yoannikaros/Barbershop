import '../models/finance_category.dart';
import '../utils/database_helper.dart';

class FinanceCategoryRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertCategory(FinanceCategory category) async {
    return await dbHelper.insert('finance_categories', category.toMap());
  }

  Future<List<FinanceCategory>> getAllCategories() async {
    final rows = await dbHelper.queryAllRows('finance_categories');
    return rows.map((row) => FinanceCategory.fromMap(row)).toList();
  }

  Future<List<FinanceCategory>> getCategoriesByType(String type) async {
    final rows = await dbHelper.queryWhere('finance_categories', 'type = ?', [type]);
    return rows.map((row) => FinanceCategory.fromMap(row)).toList();
  }

  Future<List<FinanceCategory>> getActiveCategories() async {
    final rows = await dbHelper.queryWhere('finance_categories', 'is_active = ?', [1]);
    return rows.map((row) => FinanceCategory.fromMap(row)).toList();
  }

  Future<List<FinanceCategory>> getActiveCategoriesByType(String type) async {
    final rows = await dbHelper.queryWhere(
      'finance_categories', 
      'type = ? AND is_active = ?', 
      [type, 1]
    );
    return rows.map((row) => FinanceCategory.fromMap(row)).toList();
  }

  Future<FinanceCategory?> getCategoryById(int id) async {
    final rows = await dbHelper.queryWhere('finance_categories', 'id = ?', [id]);
    return rows.isNotEmpty ? FinanceCategory.fromMap(rows.first) : null;
  }

  Future<int> updateCategory(FinanceCategory category) async {
    return await dbHelper.update(
      'finance_categories',
      category.toMap(),
      'id = ?',
      [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    return await dbHelper.delete('finance_categories', 'id = ?', [id]);
  }
}
