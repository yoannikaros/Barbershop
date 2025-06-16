import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/transaction.dart';
import '../../models/transaction_detail.dart';
import '../../repositories/transaction_repository.dart';
import '../../repositories/outlet_repository.dart';
import '../../models/outlet.dart';
import '../../services/printer_service.dart';
import '../../screens/printer/printer_selection_screen.dart';

class TransactionReceiptScreen extends StatefulWidget {
  final int transactionId;

  const TransactionReceiptScreen({Key? key, required this.transactionId}) : super(key: key);

  @override
  _TransactionReceiptScreenState createState() => _TransactionReceiptScreenState();
}

class _TransactionReceiptScreenState extends State<TransactionReceiptScreen> {
  final TransactionRepository _transactionRepository = TransactionRepository();
  final OutletRepository _outletRepository = OutletRepository();
  final PrinterService _printerService = PrinterService();
  final GlobalKey _receiptKey = GlobalKey();

  Transaction? _transaction;
  List<TransactionDetail> _details = [];
  Outlet? _outlet;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializePrinterService();
  }

  Future<void> _initializePrinterService() async {
    await _printerService.initialize();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transaction = await _transactionRepository.getTransactionById(widget.transactionId);
      final details = await _transactionRepository.getTransactionDetails(widget.transactionId);

      Outlet? outlet;
      if (transaction?.outletId != null) {
        outlet = await _outletRepository.getOutletById(transaction!.outletId!);
      }

      setState(() {
        _transaction = transaction;
        _details = details;
        _outlet = outlet;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load transaction details');
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

  Future<void> _captureAndShareReceipt() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Capture the receipt as an image
      RenderRepaintBoundary boundary = _receiptKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();

        // Save the image temporarily
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/receipt.png').create();
        await file.writeAsBytes(pngBytes);

        // Share the image
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Your receipt from Barbershop Offline Pro',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to share receipt: ${e.toString()}');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _printReceipt() async {
    // Check if printer is connected
    if (!_printerService.isConnected) {
      final bool? result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => const PrinterSelectionScreen(),
        ),
      );

      if (result != true) {
        return;
      }
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      final bool success = await _printerService.printReceiptFromWidget(_receiptKey);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt printed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackBar('Failed to print receipt');
      }
    } catch (e) {
      _showErrorSnackBar('Error printing receipt: ${e.toString()}');
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        actions: [
          if (!_isLoading && _transaction != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _isSaving ? null : _captureAndShareReceipt,
              tooltip: 'Share Receipt',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transaction == null
          ? const Center(child: Text('Transaction not found'))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              RepaintBoundary(
                key: _receiptKey,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                  child: _buildReceipt(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _captureAndShareReceipt,
                      icon: const Icon(Icons.share),
                      label: _isSaving
                          ? const Text('Sharing...')
                          : const Text('Share Receipt'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isPrinting ? null : _printReceipt,
                      icon: const Icon(Icons.print),
                      label: _isPrinting
                          ? const Text('Printing...')
                          : const Text('Print Receipt'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Tip: Take a screenshot to save this receipt',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceipt() {
    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    final transactionDate = DateTime.parse(_transaction!.date);
    final formattedDate = DateFormat('dd/MM/yyyy').format(transactionDate);
    final formattedTime = DateFormat('HH:mm').format(transactionDate);

    final serviceItems = _details.where((detail) => detail.itemType == 'service').toList();
    final productItems = _details.where((detail) => detail.itemType == 'product').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Center(
          child: Column(
            children: [
              const Text(
                'BARBERSHOP OFFLINE PRO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_outlet != null) ...[
                const SizedBox(height: 4),
                Text(
                  _outlet!.name,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                if (_outlet!.address != null && _outlet!.address!.isNotEmpty)
                  Text(
                    _outlet!.address!,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                if (_outlet!.phone != null && _outlet!.phone!.isNotEmpty)
                  Text(
                    'Phone: ${_outlet!.phone}',
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              const Text(
                '------------------------------',
                style: TextStyle(
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),

        // Transaction Info
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Receipt No:'),
            Text('#${_transaction!.id}'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Date:'),
            Text('$formattedDate $formattedTime'),
          ],
        ),
        if (_transaction!.customerName != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Customer:'),
              Text(_transaction!.customerName!),
            ],
          ),
        if (_transaction!.userName != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cashier:'),
              Text(_transaction!.userName!),
            ],
          ),

        const SizedBox(height: 8),
        const Text(
          '------------------------------',
          style: TextStyle(
            fontFamily: 'monospace',
          ),
        ),

        // Items
        const SizedBox(height: 8),
        const Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                'Item',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                'Qty',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Price',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '------------------------------',
          style: TextStyle(
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),

        // Services
        if (serviceItems.isNotEmpty) ...[
          ...serviceItems.map((item) => _buildItemRow(
            item.itemName ?? 'Unknown Service',
            item.quantity,
            item.price,
            item.subtotal,
            currencyFormat,
          )),
        ],

        // Products
        if (productItems.isNotEmpty) ...[
          ...productItems.map((item) => _buildItemRow(
            item.itemName ?? 'Unknown Product',
            item.quantity,
            item.price,
            item.subtotal,
            currencyFormat,
          )),
        ],

        const SizedBox(height: 4),
        const Text(
          '------------------------------',
          style: TextStyle(
            fontFamily: 'monospace',
          ),
        ),

        // Total
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TOTAL',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              currencyFormat.format(_transaction!.total),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),

        // Payment Method
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Payment Method:'),
            Text(_transaction!.paymentMethod?.toUpperCase() ?? 'CASH'),
          ],
        ),

        // Notes
        if (_transaction!.notes != null && _transaction!.notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Notes:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(_transaction!.notes!),
        ],

        // Footer
        const SizedBox(height: 24),
        const Center(
          child: Column(
            children: [
              Text(
                'Thank you for your business!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Please come again',
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(String name, int quantity, int price, int subtotal, NumberFormat currencyFormat) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              quantity.toString(),
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              currencyFormat.format(price),
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              currencyFormat.format(subtotal),
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
