import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import '../../repositories/customer_repository.dart';

class CustomerFormScreen extends StatefulWidget {
  final Customer? customer;

  const CustomerFormScreen({Key? key, this.customer}) : super(key: key);

  @override
  _CustomerFormScreenState createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _notesController = TextEditingController();
  final _referralCodeController = TextEditingController();
  final _referredByController = TextEditingController();
  final CustomerRepository _customerRepository = CustomerRepository();
  bool _isLoading = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _phoneController.text = widget.customer!.phone ?? '';
      if (widget.customer!.birthDate != null) {
        _birthDateController.text = widget.customer!.birthDate!;
        _selectedDate = DateTime.parse(widget.customer!.birthDate!);
      }
      _notesController.text = widget.customer!.notes ?? '';
      _referralCodeController.text = widget.customer!.referralCode ?? '';
      _referredByController.text = widget.customer!.referredBy ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _notesController.dispose();
    _referralCodeController.dispose();
    _referredByController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      });
    }
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final customer = Customer(
          id: widget.customer?.id,
          name: _nameController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          birthDate: _birthDateController.text.isEmpty ? null : _birthDateController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          points: widget.customer?.points ?? 0,
          referralCode: _referralCodeController.text.isEmpty ? null : _referralCodeController.text,
          referredBy: _referredByController.text.isEmpty ? null : _referredByController.text,
        );

        if (widget.customer == null) {
          await _customerRepository.insertCustomer(customer);
        } else {
          await _customerRepository.updateCustomer(customer);
        }

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.customer == null
                    ? 'Pelanggan berhasil ditambahkan'
                    : 'Pelanggan berhasil diperbarui',
              ),
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
              content: Text(
                widget.customer == null
                    ? 'Gagal menambahkan pelanggan'
                    : 'Gagal memperbarui pelanggan',
              ),
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
        title: Text(widget.customer == null ? 'Tambah Pelanggan' : 'Edit Pelanggan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Silakan masukkan nama pelanggan';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'No. HP',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _birthDateController,
                decoration: InputDecoration(
                  labelText: 'Tanggal Lahir',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _referredByController,
                decoration: const InputDecoration(
                  labelText: 'Direferensikan Oleh',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCustomer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                  widget.customer == null ? 'Tambah Pelanggan' : 'Perbarui Pelanggan',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
