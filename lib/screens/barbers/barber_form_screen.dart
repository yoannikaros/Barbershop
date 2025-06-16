import 'package:flutter/material.dart';
import '../../models/barber.dart';
import '../../repositories/barber_repository.dart';

class BarberFormScreen extends StatefulWidget {
  final Barber? barber;

  const BarberFormScreen({Key? key, this.barber}) : super(key: key);

  @override
  _BarberFormScreenState createState() => _BarberFormScreenState();
}

class _BarberFormScreenState extends State<BarberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _photoController = TextEditingController();
  final _bioController = TextEditingController();
  final BarberRepository _barberRepository = BarberRepository();
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.barber != null) {
      _nameController.text = widget.barber!.name;
      _photoController.text = widget.barber!.photo ?? '';
      _bioController.text = widget.barber!.bio ?? '';
      _isActive = widget.barber!.isActive == 1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _photoController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveBarber() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final barber = Barber(
          id: widget.barber?.id,
          name: _nameController.text,
          photo: _photoController.text.isEmpty ? null : _photoController.text,
          bio: _bioController.text.isEmpty ? null : _bioController.text,
          isActive: _isActive ? 1 : 0,
        );

        if (widget.barber == null) {
          await _barberRepository.insertBarber(barber);
        } else {
          await _barberRepository.updateBarber(barber);
        }

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.barber == null
                    ? 'Barber berhasil ditambahkan'
                    : 'Barber berhasil diperbarui',
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
                widget.barber == null
                    ? 'Gagal menambahkan barber'
                    : 'Gagal memperbarui barber',
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
        title: Text(widget.barber == null ? 'Tambah Barber' : 'Edit Barber'),
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
                    return 'Silakan masukkan nama barber';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio (opsional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Aktif'),
                subtitle: const Text('Barber tidak aktif tidak tersedia untuk booking'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveBarber,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        widget.barber == null ? 'Tambah Barber' : 'Perbarui Barber',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
