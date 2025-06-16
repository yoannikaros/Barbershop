import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import '../../services/printer_service.dart';

class PrinterSelectionScreen extends StatefulWidget {
  const PrinterSelectionScreen({Key? key}) : super(key: key);

  @override
  _PrinterSelectionScreenState createState() => _PrinterSelectionScreenState();
}

class _PrinterSelectionScreenState extends State<PrinterSelectionScreen> {
  final PrinterService _printerService = PrinterService();
  List<PrinterDevice> _devices = [];
  bool _isLoading = false;
  bool _isScanning = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePrinterService();
  }

  Future<void> _initializePrinterService() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _printerService.initialize();
      _startScan();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize printer service: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _devices = [];
    });

    _printerService.discoverPrinters().listen(
          (device) {
        // Check if the device is already in the list to avoid duplicates
        if (!_devices.any((d) => d.address == device.address)) {
          setState(() {
            // Add the new device to the list
            _devices.add(device);
          });
        }
      },
      onDone: () {
        setState(() {
          _isScanning = false;
          _isLoading = false;
        });
      },
      onError: (error) {
        setState(() {
          _errorMessage = 'Error scanning for printers: ${error.toString()}';
          _isScanning = false;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _connectToPrinter(PrinterDevice printer) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bool connected = await _printerService.connectPrinter(printer);

      if (connected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connected to ${printer.name}'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to connect to ${printer.name}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error connecting to printer: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Printer'),
      ),
      body: _isLoading && !_isScanning
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (_isScanning)
            const LinearProgressIndicator(),
          if (_errorMessage != null)
            Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),
          Expanded(
            child: _devices.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.print,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isScanning
                        ? 'Scanning for printers...'
                        : 'No printers found',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_isScanning)
                    ElevatedButton.icon(
                      onPressed: _startScan,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Scan Again'),
                    ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final printer = _devices[index];
                final bool isSelected = _printerService.selectedPrinter?.address == printer.address;

                return ListTile(
                  leading: Icon(
                    Icons.print,
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                  title: Text(printer.name ?? 'Unknown Printer'),
                  subtitle: Text(printer.address ?? ''),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.bluetooth),
                  selected: isSelected,
                  onTap: () => _connectToPrinter(printer),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: !_isScanning
          ? FloatingActionButton(
        onPressed: _startScan,
        child: const Icon(Icons.refresh),
      )
          : null,
    );
  }
}
