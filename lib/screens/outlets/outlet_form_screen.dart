import 'package:flutter/material.dart';
import '../../models/outlet.dart';
import '../../repositories/outlet_repository.dart';

class OutletFormScreen extends StatefulWidget {
  final Outlet? outlet;

  const OutletFormScreen({Key? key, this.outlet}) : super(key: key);

  @override
  _OutletFormScreenState createState() => _OutletFormScreenState();
}

class _OutletFormScreenState extends State<OutletFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final OutletRepository _outletRepository = OutletRepository();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.outlet != null) {
      _nameController.text = widget.outlet!.name;
      _addressController.text = widget.outlet!.address ?? '';
      _phoneController.text = widget.outlet!.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveOutlet() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final outlet = Outlet(
          id: widget.outlet?.id,
          name: _nameController.text,
          address: _addressController.text.isEmpty ? null : _addressController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        );

        if (widget.outlet == null) {
          await _outletRepository.insertOutlet(outlet);
        } else {
          await _outletRepository.updateOutlet(outlet);
        }

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.outlet == null
                    ? 'Outlet added successfully'
                    : 'Outlet updated successfully',
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
                widget.outlet == null
                    ? 'Failed to add outlet'
                    : 'Failed to update outlet',
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
        title: Text(widget.outlet == null ? 'Add Outlet' : 'Edit Outlet'),
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
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter outlet name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveOutlet,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        widget.outlet == null ? 'Add Outlet' : 'Update Outlet',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
