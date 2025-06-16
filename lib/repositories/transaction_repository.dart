import '../../models/transaction.dart';
import '../../models/transaction_detail.dart';
import '../../utils/database_helper.dart';

class TransactionRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await dbHelper.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> insertTransactionDetail(TransactionDetail detail) async {
    return await dbHelper.insert('transaction_details', detail.toMap());
  }

  Future<List<Transaction>> getAllTransactions() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        t.*,
        c.name as customer_name,
        u.username as user_name,
        o.name as outlet_name,
        p.name as promo_name
      FROM transactions t
      LEFT JOIN customers c ON t.customer_id = c.id
      LEFT JOIN users u ON t.user_id = u.id
      LEFT JOIN outlets o ON t.outlet_id = o.id
      LEFT JOIN promos p ON t.promo_id = p.id
      ORDER BY t.date DESC
    ''');

    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  Future<Transaction?> getTransactionById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        t.*,
        c.name as customer_name,
        u.username as user_name,
        o.name as outlet_name,
        p.name as promo_name
      FROM transactions t
      LEFT JOIN customers c ON t.customer_id = c.id
      LEFT JOIN users u ON t.user_id = u.id
      LEFT JOIN outlets o ON t.outlet_id = o.id
      LEFT JOIN promos p ON t.promo_id = p.id
      WHERE t.id = ?
    ''', [id]);

    if (maps.isNotEmpty) {
      return Transaction.fromMap(maps.first);
    }
    return null;
  }

  Future<List<TransactionDetail>> getTransactionDetails(int transactionId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        td.*,
        CASE 
          WHEN td.item_type = 'service' THEN s.name
          WHEN td.item_type = 'product' THEN p.name
          ELSE NULL
        END as item_name
      FROM transaction_details td
      LEFT JOIN services s ON td.item_type = 'service' AND td.item_id = s.id
      LEFT JOIN products p ON td.item_type = 'product' AND td.item_id = p.id
      WHERE td.transaction_id = ?
    ''', [transactionId]);

    return List.generate(maps.length, (i) {
      return TransactionDetail.fromMap(maps[i]);
    });
  }

  Future<int> updateTransaction(Transaction transaction) async {
    return await dbHelper.update(
      'transactions',
      transaction.toMap(),
      'id = ?',
      [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await dbHelper.database;

    // First delete all transaction details
    await db.delete(
      'transaction_details',
      where: 'transaction_id = ?',
      whereArgs: [id],
    );

    // Then delete the transaction
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
