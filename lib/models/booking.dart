class Booking {
  final int? id;
  final int customerId;
  final int barberId;
  final int serviceId;
  final int? outletId;
  final String scheduledAt;
  final String status;
  final String? notes;

  // For UI display (not stored in database)
  final String? customerName;
  final String? barberName;
  final String? serviceName;
  final String? outletName;

  Booking({
    this.id,
    required this.customerId,
    required this.barberId,
    required this.serviceId,
    this.outletId,
    required this.scheduledAt,
    this.status = 'pending',
    this.notes,
    this.customerName,
    this.barberName,
    this.serviceName,
    this.outletName,
  });

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'],
      customerId: map['customer_id'],
      barberId: map['barber_id'],
      serviceId: map['service_id'],
      outletId: map['outlet_id'],
      scheduledAt: map['scheduled_at'],
      status: map['status'],
      notes: map['notes'],
      customerName: map['customer_name'],
      barberName: map['barber_name'],
      serviceName: map['service_name'],
      outletName: map['outlet_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'barber_id': barberId,
      'service_id': serviceId,
      'outlet_id': outletId,
      'scheduled_at': scheduledAt,
      'status': status,
      'notes': notes,
    };
  }

  Booking copyWith({
    int? id,
    int? customerId,
    int? barberId,
    int? serviceId,
    int? outletId,
    String? scheduledAt,
    String? status,
    String? notes,
    String? customerName,
    String? barberName,
    String? serviceName,
    String? outletName,
  }) {
    return Booking(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      barberId: barberId ?? this.barberId,
      serviceId: serviceId ?? this.serviceId,
      outletId: outletId ?? this.outletId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      customerName: customerName ?? this.customerName,
      barberName: barberName ?? this.barberName,
      serviceName: serviceName ?? this.serviceName,
      outletName: outletName ?? this.outletName,
    );
  }
}
