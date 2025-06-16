import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking.dart';
import '../../models/customer.dart';
import '../../models/barber.dart';
import '../../models/service.dart';
import '../../models/outlet.dart';
import '../../repositories/booking_repository.dart';
import '../../repositories/customer_repository.dart';
import '../../repositories/barber_repository.dart';
import '../../repositories/service_repository.dart';
import '../../repositories/outlet_repository.dart';
import 'package:provider/provider.dart';
import '../../repositories/finance_transaction_repository.dart';
import '../../repositories/finance_category_repository.dart';
import '../../providers/auth_provider.dart';
import '../../models/finance_transaction.dart';

class BookingFormScreen extends StatefulWidget {
  final Booking? booking;

  const BookingFormScreen({Key? key, this.booking}) : super(key: key);

  @override
  _BookingFormScreenState createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  final BookingRepository _bookingRepository = BookingRepository();
  final CustomerRepository _customerRepository = CustomerRepository();
  final BarberRepository _barberRepository = BarberRepository();
  final ServiceRepository _serviceRepository = ServiceRepository();
  final OutletRepository _outletRepository = OutletRepository();
  final FinanceTransactionRepository _financeTransactionRepository =
      FinanceTransactionRepository();
  final FinanceCategoryRepository _financeCategoryRepository =
      FinanceCategoryRepository();

  bool _isLoading = false;
  bool _isInitializing = true;

  List<Customer> _customers = [];
  List<Barber> _barbers = [];
  List<Service> _services = [];
  List<Outlet> _outlets = [];

  Customer? _selectedCustomer;
  Barber? _selectedBarber;
  Service? _selectedService;
  Outlet? _selectedOutlet;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedStatus = 'pending';

  final List<String> _statusOptions = [
    'pending',
    'confirmed',
    'completed',
    'canceled',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      final customers = await _customerRepository.getAllCustomers();
      final barbers = await _barberRepository.getActiveBarbers();
      final services = await _serviceRepository.getActiveServices();
      final outlets = await _outletRepository.getAllOutlets();

      setState(() {
        _customers = customers;
        _barbers = barbers;
        _services = services;
        _outlets = outlets;
      });

      if (widget.booking != null) {
        _notesController.text = widget.booking!.notes ?? '';
        _selectedStatus = widget.booking!.status;

        final scheduledDateTime = DateTime.parse(widget.booking!.scheduledAt);
        _selectedDate = scheduledDateTime;
        _selectedTime = TimeOfDay(
          hour: scheduledDateTime.hour,
          minute: scheduledDateTime.minute,
        );

        // Find and set selected entities
        for (var customer in _customers) {
          if (customer.id == widget.booking!.customerId) {
            _selectedCustomer = customer;
            break;
          }
        }

        for (var barber in _barbers) {
          if (barber.id == widget.booking!.barberId) {
            _selectedBarber = barber;
            break;
          }
        }

        for (var service in _services) {
          if (service.id == widget.booking!.serviceId) {
            _selectedService = service;
            break;
          }
        }

        if (widget.booking!.outletId != null) {
          for (var outlet in _outlets) {
            if (outlet.id == widget.booking!.outletId) {
              _selectedOutlet = outlet;
              break;
            }
          }
        }

        // If we couldn't find the entities, set defaults
        if (_selectedCustomer == null && _customers.isNotEmpty) {
          _selectedCustomer = _customers.first;
        }

        if (_selectedBarber == null && _barbers.isNotEmpty) {
          _selectedBarber = _barbers.first;
        }

        if (_selectedService == null && _services.isNotEmpty) {
          _selectedService = _services.first;
        }
      } else {
        // Set defaults for new booking
        if (_customers.isNotEmpty) _selectedCustomer = _customers.first;
        if (_barbers.isNotEmpty) _selectedBarber = _barbers.first;
        if (_services.isNotEmpty) _selectedService = _services.first;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveBooking() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCustomer == null ||
          _selectedBarber == null ||
          _selectedService == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select customer, barber and service'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final scheduledDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        final booking = Booking(
          id: widget.booking?.id,
          customerId: _selectedCustomer!.id!,
          barberId: _selectedBarber!.id!,
          serviceId: _selectedService!.id!,
          outletId: _selectedOutlet?.id,
          scheduledAt: scheduledDateTime.toIso8601String(),
          status: _selectedStatus,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

        if (widget.booking == null) {
          final bookingId = await _bookingRepository.insertBooking(booking);
          // Insert pemasukan keuangan otomatis untuk setiap booking baru
          final existingTransactions =
              await _financeTransactionRepository.getAllTransactions();
          final alreadyInserted = existingTransactions.any(
            (t) => t.referenceId == 'booking-$bookingId',
          );
          if (!alreadyInserted) {
            final categories = await _financeCategoryRepository
                .getActiveCategoriesByType('income');
            final serviceCategory = categories.firstWhere(
              (c) => c.name == 'Penjualan Stok',
              orElse: () => categories.first,
            );
            if (serviceCategory != null) {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final userId = authProvider.currentUser?.id;
              await _financeTransactionRepository.insertTransaction(
                FinanceTransaction(
                  date: DateTime.now().toIso8601String().substring(0, 10),
                  categoryId: serviceCategory.id!,
                  amount: _selectedService!.price,
                  description: 'Pendapatan dari booking #$bookingId',
                  paymentMethod: 'cash',
                  referenceId: 'booking-$bookingId',
                  userId: userId,
                  outletId: _selectedOutlet?.id,
                ),
              );
            }
          }
        } else {
          await _bookingRepository.updateBooking(booking);
        }

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.booking == null
                    ? 'Booking berhasil dibuat'
                    : 'Booking berhasil diperbarui',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Terjadi kesalahan: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.booking == null ? 'Buat Booking' : 'Edit Booking'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body:
          _isInitializing
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer section
                      _buildSectionHeader('Informasi Pelanggan', Icons.person),
                      const SizedBox(height: 16),
                      _buildCustomerDropdown(),
                      const SizedBox(height: 16),
                      _buildOutletDropdown(),
                      const SizedBox(height: 24),

                      // Service section
                      _buildSectionHeader(
                        'Informasi Layanan',
                        Icons.content_cut,
                      ),
                      const SizedBox(height: 16),
                      _buildServiceDropdown(),
                      const SizedBox(height: 16),
                      _buildBarberDropdown(),
                      const SizedBox(height: 24),

                      // Schedule section
                      _buildSectionHeader(
                        'Informasi Jadwal',
                        Icons.calendar_today,
                      ),
                      const SizedBox(height: 16),
                      _buildDateTimePickers(),
                      const SizedBox(height: 16),
                      if (widget.booking != null) ...[
                        _buildStatusDropdown(),
                        const SizedBox(height: 16),
                      ],

                      // Notes section
                      _buildSectionHeader('Informasi Tambahan', Icons.note),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Catatan',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveBooking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  )
                                  : Text(
                                    widget.booking == null
                                        ? 'Buat Booking'
                                        : 'Perbarui Booking',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerDropdown() {
    return DropdownButtonFormField<Customer>(
      decoration: InputDecoration(
        labelText: 'Pelanggan',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.person),
      ),
      value: _selectedCustomer,
      items:
          _customers.map((customer) {
            return DropdownMenuItem<Customer>(
              value: customer,
              child: Text(customer.name),
            );
          }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCustomer = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Silakan pilih pelanggan';
        }
        return null;
      },
    );
  }

  Widget _buildBarberDropdown() {
    return DropdownButtonFormField<Barber>(
      decoration: InputDecoration(
        labelText: 'Barber',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.person),
      ),
      value: _selectedBarber,
      items:
          _barbers.map((barber) {
            return DropdownMenuItem<Barber>(
              value: barber,
              child: Text(barber.name),
            );
          }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedBarber = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Silakan pilih barber';
        }
        return null;
      },
    );
  }

  Widget _buildServiceDropdown() {
    return DropdownButtonFormField<Service>(
      decoration: InputDecoration(
        labelText: 'Layanan',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.content_cut),
      ),
      value: _selectedService,
      items:
          _services.map((service) {
            return DropdownMenuItem<Service>(
              value: service,
              child: Text(
                '${service.name} - Rp${service.price} (${service.durationMinutes} menit)',
              ),
            );
          }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedService = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Silakan pilih layanan';
        }
        return null;
      },
    );
  }

  Widget _buildOutletDropdown() {
    return DropdownButtonFormField<Outlet?>(
      decoration: InputDecoration(
        labelText: 'Outlet (Opsional)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.store),
      ),
      value: _selectedOutlet,
      items: [
        const DropdownMenuItem<Outlet?>(
          value: null,
          child: Text('Tanpa Outlet'),
        ),
        ..._outlets.map((outlet) {
          return DropdownMenuItem<Outlet>(
            value: outlet,
            child: Text(outlet.name),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _selectedOutlet = value;
        });
      },
    );
  }

  Widget _buildDateTimePickers() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Tanggal',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.calendar_today),
              ),
              child: Text(DateFormat('EEE, MMM d, yyyy').format(_selectedDate)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () => _selectTime(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Waktu',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.access_time),
              ),
              child: Text(_selectedTime.format(context)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.flag),
      ),
      value: _selectedStatus,
      items:
          _statusOptions.map((status) {
            IconData icon;
            Color color;
            String label;
            switch (status) {
              case 'pending':
                icon = Icons.schedule;
                color = Colors.orange;
                label = 'Menunggu';
                break;
              case 'confirmed':
                icon = Icons.check_circle;
                color = Colors.blue;
                label = 'Terkonfirmasi';
                break;
              case 'completed':
                icon = Icons.done_all;
                color = Colors.green;
                label = 'Selesai';
                break;
              case 'canceled':
                icon = Icons.cancel;
                color = Colors.red;
                label = 'Dibatalkan';
                break;
              default:
                icon = Icons.help;
                color = Colors.grey;
                label = status;
            }
            return DropdownMenuItem<String>(
              value: status,
              child: Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              ),
            );
          }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedStatus = value!;
        });
      },
    );
  }
}
