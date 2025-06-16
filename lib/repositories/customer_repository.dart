import '../models/customer.dart';
import '../utils/database_helper.dart';

class CustomerRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertCustomer(Customer customer) async {
    return await dbHelper.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getAllCustomers() async {
    final rows = await dbHelper.queryAllRows('customers');
    return rows.map((row) => Customer.fromMap(row)).toList();
  }

  Future<Customer?> getCustomerById(int id) async {
    final rows = await dbHelper.queryWhere('customers', 'id = ?', [id]);
    return rows.isNotEmpty ? Customer.fromMap(rows.first) : null;
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final db = await dbHelper.database;
    final rows = await db.query(
      'customers',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return rows.map((row) => Customer.fromMap(row)).toList();
  }

  Future<int> updateCustomer(Customer customer) async {
    return await dbHelper.update(
      'customers',
      customer.toMap(),
      'id = ?',
      [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    return await dbHelper.delete('customers', 'id = ?', [id]);
  }

  Future<int> updateCustomerPoints(int customerId, int points) async {
    final customer = await getCustomerById(customerId);
    if (customer == null) return 0;
    
    final updatedCustomer = customer.copyWith(points: customer.points + points);
    return await updateCustomer(updatedCustomer);
  }
}
