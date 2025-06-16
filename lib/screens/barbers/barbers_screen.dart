import 'package:flutter/material.dart';
import '../../models/barber.dart';
import '../../repositories/barber_repository.dart';
import '../../screens/barbers/barber_form_screen.dart';

class BarbersScreen extends StatefulWidget {
  const BarbersScreen({Key? key}) : super(key: key);

  @override
  _BarbersScreenState createState() => _BarbersScreenState();
}

class _BarbersScreenState extends State<BarbersScreen> {
  final BarberRepository _barberRepository = BarberRepository();
  List<Barber> _barbers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBarbers();
  }

  Future<void> _loadBarbers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final barbers = await _barberRepository.getAllBarbers();
      setState(() {
        _barbers = barbers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load barbers');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _deleteBarber(Barber barber) async {
    try {
      await _barberRepository.deleteBarber(barber.id!);
      _loadBarbers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barber deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to delete barber');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barbers'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _barbers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_off,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No barbers found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BarberFormScreen(),
                            ),
                          );
                          _loadBarbers();
                        },
                        child: const Text('Add Barber'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _barbers.length,
                  itemBuilder: (context, index) {
                    final barber = _barbers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: barber.photo != null
                              ? NetworkImage(barber.photo!)
                              : null,
                          child: barber.photo == null
                              ? Text(barber.name[0].toUpperCase())
                              : null,
                        ),
                        title: Text(
                          barber.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: barber.isActive == 1 ? null : Colors.grey,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (barber.bio != null && barber.bio!.isNotEmpty)
                              Text(barber.bio!),
                            Text(
                              barber.isActive == 1 ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: barber.isActive == 1 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: barber.isActive == 1,
                              onChanged: (value) async {
                                final updatedBarber = barber.copyWith(
                                  isActive: value ? 1 : 0,
                                );
                                await _barberRepository.updateBarber(updatedBarber);
                                _loadBarbers();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BarberFormScreen(barber: barber),
                                  ),
                                );
                                _loadBarbers();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Barber'),
                                    content: Text(
                                      'Are you sure you want to delete ${barber.name}?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteBarber(barber);
                                        },
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BarberFormScreen(),
            ),
          );
          _loadBarbers();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
