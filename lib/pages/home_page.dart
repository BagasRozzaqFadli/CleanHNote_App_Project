import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cleanhnote/provider/auth_provider.dart';

/// Halaman utama setelah user berhasil login
/// (versi tanpa sistem role/premium agar aman dijalankan)
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Text(
              'CleanHNote',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            // ================================
            // Bagian label Premium (dinonaktifkan sementara)
            // ================================
            /*
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber[400],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Premium',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            */
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {
              // TODO: tambahkan logika notifikasi nanti
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () {
              authProvider.logout();
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===============================
              // Bagian Sambutan
              // ===============================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat datang, ${user.name}!',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Pesan sambutan default
                    const Text(
                      'Upgrade ke premium untuk fitur tambahan.',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ===============================
              // Bagian Akses Cepat
              // ===============================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickAccess(
                    context,
                    icon: Icons.assignment_outlined,
                    label: 'Tugas Pribadi',
                    color: Colors.blue[100]!,
                    onTap: () {
                      // TODO: Arahkan ke halaman tugas pribadi
                    },
                  ),
                  _buildQuickAccess(
                    context,
                    icon: Icons.group_outlined,
                    label: 'Tim Saya',
                    color: Colors.green[100]!,
                    onTap: () {
                      // TODO: Arahkan ke halaman tim
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ===============================
              // Bagian Tugas Terbaru
              // ===============================
              _buildSectionTitle('Tugas Pribadi Terbaru', onViewAll: () {
                // TODO: Navigasi ke halaman daftar tugas
              }),
              _buildEmptyCard('Belum ada tugas aktif.'),

              const SizedBox(height: 24),

              // ===============================
              // Bagian Tim
              // ===============================
              _buildSectionTitle('Tim Saya', onViewAll: () {
                // TODO: Navigasi ke halaman daftar tim
              }),
              _buildEmptyCard('Belum ada tim.'),
            ],
          ),
        ),
      ),
    );
  }

  /// Komponen judul bagian (misal: “Tugas Pribadi Terbaru”)
  Widget _buildSectionTitle(String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: const Text(
            'Lihat Semua',
            style: TextStyle(color: Colors.purple),
          ),
        ),
      ],
    );
  }

  /// Komponen kartu kosong (placeholder)
  Widget _buildEmptyCard(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Colors.black54),
        ),
      ),
    );
  }

  /// Komponen tombol akses cepat
  Widget _buildQuickAccess(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color,
              child: Icon(icon, color: Colors.black87, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
