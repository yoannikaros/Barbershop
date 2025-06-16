import '../models/user.dart';
import '../utils/database_helper.dart';

class UserRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertUser(User user) async {
    return await dbHelper.insert('users', user.toMap());
  }

  Future<List<User>> getAllUsers() async {
    final rows = await dbHelper.queryAllRows('users');
    return rows.map((row) => User.fromMap(row)).toList();
  }

  Future<User?> getUserById(int id) async {
    final rows = await dbHelper.queryWhere('users', 'id = ?', [id]);
    return rows.isNotEmpty ? User.fromMap(rows.first) : null;
  }

  Future<User?> getUserByUsername(String username) async {
    final rows = await dbHelper.queryWhere('users', 'username = ?', [username]);
    return rows.isNotEmpty ? User.fromMap(rows.first) : null;
  }

  Future<int> updateUser(User user) async {
    return await dbHelper.update(
      'users',
      user.toMap(),
      'id = ?',
      [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    return await dbHelper.delete('users', 'id = ?', [id]);
  }

  Future<int> updateUsername(int id, String username) async {
    return await dbHelper.update(
      'users',
      {'username': username},
      'id = ?',
      [id],
    );
  }

  Future<int> updatePassword(int userId, String newPassword) async {
    return await dbHelper.update(
      'users',
      {'password': newPassword},
      'id = ?',
      [userId],
    );
  }

  Future<int> deleteAccount(int userId) async {
    return await dbHelper.delete('users', 'id = ?', [userId]);
  }
}
