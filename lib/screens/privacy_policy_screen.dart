import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade800, Colors.blue.shade400],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      width: 600,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const _PrivacyContent(),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Kembali', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyContent extends StatelessWidget {
  const _PrivacyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Kebijakan Privasi',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Text(
          'Aplikasi ini menghormati dan melindungi privasi pengguna sesuai dengan ketentuan Google Play dan hukum yang berlaku di Indonesia. Dengan menggunakan aplikasi ini, Anda menyetujui kebijakan privasi berikut:',
          style: TextStyle(fontSize: 15),
        ),
        SizedBox(height: 16),
        Text('1. Pengumpulan Data', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(
          'Kami hanya mengumpulkan data yang diperlukan untuk menjalankan dan meningkatkan layanan aplikasi. Data yang dikumpulkan dapat berupa nama, email, dan informasi lain yang relevan.',
        ),
        SizedBox(height: 12),
        Text('2. Penggunaan Data', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(
          'Data yang dikumpulkan digunakan untuk keperluan aplikasi, seperti autentikasi, personalisasi, dan peningkatan layanan. Kami tidak membagikan data pribadi kepada pihak ketiga tanpa izin, kecuali diwajibkan oleh hukum.',
        ),
        SizedBox(height: 12),
        Text('3. Keamanan Data', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(
          'Kami berkomitmen menjaga keamanan data pengguna dengan menerapkan langkah-langkah teknis dan organisasi yang wajar untuk melindungi data dari akses, perubahan, atau penghapusan yang tidak sah.',
        ),
        SizedBox(height: 12),
        Text('4. Hak Pengguna', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(
          'Pengguna berhak mengakses, memperbaiki, atau menghapus data pribadi mereka melalui fitur yang tersedia di aplikasi.',
        ),
        SizedBox(height: 12),
        Text('5. Perubahan Kebijakan', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(
          'Kebijakan privasi ini dapat diperbarui sewaktu-waktu. Perubahan akan diinformasikan melalui aplikasi atau media lain yang relevan.',
        ),
        SizedBox(height: 12),
        Text('6. Kontak', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(
          'Jika ada pertanyaan atau permintaan terkait privasi, silakan hubungi kami melalui email yang tertera di Google Play.',
        ),
        SizedBox(height: 16),
        Text(
          'Dengan menggunakan aplikasi ini, Anda dianggap telah membaca, memahami, dan menyetujui seluruh kebijakan privasi ini.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
} 