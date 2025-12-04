# Penjelasan Import Statement `dart:developer`

## Apa itu `dart:developer`?

`dart:developer` adalah library bawaan Dart yang menyediakan berbagai fungsi untuk debugging dan profiling aplikasi. Library ini menyediakan fungsi-fungsi penting seperti:

- `developer.log()` - Untuk mencatat pesan log
- `debugger()` - Untuk menempatkan breakpoint dalam kode
- `Timeline` - Untuk profiling aplikasi

## Kegunaan dalam Proyek Ini

Dalam proyek CleanHNote, import `dart:developer` digunakan secara alias sebagai `developer` untuk keperluan:

1. **Mencatat informasi penting dalam aplikasi**:
   ```dart
   developer.log('Pesan log', name: 'NamaLogger');
   ```

2. **Mencatat error dengan informasi stack trace**:
   ```dart
   developer.log('Error message', name: 'NamaLogger', error: error, stackTrace: stack);
   ```

3. **Menggantikan fungsi `print()` yang tidak aman untuk production**:
   - Fungsi `print()` tidak aman karena tidak bisa difilter dan bisa bocor ke output production
   - `developer.log()` lebih aman dan bisa dikontrol tingkatannya

## File-file yang Menggunakan Import Ini

- `lib/main.dart` - Untuk logging saat inisialisasi Firebase dan pembuatan widget
- `lib/services/auth_service.dart` - Untuk logging semua operasi autentikasi
- `lib/utils/logger.dart` - Sebagai dasar dari sistem logging aplikasi

## Perbedaan dengan `print()`

| Fungsi | `print()` | `developer.log()` |
|--------|-----------|-------------------|
| Tujuan | Output sederhana | Logging struktural |
| Filter | Tidak bisa difilter | Bisa difilter berdasarkan level |
| Production | Tidak aman | Aman untuk production |
| Informasi tambahan | Hanya pesan | Bisa tambahkan error, stack trace, level, dll |