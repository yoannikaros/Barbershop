import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  // Printer manager
  final PrinterManager _printerManager = PrinterManager.instance;

  // Selected printer
  PrinterDevice? _selectedPrinter;
  PrinterDevice? get selectedPrinter => _selectedPrinter;

  // Printer connection status
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Initialize the printer service
  Future<void> initialize() async {
    // Request Bluetooth permissions
    await _requestPermissions();

    // Initialize printer manager
    _printerManager.discovery(type: PrinterType.bluetooth);
  }

  // Request necessary permissions
  Future<void> _requestPermissions() async {
    if (await Permission.bluetooth.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.bluetoothScan.request().isGranted &&
        await Permission.location.request().isGranted) {
      return;
    }
  }

  // Discover Bluetooth printers
  Stream<PrinterDevice> discoverPrinters() {
    return _printerManager.discovery(
      type: PrinterType.bluetooth,
      isBle: false,
    );
  }

  // Connect to a printer
  Future<bool> connectPrinter(PrinterDevice printer) async {
    try {
      _selectedPrinter = printer;
      _isConnected = await _printerManager.connect(
        type: PrinterType.bluetooth,
        model: BluetoothPrinterInput(
          address: printer.address!,
          name: printer.name,
          isBle: false,
        ),
      );
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  // Disconnect from the printer
  Future<bool> disconnect() async {
    try {
      _isConnected = false;
      _selectedPrinter = null;
      return await _printerManager.disconnect(type: PrinterType.bluetooth);
    } catch (e) {
      return false;
    }
  }

  // Print a receipt from a widget
  Future<bool> printReceiptFromWidget(GlobalKey receiptKey) async {
    if (!_isConnected || _selectedPrinter == null) {
      return false;
    }

    try {
      // Capture the receipt widget as an image
      final RenderRepaintBoundary boundary =
      receiptKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        return false;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Convert to grayscale for better printing on thermal printers
      final img.Image? originalImage = img.decodeImage(pngBytes);
      if (originalImage == null) {
        return false;
      }

      // Resize image to fit printer width (typically 384px for 58mm printers)
      final img.Image resizedImage = img.copyResize(
        originalImage,
        width: 384,
        height: (originalImage.height * 384 / originalImage.width).round(),
      );

      // Convert to grayscale
      final img.Image grayscaleImage = img.grayscale(resizedImage);
      final Uint8List processedImageBytes = Uint8List.fromList(img.encodePng(grayscaleImage));

      // Print the image
      final result = await _printerManager.send(
        type: PrinterType.bluetooth,
        bytes: processedImageBytes,
      );

      // No direct paperCut method, so we'll send a paper cut command manually
      final List<int> cutCommand = [0x1D, 0x56, 0x41, 0x10]; // Standard GS V command for paper cut
      await _printerManager.send(
        type: PrinterType.bluetooth,
        bytes: Uint8List.fromList(cutCommand),
      );

      return result;
    } catch (e) {
      return false;
    }
  }
}
