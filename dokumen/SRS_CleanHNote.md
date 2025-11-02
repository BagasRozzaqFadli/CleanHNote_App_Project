# Software Requirement Specification (SRS)
## CleanHNote - Spesifikasi Kebutuhan Perangkat Lunak

---

### Informasi Tim
- **Nama Kelompok**: Bagas Rozzaq Fadli (221240001280) & Muhammad Alif Nur Hanif (221240001276)
- **Mata Kuliah**: Pemrograman Mobile Lanjut
- **Tanggal**: September 2025

---

## 1. Pengenalan

CleanHNote adalah aplikasi mobile untuk mengelola tugas bersih-bersih. Dokumen ini menjelaskan apa yang harus bisa dilakukan aplikasi.

## 2. MVP (Minimum Viable Product)

MVP CleanHNote adalah versi paling dasar yang harus bisa berfungsi untuk memenuhi kebutuhan utama pengguna. MVP ini fokus pada fitur-fitur core yang memungkinkan pengguna untuk:

- **Mengelola tugas personal** dengan lengkap
- **Mengatur jadwal dan deadline** 
- **Mengorganisir tugas** berdasarkan kategori dan prioritas

### 2.1 Login dan Daftar (MVP Core)
- **REQ-001**: User bisa daftar dengan email dan password
- **REQ-002**: User bisa login dengan email dan password
- **REQ-003**: User bisa logout dari aplikasi
- **REQ-004**: User bisa reset password jika lupa

### 2.2 Kelola Tugas (MVP Core)
- **REQ-005**: User bisa buat tugas baru
- **REQ-006**: User bisa lihat daftar tugas
- **REQ-007**: User bisa edit tugas yang sudah ada
- **REQ-008**: User bisa hapus tugas
- **REQ-009**: User bisa tandai tugas selesai

### 2.3 Kategori dan Prioritas (MVP Core)
- **REQ-010**: User bisa pilih kategori tugas (bersih-bersih, perawatan, dll)
- **REQ-011**: User bisa set prioritas (rendah, sedang, tinggi, urgent)
- **REQ-012**: User bisa set deadline tugas

## 3. Fitur Tambahan (Post-MVP)

### 3.1 Fitur Tim (Premium)
- **REQ-015**: User premium bisa buat tim
- **REQ-016**: User premium bisa undang anggota tim
- **REQ-017**: User premium bisa assign tugas ke anggota

### 3.2 Upload Foto (Premium)
- **REQ-018**: User premium bisa upload foto sebelum tugas
- **REQ-019**: User premium bisa upload foto sesudah tugas
- **REQ-020**: User premium bisa lihat galeri foto

## 4. Kebutuhan Non-Fungsional

### 4.1 Performa
- Aplikasi harus buka dalam 3 detik
- Buat tugas harus selesai dalam 2 detik
- Upload foto harus selesai dalam 10 detik

### 4.2 Keamanan
- Password harus dienkripsi
- Data user harus aman
- Hanya user yang login bisa akses data

### 4.3 Kemudahan Penggunaan
- Interface harus mudah dipahami
- Tombol dan menu harus jelas
- Aplikasi harus mudah dipelajari

### 4.4 Kompatibilitas
- Berjalan di Android 5.0 ke atas
- Berjalan di iOS 12.0 ke atas
- Butuh koneksi internet

## 5. Batasan Aplikasi

- Maksimal 50 anggota per tim (Premium)
- Maksimal 10MB per foto
- Maksimal 1000 tugas per user (Free)
- Tidak ada batas tugas untuk Premium

## 6. Skenario Penggunaan

### 6.1 User Baru
1. Download aplikasi
2. Daftar akun
3. Buat tugas pertama
4. Set reminder

### 6.2 User Harian
1. Buka aplikasi
2. Lihat daftar tugas hari ini
3. Kerjakan tugas
4. Tandai selesai

### 6.3 User Premium
1. Buat tim
2. Undang anggota
3. Assign tugas ke anggota
4. Upload foto dokumentasi

---

