import '../models/barber.dart';
import '../utils/database_helper.dart';

class BarberRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertBarber(Barber barber) async {
    return await dbHelper.insert('barbers', barber.toMap());
  }

  Future<List<Barber>> getAllBarbers() async {
    final rows = await dbHelper.queryAllRows('barbers');
    return rows.map((row) => Barber.fromMap(row)).toList();
  }

  Future<List<Barber>> getActiveBarbers() async {
    final rows = await dbHelper.queryWhere('barbers', 'is_active = ?', [1]);
    return rows.map((row) => Barber.fromMap(row)).toList();
  }

  Future<Barber?> getBarberById(int id) async {
    final rows = await dbHelper.queryWhere('barbers', 'id = ?', [id]);
    return rows.isNotEmpty ? Barber.fromMap(rows.first) : null;
  }

  Future<int> updateBarber(Barber barber) async {
    return await dbHelper.update(
      'barbers',
      barber.toMap(),
      'id = ?',
      [barber.id],
    );
  }

  Future<int> deleteBarber(int id) async {
    return await dbHelper.delete('barbers', 'id = ?', [id]);
  }
}
