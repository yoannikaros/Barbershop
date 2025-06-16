import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/outlets/outlets_screen.dart';
import '../../screens/users/users_screen.dart';
import '../../screens/customers/customers_screen.dart';
import '../../screens/services/services_screen.dart';
import '../../screens/products/products_screen.dart';
import '../../screens/barbers/barbers_screen.dart';
import '../../screens/bookings/bookings_screen.dart';
import '../../screens/transactions/transactions_screen.dart';
import '../../screens/finance/finance_screen.dart';
import 'package:intl/intl.dart';
import '../../repositories/booking_repository.dart';
import '../../repositories/transaction_repository.dart';
import '../utils/database_helper.dart';
import 'dart:convert';
import 'package:barber/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _todayBookingCount = 0;
  int _todaySalesCount = 0;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _loadTodayStats();
    _checkTokenTrial();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Delay agar tidak double call saat initState
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _loadTodayStats();
    });
  }

  Future<void> _loadTodayStats() async {
    final bookingRepo = BookingRepository();
    final transactionRepo = TransactionRepository();
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    // Booking: semua booking hari ini (tanpa filter status)
    final allBookings = await bookingRepo.getAllBookings();
    final todayBookings =
        allBookings.where((b) {
          final date = DateTime.tryParse(b.scheduledAt);
          return date != null &&
              DateFormat('yyyy-MM-dd').format(date) == todayStr;
        }).toList();
    setState(() {
      _todayBookingCount = todayBookings.length;
    });

    // Penjualan: transaksi hari ini (jika ada status, filter selain completed)
    final allTransactions = await transactionRepo.getAllTransactions();
    final todaySales =
        allTransactions.where((t) {
          final date = DateTime.tryParse(t.date);
          return date != null &&
              DateFormat('yyyy-MM-dd').format(date) == todayStr;
          // Jika ada status di model Transaction, tambahkan && t.status != 'completed'
        }).toList();
    setState(() {
      _todaySalesCount = todaySales.length;
    });
  }

  Future<void> _checkTokenTrial() async {
    // Ambil user login dari authProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null || user.email == null) {
      // Tidak ada user/email, redirect
      if (mounted) Navigator.pushReplacementNamed(context, '/input-token');
      return;
    }
    final email = user.email!;
    final token = base64Encode(utf8.encode(email));
    // Cek token_trial
    final tokenTrial = await DatabaseHelper.instance.queryWhere(
      'token_trial',
      'token = ?',
      [token],
    );
    if (tokenTrial.isEmpty) {
      if (mounted) Navigator.pushReplacementNamed(context, '/input-token');
      return;
    }
    final trialData = tokenTrial.first;
    final isTrial = trialData['trial'] == 1;
    final startAtStr = trialData['start_at'] as String?;
    if (!isTrial) {
      // Jika trial sudah false, izinkan akses home
      return;
    }
    if (startAtStr == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/input-token');
      return;
    }
    final startAt = DateTime.tryParse(startAtStr);
    if (startAt == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/input-token');
      return;
    }
    final now = DateTime.now();
    final diff = now.difference(startAt).inDays;
    if (diff > 6) {
      if (mounted) Navigator.pushReplacementNamed(context, '/input-token');
      return;
    }
    // Jika trial masih true dan belum lebih dari 7 hari, izinkan akses home
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onNavBarTap(int index) {
    if (index == _selectedIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TransactionsScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookingsScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade800, Colors.blue.shade500],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(authProvider),

              // Main Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome Section
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildWelcomeSection(authProvider),
                          ),

                          const SizedBox(height: 24),

                          // Quick Actions Section
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildQuickActionsSection(),
                          ),

                          const SizedBox(height: 24),

                          // Main Menu Section
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildMainMenuSection(size),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.blue.shade700,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Transaksi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Booking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onNavBarTap,
        ),
      ),
    );
  }

  Widget _buildAppBar(AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.content_cut,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Barbershop Pro',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // IconButton(
              //   icon: const Icon(Icons.account_circle, color: Colors.white),
              //   tooltip: 'Profile',
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (_) => const ProfileScreen()),
              //     );
              //   },
              // ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Keluar'),
                          content: const Text('Apakah Anda yakin ingin keluar?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                authProvider.logout();
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                              child: const Text('Keluar'),
                            ),
                          ],
                        ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(AuthProvider authProvider) {
    final username =
        authProvider.currentUser?.fullName ??
        authProvider.currentUser?.username ??
        'Pengguna';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade700, Colors.blue.shade500],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 25,
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : 'P',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat datang,',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh statistik',
                onPressed: _loadTodayStats,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_today,
                  title: 'Booking',
                  subtitle: 'Hari Ini',
                  color: Colors.orange,
                  count: _todayBookingCount,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.receipt_long,
                  title: 'Penjualan',
                  subtitle: 'Hari Ini',
                  color: Colors.green,
                  count: _todaySalesCount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    int? count,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          //
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (count != null) ...[
                    Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  SizedBox(width: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aksi Cepat',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickActionButton(
              icon: Icons.receipt_long,
              label: 'Transaksi Baru',
              color: Colors.green,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TransactionsScreen(),
                    ),
                  ),
            ),
            _buildQuickActionButton(
              icon: Icons.calendar_today,
              label: 'Booking Baru',
              color: Colors.orange,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BookingsScreen()),
                  ),
            ),
            _buildQuickActionButton(
              icon: Icons.person_add,
              label: 'Pelanggan Baru',
              color: Colors.blue,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomersScreen()),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMenuSection(Size size) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Transaksi',
        'subtitle': 'Kelola transaksi harian',
        'icon': Icons.receipt_long,
        'gradient': [Colors.green.shade400, Colors.green.shade700],
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TransactionsScreen()),
        ),
      },
      {
        'title': 'Booking',
        'subtitle': 'Atur jadwal booking',
        'icon': Icons.calendar_today,
        'gradient': [Colors.orange.shade400, Colors.orange.shade700],
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookingsScreen()),
        ),
      },
      {
        'title': 'Pelanggan',
        'subtitle': 'Data pelanggan',
        'icon': Icons.people,
        'gradient': [Colors.blue.shade400, Colors.blue.shade700],
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomersScreen()),
        ),
      },
      {
        'title': 'Layanan',
        'subtitle': 'Kelola layanan',
        'icon': Icons.content_cut,
        'gradient': [Colors.purple.shade400, Colors.purple.shade700],
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ServicesScreen()),
        ),
      },
      {
        'title': 'Produk',
        'subtitle': 'Inventaris produk',
        'icon': Icons.shopping_bag,
        'gradient': [Colors.amber.shade400, Colors.amber.shade700],
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductsScreen()),
        ),
      },
      {
        'title': 'Karyawan',
        'subtitle': 'Data karyawan',
        'icon': Icons.person,
        'gradient': [Colors.teal.shade400, Colors.teal.shade700],
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BarbersScreen()),
        ),
      },
      {
        'title': 'Outlet',
        'subtitle': 'Manajemen outlet',
        'icon': Icons.store,
        'gradient': [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OutletsScreen()),
        ),
      },
      {
        'title': 'Keuangan',
        'subtitle': 'Laporan keuangan',
        'icon': Icons.account_balance_wallet,
        'gradient': [Colors.deepOrange.shade400, Colors.deepOrange.shade700],
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FinanceScreen()),
        ),
      },
      {
        'title': 'Backup & Restore',
        'subtitle': 'Kelola data',
        'icon': Icons.backup,
        'gradient': [Colors.blueAccent.shade400, Colors.blueAccent.shade700],
        'onTap': () => Navigator.pushNamed(context, '/backup-restore'),
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Hitung tinggi maksimal untuk GridView (misal: sisa tinggi layar dikurangi header dan padding)
        final double maxGridHeight = constraints.maxHeight > 400
            ? constraints.maxHeight - 60
            : 400;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Menu Utama',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.grid_view_rounded),
                    onPressed: () {},
                    tooltip: 'Ubah tampilan',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxGridHeight,
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: size.width > 600 ? 3 : 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return _buildMenuItem(
                    title: item['title'],
                    subtitle: item['subtitle'],
                    icon: item['icon'],
                    gradient: item['gradient'],
                    onTap: item['onTap'],
                    index: index,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
    required int index,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.6 + (0.4 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 4,
        shadowColor: gradient.first.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode 
                    ? [
                        gradient.first.withOpacity(0.2),
                        gradient.last.withOpacity(0.3),
                      ]
                    : [
                        gradient.first.withOpacity(0.1),
                        gradient.last.withOpacity(0.2),
                      ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradient,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.first.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode 
                          ? Colors.white70 
                          : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
