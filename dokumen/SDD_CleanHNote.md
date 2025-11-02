# Software Design Document (SDD)
## CleanHNote - Desain Arsitektur Aplikasi

---

### Informasi Tim
- **Nama Kelompok**: Bagas Rozzaq Fadli (221240001280) & Muhammad Alif Nur Hanif (221240001276)
- **Mata Kuliah**: Pemrograman Mobile Lanjut
- **Tanggal**: September 2025

---

## 1. Arsitektur Aplikasi

CleanHNote menggunakan arsitektur sederhana:

```
┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │◄──►│   Appwrite      │
│   (Frontend)    │    │   (Backend)     │
└─────────────────┘    └─────────────────┘
```

## 2. Struktur Folder Flutter

```
lib/
├── screens/          # Halaman aplikasi
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── task_screen.dart
│   └── team_screen.dart
├── widgets/          # Komponen UI
│   ├── task_card.dart
│   ├── custom_button.dart
│   └── photo_gallery.dart
├── models/           # Data model
│   ├── user.dart
│   ├── task.dart
│   └── team.dart
├── services/         # Layanan
│   ├── auth_service.dart
│   ├── task_service.dart
│   └── team_service.dart
└── main.dart
```

## 3. Komponen Utama

### 3.1 Screens (Halaman)
- **LoginScreen**: Halaman login dan daftar
- **HomeScreen**: Halaman utama dengan daftar tugas
- **TaskScreen**: Halaman detail dan buat tugas
- **TeamScreen**: Halaman kelola tim (Premium)

### 3.2 Widgets (Komponen UI)
- **TaskCard**: Kartu untuk menampilkan tugas
- **CustomButton**: Tombol dengan desain konsisten
- **PhotoGallery**: Galeri foto dokumentasi

### 3.3 Models (Data)
- **User**: Data pengguna (nama, email, subscription)
- **Task**: Data tugas (judul, deskripsi, status, dll)
- **Team**: Data tim (nama, owner, anggota)

### 3.4 Services (Layanan)
- **AuthService**: Login, daftar, logout
- **TaskService**: CRUD operasi tugas
- **TeamService**: Kelola tim dan anggota

## 4. Database Design

### 4.1 Collections di Appwrite
- **users**: Data pengguna
- **tasks**: Data tugas
- **teams**: Data tim
- **photos**: Data foto

### 4.2 Permissions
- User hanya bisa akses data miliknya
- Team owner bisa akses data tim
- Team member bisa akses data tim

## 5. API Integration

### 5.1 Authentication
```dart
// Login
await Appwrite.account.createEmailSession(
  email: email,
  password: password,
);

// Daftar
await Appwrite.account.create(
  userId: ID.unique(),
  email: email,
  password: password,
  name: name,
);
```

### 5.2 Database Operations
```dart
// Buat tugas
await Appwrite.database.createDocument(
  databaseId: databaseId,
  collectionId: 'tasks',
  documentId: ID.unique(),
  data: {
    'title': title,
    'description': description,
    'user_id': userId,
    'status': 'pending',
  },
);
```

## 6. State Management

Menggunakan **Provider** untuk mengelola state:

```dart
class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  
  List<Task> get tasks => _tasks;
  
  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }
  
  void updateTask(Task task) {
    int index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      notifyListeners();
    }
  }
}
```

## 7. UI/UX Design

### 7.1 Design System
- **Warna**: Primary (Biru), Secondary (Hijau), Error (Merah)
- **Font**: Roboto untuk Android
- **Icon**: Material Icons
- **Spacing**: 8px, 16px, 24px, 32px

### 7.2 Screen Layouts
- **Login**: Form di tengah layar
- **Home**: List tugas dengan FAB untuk tambah
- **Task Detail**: Form edit dengan tombol save
- **Team**: List anggota dengan tombol invite

## 8. Security

### 8.1 Data Protection
- Password dienkripsi oleh Appwrite
- Token JWT untuk autentikasi
- HTTPS untuk semua komunikasi

### 8.2 Access Control
- User hanya bisa akses data miliknya
- Premium features dicek di frontend dan backend

## 9. Performance

### 9.1 Optimization
- Lazy loading untuk list tugas
- Image compression untuk foto
- Caching data di local storage

### 9.2 Error Handling
- Try-catch untuk semua API calls
- User-friendly error messages
- Retry mechanism untuk network errors

---
