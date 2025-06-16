import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/database_helper.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({Key? key}) : super(key: key);

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _isLoading = false;
  String? _status;

  Future<String> _getDbPath() async {
    final db = await DatabaseHelper.instance.database;
    return db.path;
  }

  Future<void> _backupDatabase() async {
    setState(() {
      _isLoading = true;
      _status = null;
    });
    try {
      final dbPath = await _getDbPath();
      final dbFile = File(dbPath);
      final dir = await getExternalStorageDirectory();
      final backupDir = Directory('${dir!.path}/BarbershopBackup');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      final backupPath =
          '${backupDir.path}/barbershop_backup_${DateTime.now().millisecondsSinceEpoch}.db';
      await dbFile.copy(backupPath);
      setState(() {
        _status = 'Backup berhasil: $backupPath';
      });
    } catch (e) {
      setState(() {
        _status = 'Backup gagal: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreDatabase() async {
    setState(() {
      _isLoading = true;
      _status = null;
    });
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result != null && result.files.single.path != null) {
        final pickedFile = File(result.files.single.path!);
        final dbPath = await _getDbPath();
        final dbFile = File(dbPath);
        await dbFile.writeAsBytes(await pickedFile.readAsBytes(), flush: true);
        setState(() {
          _status = 'Restore berhasil!';
        });
      } else {
        setState(() {
          _status = 'Restore dibatalkan.';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Restore gagal: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore Database'),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade800, Colors.blue.shade400],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Backup & Restore',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _backupDatabase,
                      icon: const Icon(Icons.backup),
                      label: const Text('Backup Database'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _restoreDatabase,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload & Restore'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 24),
                      const Center(child: CircularProgressIndicator()),
                    ],
                    if (_status != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        _status!,
                        style: TextStyle(
                          color:
                              _status!.contains('berhasil')
                                  ? Colors.green
                                  : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
