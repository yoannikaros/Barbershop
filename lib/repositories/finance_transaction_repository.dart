import '../models/finance_transaction.dart';
import '../utils/database_helper.dart';

class FinanceTransactionRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertTransaction(FinanceTransaction transaction) async {
    return await dbHelper.insert('finance_transactions', transaction.toMap());
  }

  Future<List<FinanceTransaction>> getAllTransactions() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        ft.*,
        fc.name as category_name,
        fc.type as category_type,
        u.username as user_name,
        o.name as outlet_name
      FROM finance_transactions ft
      LEFT JOIN finance_categories fc ON ft.category_id = fc.id
      LEFT JOIN users u ON ft.user_id = u.id
      LEFT JOIN outlets o ON ft.outlet_id = o.id
      ORDER BY ft.date DESC
    ''');

    return List.generate(maps.length, (i) {
      return FinanceTransaction.fromMap(maps[i]);
    });
  }

  Future<List<FinanceTransaction>> getTransactionsByType(String type) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        ft.*,
        fc.name as category_name,
        fc.type as category_type,
        u.username as user_name,
        o.name as outlet_name
      FROM finance_transactions ft
      LEFT JOIN finance_categories fc ON ft.category_id = fc.id
      LEFT JOIN users u ON ft.user_id = u.id
      LEFT JOIN outlets o ON ft.outlet_id = o.id
      WHERE fc.type = ?
      ORDER BY ft.date DESC
    ''', [type]);

    return List.generate(maps.length, (i) {
      return FinanceTransaction.fromMap(maps[i]);
    });
  }

  Future<List<FinanceTransaction>> getTransactionsByDateRange(String startDate, String endDate) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        ft.*,
        fc.name as category_name,
        fc.type as category_type,
        u.username as user_name,
        o.name as outlet_name
      FROM finance_transactions ft
      LEFT JOIN finance_categories fc ON ft.category_id = fc.id
      LEFT JOIN users u ON ft.user_id = u.id
      LEFT JOIN outlets o ON ft.outlet_id = o.id
      WHERE ft.date BETWEEN ? AND ?
      ORDER BY ft.date DESC
    ''', [startDate, endDate]);

    return List.generate(maps.length, (i) {
      return FinanceTransaction.fromMap(maps[i]);
    });
  }

  Future<FinanceTransaction?> getTransactionById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        ft.*,
        fc.name as category_name,
        fc.type as category_type,
        u.username as user_name,
        o.name as outlet_name
      FROM finance_transactions ft
      LEFT JOIN finance_categories fc ON ft.category_id = fc.id
      LEFT JOIN users u ON ft.user_id = u.id
      LEFT JOIN outlets o ON ft.outlet_id = o.id
      WHERE ft.id = ?
    ''', [id]);

    if (maps.isNotEmpty) {
      return FinanceTransaction.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTransaction(FinanceTransaction transaction) async {
    return await dbHelper.update(
      'finance_transactions',
      transaction.toMap(),
      'id = ?',
      [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    return await dbHelper.delete('finance_transactions', 'id = ?', [id]);
  }

  Future<Map<String, int>> getSummary(String startDate, String endDate) async {
    final db = await dbHelper.database;
    
    // Get total income
    final incomeResult = await db.rawQuery('''
      SELECT SUM(ft.amount) as total
      FROM finance_transactions ft
      LEFT JOIN finance_categories fc ON ft.category_id = fc.id
      WHERE fc.type = 'income' AND ft.date BETWEEN ? AND ?
    ''', [startDate, endDate]);
    
    // Get total expense
    final expenseResult = await db.rawQuery('''
      SELECT SUM(ft.amount) as total
      FROM finance_transactions ft
      LEFT JOIN finance_categories fc ON ft.category_id = fc.id
      WHERE fc.type = 'expense' AND ft.date BETWEEN ? AND ?
    ''', [startDate, endDate]);
    
    final int totalIncome = incomeResult.first['total'] as int? ?? 0;
    final int totalExpense = expenseResult.first['total'] as int? ?? 0;
    
    return {
      'income': totalIncome,
      'expense': totalExpense,
      'profit': totalIncome - totalExpense,
    };
  }

  Future<List<Map<String, dynamic>>> getCategorySummary(String type, String startDate, String endDate) async {
    final db = await dbHelper.database;
    
    final result = await db.rawQuery('''
      SELECT 
        fc.id,
        fc.name,
        SUM(ft.amount) as total
      FROM finance_transactions ft
      LEFT JOIN finance_categories fc ON ft.category_id = fc.id
      WHERE fc.type = ? AND ft.date BETWEEN ? AND ?
      GROUP BY fc.id
      ORDER BY total DESC
    ''', [type, startDate, endDate]);
    
    return result;
  }
}
