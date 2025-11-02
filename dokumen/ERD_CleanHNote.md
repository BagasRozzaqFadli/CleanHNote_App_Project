# Entity Relationship Diagram (ERD)
## CleanHNote - Database Design

---

### Informasi Tim
- **Nama Kelompok**: Bagas Rozzaq Fadli (221240001280) & Muhammad Alif Nur Hanif (221240001276)
- **Mata Kuliah**: Pemrograman Mobile Lanjut
- **Tanggal**: September 2025

---

## 1. Database Overview

CleanHNote menggunakan Appwrite Database dengan 4 tabel utama:

## 2. Tabel Database

### 2.1 Tabel Users (Pengguna)
| Field | Type | Keterangan |
|-------|------|------------|
| id | String | ID unik pengguna |
| email | String | Email pengguna |
| name | String | Nama lengkap |
| subscription | String | free atau premium |
| created_at | Date | Tanggal daftar |

### 2.2 Tabel Tasks (Tugas)
| Field | Type | Keterangan |
|-------|------|------------|
| id | String | ID unik tugas |
| title | String | Judul tugas |
| description | String | Deskripsi tugas |
| user_id | String | ID pembuat tugas |
| assigned_to | String | ID yang ditugaskan |
| team_id | String | ID tim (jika ada) |
| status | String | pending, completed, cancelled |
| priority | String | low, medium, high, urgent |
| due_date | Date | Tanggal deadline |
| created_at | Date | Tanggal dibuat |

### 2.3 Tabel Teams (Tim)
| Field | Type | Keterangan |
|-------|------|------------|
| id | String | ID unik tim |
| name | String | Nama tim |
| owner_id | String | ID pemilik tim |
| created_at | Date | Tanggal dibuat |

### 2.4 Tabel Photos (Foto)
| Field | Type | Keterangan |
|-------|------|------------|
| id | String | ID unik foto |
| task_id | String | ID tugas terkait |
| photo_type | String | before atau after |
| file_url | String | URL file foto |
| uploaded_at | Date | Tanggal upload |

## 3. Hubungan Antar Tabel

```
Users (1) ──── (∞) Tasks
  │
  └── (1) ──── (∞) Teams (sebagai owner)

Teams (1) ──── (∞) Tasks (tugas tim)

Tasks (1) ──── (∞) Photos (foto dokumentasi)
```

## 4. Penjelasan Hubungan

- **1 User** bisa punya **banyak Tasks**
- **1 User** bisa punya **banyak Teams** (sebagai owner)
- **1 Team** bisa punya **banyak Tasks**
- **1 Task** bisa punya **banyak Photos**

## 5. Contoh Data

### Users
```
id: "user1"
email: "bagas@email.com"
name: "Bagas Rozzaq"
subscription: "free"
```

### Tasks
```
id: "task1"
title: "Bersihkan kamar"
description: "Sapu dan pel lantai"
user_id: "user1"
status: "pending"
priority: "medium"
```

---

