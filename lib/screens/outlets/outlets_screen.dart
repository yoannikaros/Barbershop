import 'package:flutter/material.dart';
import '../../models/outlet.dart';
import '../../repositories/outlet_repository.dart';
import '../../screens/outlets/outlet_form_screen.dart';

class OutletsScreen extends StatefulWidget {
  const OutletsScreen({Key? key}) : super(key: key);

  @override
  _OutletsScreenState createState() => _OutletsScreenState();
}

class _OutletsScreenState extends State<OutletsScreen> {
  final OutletRepository _outletRepository = OutletRepository();
  List<Outlet> _outlets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOutlets();
  }

  Future<void> _loadOutlets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final outlets = await _outletRepository.getAllOutlets();
      setState(() {
        _outlets = outlets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load outlets');
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

  Future<void> _deleteOutlet(Outlet outlet) async {
    try {
      await _outletRepository.deleteOutlet(outlet.id!);
      _loadOutlets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Outlet deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to delete outlet');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outlets'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _outlets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.ac_unit_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No outlets found',
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
                              builder: (_) => const OutletFormScreen(),
                            ),
                          );
                          _loadOutlets();
                        },
                        child: const Text('Add Outlet'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _outlets.length,
                  itemBuilder: (context, index) {
                    final outlet = _outlets[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(
                          outlet.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (outlet.address != null && outlet.address!.isNotEmpty)
                              Text('Address: ${outlet.address}'),
                            if (outlet.phone != null && outlet.phone!.isNotEmpty)
                              Text('Phone: ${outlet.phone}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OutletFormScreen(outlet: outlet),
                                  ),
                                );
                                _loadOutlets();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Outlet'),
                                    content: Text(
                                      'Are you sure you want to delete ${outlet.name}?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteOutlet(outlet);
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
              builder: (_) => const OutletFormScreen(),
            ),
          );
          _loadOutlets();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
