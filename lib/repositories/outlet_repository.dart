import '../models/outlet.dart';
import '../utils/database_helper.dart';

class OutletRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertOutlet(Outlet outlet) async {
    return await dbHelper.insert('outlets', outlet.toMap());
  }

  Future<List<Outlet>> getAllOutlets() async {
    final rows = await dbHelper.queryAllRows('outlets');
    return rows.map((row) => Outlet.fromMap(row)).toList();
  }

  Future<Outlet?> getOutletById(int id) async {
    final rows = await dbHelper.queryWhere('outlets', 'id = ?', [id]);
    return rows.isNotEmpty ? Outlet.fromMap(rows.first) : null;
  }

  Future<int> updateOutlet(Outlet outlet) async {
    return await dbHelper.update(
      'outlets',
      outlet.toMap(),
      'id = ?',
      [outlet.id],
    );
  }

  Future<int> deleteOutlet(int id) async {
    return await dbHelper.delete('outlets', 'id = ?', [id]);
  }
}
