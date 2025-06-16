import '../models/service.dart';
import '../utils/database_helper.dart';

class ServiceRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertService(Service service) async {
    return await dbHelper.insert('services', service.toMap());
  }

  Future<List<Service>> getAllServices() async {
    final rows = await dbHelper.queryAllRows('services');
    return rows.map((row) => Service.fromMap(row)).toList();
  }

  Future<List<Service>> getActiveServices() async {
    final rows = await dbHelper.queryWhere('services', 'is_active = ?', [1]);
    return rows.map((row) => Service.fromMap(row)).toList();
  }

  Future<Service?> getServiceById(int id) async {
    final rows = await dbHelper.queryWhere('services', 'id = ?', [id]);
    return rows.isNotEmpty ? Service.fromMap(rows.first) : null;
  }

  Future<int> updateService(Service service) async {
    return await dbHelper.update(
      'services',
      service.toMap(),
      'id = ?',
      [service.id],
    );
  }

  Future<int> deleteService(int id) async {
    return await dbHelper.delete('services', 'id = ?', [id]);
  }
}
