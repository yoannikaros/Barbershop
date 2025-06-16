import '../../models/booking.dart';
import '../../utils/database_helper.dart';

class BookingRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertBooking(Booking booking) async {
    return await dbHelper.insert('bookings', booking.toMap());
  }

  Future<List<Booking>> getAllBookings() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        b.*,
        c.name as customer_name,
        br.name as barber_name,
        s.name as service_name,
        o.name as outlet_name
      FROM bookings b
      LEFT JOIN customers c ON b.customer_id = c.id
      LEFT JOIN barbers br ON b.barber_id = br.id
      LEFT JOIN services s ON b.service_id = s.id
      LEFT JOIN outlets o ON b.outlet_id = o.id
      ORDER BY b.scheduled_at DESC
    ''');

    return List.generate(maps.length, (i) {
      return Booking.fromMap(maps[i]);
    });
  }

  Future<List<Booking>> getBookingsByStatus(String status) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        b.*,
        c.name as customer_name,
        br.name as barber_name,
        s.name as service_name,
        o.name as outlet_name
      FROM bookings b
      LEFT JOIN customers c ON b.customer_id = c.id
      LEFT JOIN barbers br ON b.barber_id = br.id
      LEFT JOIN services s ON b.service_id = s.id
      LEFT JOIN outlets o ON b.outlet_id = o.id
      WHERE b.status = ?
      ORDER BY b.scheduled_at DESC
    ''', [status]);

    return List.generate(maps.length, (i) {
      return Booking.fromMap(maps[i]);
    });
  }

  Future<Booking?> getBookingById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        b.*,
        c.name as customer_name,
        br.name as barber_name,
        s.name as service_name,
        o.name as outlet_name
      FROM bookings b
      LEFT JOIN customers c ON b.customer_id = c.id
      LEFT JOIN barbers br ON b.barber_id = br.id
      LEFT JOIN services s ON b.service_id = s.id
      LEFT JOIN outlets o ON b.outlet_id = o.id
      WHERE b.id = ?
    ''', [id]);

    if (maps.isNotEmpty) {
      return Booking.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateBooking(Booking booking) async {
    return await dbHelper.update(
      'bookings',
      booking.toMap(),
      'id = ?',
      [booking.id],
    );
  }

  Future<int> updateBookingStatus(int id, String status) async {
    final db = await dbHelper.database;
    return await db.update(
      'bookings',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteBooking(int id) async {
    return await dbHelper.delete('bookings', 'id = ?', [id]);
  }
}
