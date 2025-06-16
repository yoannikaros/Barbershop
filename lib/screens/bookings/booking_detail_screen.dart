import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking.dart';
import '../../repositories/booking_repository.dart';
import '../../screens/bookings/booking_form_screen.dart';
import 'package:provider/provider.dart';
import '../../repositories/finance_transaction_repository.dart';
import '../../repositories/finance_category_repository.dart';
import '../../repositories/service_repository.dart';
import '../../providers/auth_provider.dart';
import '../../models/finance_transaction.dart';

class BookingDetailScreen extends StatefulWidget {
  final int bookingId;

  const BookingDetailScreen({Key? key, required this.bookingId})
    : super(key: key);

  @override
  _BookingDetailScreenState createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final BookingRepository _bookingRepository = BookingRepository();
  final FinanceTransactionRepository _financeTransactionRepository =
      FinanceTransactionRepository();
  final FinanceCategoryRepository _financeCategoryRepository =
      FinanceCategoryRepository();
  final ServiceRepository _serviceRepository = ServiceRepository();
  Booking? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final booking = await _bookingRepository.getBookingById(widget.bookingId);
      setState(() {
        _booking = booking;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load booking details');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _updateBookingStatus(String newStatus) async {
    try {
      await _bookingRepository.updateBookingStatus(_booking!.id!, newStatus);
      if (newStatus == 'completed') {
        final existingTransactions =
            await _financeTransactionRepository.getAllTransactions();
        final alreadyInserted = existingTransactions.any(
          (t) => t.referenceId == 'booking-${_booking!.id}',
        );
        if (!alreadyInserted) {
          final categories = await _financeCategoryRepository
              .getActiveCategoriesByType('income');
          final serviceCategory = categories.firstWhere(
            (c) => c.name == 'Penjualan Layanan',
            orElse: () => categories.first,
          );
          if (serviceCategory != null) {
            final service = await _serviceRepository.getServiceById(
              _booking!.serviceId,
            );
            if (service != null) {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final userId = authProvider.currentUser?.id;
              await _financeTransactionRepository.insertTransaction(
                FinanceTransaction(
                  date: DateTime.now().toIso8601String().substring(0, 10),
                  categoryId: serviceCategory.id!,
                  amount: service.price,
                  description: 'Pendapatan dari booking #${_booking!.id}',
                  paymentMethod: 'cash',
                  referenceId: 'booking-${_booking!.id}',
                  userId: userId,
                  outletId: _booking!.outletId,
                ),
              );
            }
          }
        }
      }
      _loadBooking();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to update booking status');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking #${_booking?.id ?? ''}'),
        backgroundColor:
            _booking != null
                ? _getStatusColor(_booking!.status)
                : Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_booking != null &&
              _booking!.status != 'completed' &&
              _booking!.status != 'canceled')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingFormScreen(booking: _booking),
                  ),
                );
                _loadBooking();
              },
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _booking == null
              ? const Center(child: Text('Booking not found'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 16),
                    _buildDateTimeCard(),
                    const SizedBox(height: 16),
                    _buildCustomerCard(),
                    const SizedBox(height: 16),
                    _buildServiceCard(),
                    const SizedBox(height: 16),
                    if (_booking!.outletName != null) ...[
                      _buildOutletCard(),
                      const SizedBox(height: 16),
                    ],
                    if (_booking!.notes != null &&
                        _booking!.notes!.isNotEmpty) ...[
                      _buildNotesCard(),
                      const SizedBox(height: 16),
                    ],
                    _buildStatusActions(),
                  ],
                ),
              ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'canceled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(_booking!.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getStatusIcon(_booking!.status),
                color: _getStatusColor(_booking!.status),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    _booking!.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(_booking!.status),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeCard() {
    final scheduledDateTime = DateTime.parse(_booking!.scheduledAt);
    final formattedDate = DateFormat(
      'EEEE, MMMM d, yyyy',
    ).format(scheduledDateTime);
    final formattedTime = DateFormat('h:mm a').format(scheduledDateTime);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Date & Time',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.calendar_today,
                    'Date',
                    formattedDate,
                    Colors.blue.shade100,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    Icons.access_time,
                    'Time',
                    formattedTime,
                    Colors.orange.shade100,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Customer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  radius: 24,
                  child: Text(
                    _booking!.customerName != null &&
                            _booking!.customerName!.isNotEmpty
                        ? _booking!.customerName![0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _booking!.customerName ?? 'Unknown Customer',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.content_cut, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Service',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.content_cut, color: Colors.purple.shade700),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _booking!.serviceName ?? 'Unknown Service',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _booking!.barberName ?? 'Unknown Barber',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutletCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Outlet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.store, color: Colors.indigo.shade700),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _booking!.outletName!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Notes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(_booking!.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusActions() {
    if (_booking!.status == 'completed' || _booking!.status == 'canceled') {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.update, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Update Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (_booking!.status == 'pending') ...[
                  _buildStatusButton(
                    'Confirm',
                    Icons.check_circle,
                    Colors.blue,
                    () => _updateBookingStatus('confirmed'),
                  ),
                  _buildStatusButton(
                    'Cancel',
                    Icons.cancel,
                    Colors.red,
                    () => _updateBookingStatus('canceled'),
                  ),
                ] else if (_booking!.status == 'confirmed') ...[
                  _buildStatusButton(
                    'Complete',
                    Icons.done_all,
                    Colors.green,
                    () => _updateBookingStatus('completed'),
                  ),
                  _buildStatusButton(
                    'Cancel',
                    Icons.cancel,
                    Colors.red,
                    () => _updateBookingStatus('canceled'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
