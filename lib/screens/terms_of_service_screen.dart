import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

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
                      'Terms of Service',
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
                      child: const _TermsContent(),
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

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Syarat & Ketentuan Penggunaan',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Text(
          'Aplikasi ini tunduk pada ketentuan Google Play dan hukum yang berlaku di Indonesia. Dengan menggunakan aplikasi ini, Anda menyetujui syarat dan ketentuan berikut:',
          style: TextStyle(fontSize: 15),
        ),
        SizedBox(height: 16),
        Text('1. Penggunaan Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(
          'Aplikasi hanya boleh digunakan untuk tujuan yang sah dan tidak melanggar hukum. Dilarang menggunakan aplikasi untuk aktivitas ilegal, penipuan, atau pelanggaran hak pihak ketiga.',
        ),
        SizedBox(height: 12),
        Text('2. Data & Privasi', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(
          'Kami menghormati privasi Anda. Data yang dikumpulkan hanya digunakan untuk keperluan aplikasi dan tidak dibagikan ke pihak ketiga tanpa izin, kecuali diwajibkan oleh hukum.',
        ),
        SizedBox(height: 12),
        Text('3. Hak Kekayaan Intelektual', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(
          'Seluruh konten, logo, dan desain aplikasi adalah milik pengembang dan dilindungi undang-undang. Dilarang menyalin, memodifikasi, atau mendistribusikan tanpa izin.',
        ),
        SizedBox(height: 12),
        Text('4. Pembaruan & Perubahan', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(
          'Pengembang berhak memperbarui, mengubah, atau menghentikan layanan aplikasi sewaktu-waktu dengan atau tanpa pemberitahuan.',
        ),
        SizedBox(height: 12),
        Text('5. Tanggung Jawab', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(
          'Pengembang tidak bertanggung jawab atas kerugian atau kerusakan akibat penggunaan aplikasi di luar kendali pengembang.',
        ),
        SizedBox(height: 12),
        Text('6. Kontak', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(
          'Jika ada pertanyaan terkait syarat & ketentuan, silakan hubungi kami melalui email yang tertera di Google Play.',
        ),
        SizedBox(height: 16),
        Text(
          'Dengan menggunakan aplikasi ini, Anda dianggap telah membaca, memahami, dan menyetujui seluruh syarat & ketentuan ini.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
} 