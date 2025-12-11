import 'package:flutter/material.dart';
import 'terms_of_service_screen.dart';
import 'app_support_screen.dart';

/// About Us Landing Screen with navigation to ToS and Support
class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  bool _isEnglish = true; // Default to English

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEnglish ? 'About Us' : 'Tentang Kami'),
        backgroundColor: Colors.indigo[700],
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
            colors: [Colors.white, Colors.indigo[50]!],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo[400]!, Colors.indigo[700]!],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.task_alt,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // App Name
              const Text(
                'CleanHNote',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 8),

              // Tagline
              Text(
                _isEnglish
                    ? 'Task Management & Team Collaboration App'
                    : 'Aplikasi Manajemen Tugas & Kolaborasi Tim',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                'Version 1.0.0',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 40),

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
                child: Text(
                  _isEnglish
                      ? 'CleanHNote is a modern productivity solution that helps you organize personal tasks and collaborate with teams. With comprehensive features like unlimited task management (Premium), QR code team system, task photo verification, and real-time analytics, CleanHNote is designed to boost your efficiency and productivity.'
                      : 'CleanHNote adalah solusi produktivitas modern yang membantu Anda mengorganisir tugas pribadi dan berkolaborasi dengan tim. Dengan fitur-fitur lengkap seperti manajemen tugas tanpa batas (Premium), sistem tim dengan QR code, verifikasi foto tugas, dan analitik real-time, CleanHNote dirancang untuk meningkatkan efisiensi dan produktivitas Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Navigation Cards
              _buildNavigationCard(
                context,
                icon: Icons.description,
                title: 'Terms of Services',
                description: _isEnglish
                    ? 'Read complete terms of service for CleanHNote'
                    : 'Baca ketentuan layanan lengkap untuk CleanHNote',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsOfServiceScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildNavigationCard(
                context,
                icon: Icons.favorite,
                title: _isEnglish
                    ? 'Support the App'
                    : 'Dukungan untuk Aplikasi',
                description: _isEnglish
                    ? 'Support CleanHNote development'
                    : 'Dukung pengembangan aplikasi CleanHNote',
                color: Colors.pink,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AppSupportScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Footer
              Text(
                '© 2025 CleanHNote\n${_isEnglish ? "All rights reserved" : "Hak cipta dilindungi"}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
