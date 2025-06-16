import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dart:io';
import 'change_username_screen.dart';
import 'change_password_screen.dart';
import 'delete_account_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';
import 'contact_us_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/bookings/bookings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color sectionColor = Colors.blue.shade700;
    final user = Provider.of<AuthProvider>(context).currentUser;
    final displayName = user?.fullName?.isNotEmpty == true
        ? user!.fullName!
        : (user?.username ?? 'Pengguna');
    final displayEmail = user?.email ?? '-';
    final displayUsername = user?.username ?? '-';
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
              // Profile Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: user?.photo != null && user!.photo!.isNotEmpty
                          ? ClipOval(
                              child: Image.file(
                                File(user!.photo!),
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.person,
                                  size: 48,
                                  color: Colors.blue.shade300,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 48,
                              color: Colors.blue.shade300,
                            ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayEmail,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@$displayUsername',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    children: [
                      _sectionTitle('Account', sectionColor),
                      _modernTile(context, icon: Icons.person_outline, label: 'Change Username', onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChangeUsernameScreen()),
                        );
                      }),
                      _modernTile(context, icon: Icons.lock_outline, label: 'Change Password', onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                        );
                      }),
                      _modernTile(context, icon: Icons.delete_outline, label: 'Delete Account', onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
                        );
                      }),
                      _modernTile(context, icon: Icons.logout, label: 'Logout', onTap: () {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        authProvider.logout();
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      }),
                      const SizedBox(height: 18),
                      _sectionTitle('General', Colors.pink.shade400),
                      // _modernTile(context, icon: Icons.notifications_none, label: 'Notification', onTap: () {}),
                      _modernTile(context, icon: Icons.star_border, label: 'Rate Us', onTap: () async {
                        const url = 'https://play.google.com/store/apps/details?id=com.mitra.barber';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        }
                      }),
                      _modernTile(context, icon: Icons.favorite_border, label: 'Liked Content', onTap: () async {
                        const url = 'https://play.google.com/store/apps/details?id=com.mitra.barber';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        }
                      }),
                      const SizedBox(height: 18),
                      _sectionTitle('Support', Colors.deepPurple.shade400),
                      _modernTile(context, icon: Icons.description_outlined, label: 'Terms of Service', onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                        );
                      }),
                      _modernTile(context, icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                        );
                      }),
                      _modernTile(context, icon: Icons.info_outline, label: 'Contact Us', onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _modernBottomBar(context),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _modernTile(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue.shade700),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
      ),
    );
  }

  Widget _modernBottomBar(BuildContext context) {
    return Container(
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
        currentIndex: 3,
        onTap: (i) {
          if (i == 3) return;
          switch (i) {
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
          }
        },
      ),
    );
  }
} 