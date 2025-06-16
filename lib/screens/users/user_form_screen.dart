import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/outlet_repository.dart';
import '../../models/outlet.dart';

class UserFormScreen extends StatefulWidget {
  final User? user;

  const UserFormScreen({Key? key, this.user}) : super(key: key);

  @override
  _UserFormScreenState createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final UserRepository _userRepository = UserRepository();
  final OutletRepository _outletRepository = OutletRepository();
  bool _isActive = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'admin';
  int? _selectedOutletId;
  List<Outlet> _outlets = [];

  @override
  void initState() {
    super.initState();
    _loadOutlets();
    if (widget.user != null) {
      _usernameController.text = widget.user!.username;
      _passwordController.text = widget.user!.password;
      _fullNameController.text = widget.user!.fullName ?? '';
      _selectedRole = widget.user!.role;
      _selectedOutletId = widget.user!.outletId;
      _isActive = widget.user!.isActive == 1;
    }
  }

  Future<void> _loadOutlets() async {
    try {
      final outlets = await _outletRepository.getAllOutlets();
      setState(() {
        _outlets = outlets;
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = User(
          id: widget.user?.id,
          username: _usernameController.text,
          password: _passwordController.text,
          fullName: _fullNameController.text.isEmpty ? null : _fullNameController.text,
          role: _selectedRole,
          outletId: _selectedOutletId,
          isActive: _isActive ? 1 : 0,
        );

        if (widget.user == null) {
          await _userRepository.insertUser(user);
        } else {
          await _userRepository.updateUser(user);
        }

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.user == null
                    ? 'Pengguna berhasil ditambahkan'
                    : 'Pengguna berhasil diperbarui',
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
                widget.user == null
                    ? 'Gagal menambahkan pengguna'
                    : 'Gagal memperbarui pengguna',
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
        title: Text(widget.user == null ? 'Tambah Pengguna' : 'Edit Pengguna'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Pengguna',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Silakan masukkan nama pengguna';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Silakan masukkan kata sandi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Peran',
                  border: OutlineInputBorder(),
                ),
                value: _selectedRole,
                items: const [
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Admin'),
                  ),
                  DropdownMenuItem(
                    value: 'kasir',
                    child: Text('Kasir'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                decoration: const InputDecoration(
                  labelText: 'Outlet',
                  border: OutlineInputBorder(),
                ),
                value: _selectedOutletId,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('No Outlet'),
                  ),
                  ..._outlets.map((outlet) {
                    return DropdownMenuItem(
                      value: outlet.id,
                      child: Text(outlet.name),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedOutletId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                subtitle: const Text('Inactive users cannot log in'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveUser,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        widget.user == null ? 'Add User' : 'Update User',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
