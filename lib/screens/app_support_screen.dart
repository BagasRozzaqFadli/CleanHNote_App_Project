import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// App Support Screen - Donation and Support for Developer with Language Toggle
class AppSupportScreen extends StatefulWidget {
  const AppSupportScreen({super.key});

  @override
  State<AppSupportScreen> createState() => _AppSupportScreenState();
}

class _AppSupportScreenState extends State<AppSupportScreen> {
  bool _isEnglish = true; // Default to English

  // Saweria donation link
  static const String _saweriaUrl = 'https://saweria.co/hironing';

  Future<void> _launchSaweria(BuildContext context) async {
    final Uri url = Uri.parse(_saweriaUrl);

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEnglish
                    ? 'Could not open donation page. Please try again.'
                    : 'Tidak dapat membuka halaman donasi. Silakan coba lagi.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEnglish ? 'App Support' : 'Dukungan untuk Aplikasi'),
        backgroundColor: Colors.pink[700],
        foregroundColor: Colors.white,
        actions: [
          // Language Toggle
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Text(
                  'ID',
                  style: TextStyle(
                    color: _isEnglish ? Colors.white60 : Colors.white,
                    fontWeight: _isEnglish
                        ? FontWeight.normal
                        : FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Switch(
                  value: _isEnglish,
                  onChanged: (value) {
                    setState(() {
                      _isEnglish = value;
                    });
                  },
                  activeTrackColor: Colors.amber.withOpacity(0.5),
                  activeThumbColor: Colors.amber,
                  inactiveThumbColor: Colors.white,
                ),
                Text(
                  'EN',
                  style: TextStyle(
                    color: _isEnglish ? Colors.white : Colors.white60,
                    fontWeight: _isEnglish
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.pink[50]!],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink[400]!, Colors.pink[700]!],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                _isEnglish ? 'Support Development' : 'Dukung Pengembangan',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'CleanHNote',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // Description
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.pink[400]),
                    const SizedBox(height: 16),
                    Text(
                      _isEnglish
                          ? 'Thank you for using CleanHNote!'
                          : 'Terima kasih telah menggunakan CleanHNote!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isEnglish
                          ? 'Your support means a lot to the Developer to continue developing and improving CleanHNote features. Your donations will help with:'
                          : 'Dukungan Anda sangat berarti bagi Developer untuk terus mengembangkan dan meningkatkan fitur-fitur CleanHNote. Donasi Anda akan membantu dalam:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Benefits Cards
              _buildBenefitCard(
                icon: Icons.build,
                title: _isEnglish
                    ? 'Feature Development'
                    : 'Pengembangan Fitur',
                description: _isEnglish
                    ? 'Adding more advanced new features'
                    : 'Menambahkan fitur-fitur baru yang lebih canggih',
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildBenefitCard(
                icon: Icons.speed,
                title: _isEnglish
                    ? 'Performance Improvement'
                    : 'Peningkatan Performa',
                description: _isEnglish
                    ? 'Optimizing the app for faster and more stable performance'
                    : 'Optimasi aplikasi agar lebih cepat dan stabil',
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              _buildBenefitCard(
                icon: Icons.cloud_upload,
                title: _isEnglish
                    ? 'Server Infrastructure'
                    : 'Infrastruktur Server',
                description: _isEnglish
                    ? 'Maintaining server and database for optimal performance'
                    : 'Menjaga server dan database tetap optimal',
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildBenefitCard(
                icon: Icons.support_agent,
                title: _isEnglish ? 'User Support' : 'Dukungan Pengguna',
                description: _isEnglish
                    ? 'Providing continuous support and maintenance'
                    : 'Memberikan support dan maintenance berkelanjutan',
                color: Colors.purple,
              ),
              const SizedBox(height: 32),

              // Donation Button (Active)
              InkWell(
                onTap: () => _launchSaweria(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.pink[400]!, Colors.pink[600]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.volunteer_activism,
                        size: 56,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isEnglish ? 'Support Developer' : 'Dukung Developer',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isEnglish ? 'Donate Now' : 'Donasi Sekarang',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.pink[600],
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isEnglish
                                  ? 'Open Donation Page'
                                  : 'Buka Halaman Donasi',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.pink[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isEnglish
                              ? 'Every donation, no matter the amount, will greatly help the Developer in making CleanHNote even better!'
                              : 'Setiap donasi, berapapun nominalnya, akan sangat membantu Developer dalam mengembangkan CleanHNote lebih baik lagi!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Payment Methods Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.pink[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment, color: Colors.pink[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _isEnglish ? 'Payment Methods' : 'Metode Pembayaran',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isEnglish
                          ? 'Supports various payment methods:\nQRIS • GoPay • OVO • DANA • LinkAja'
                          : 'Mendukung berbagai metode pembayaran:\nQRIS • GoPay • OVO • DANA • LinkAja',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Thank You Note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.pink[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.pink[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isEnglish
                            ? 'Every bit of your support is valuable and motivates the Developer to keep innovating!'
                            : 'Setiap dukungan dari Anda sangat berharga dan memotivasi Developer untuk terus berinovasi!',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
