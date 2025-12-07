# Setup Koleksi Appwrite - PENTING!

Sebelum menjalankan aplikasi, Anda HARUS membuat collection di Appwrite Console terlebih dahulu.

## Langkah-langkah Setup:

### 1. Buka Appwrite Console
- Login ke: https://cloud.appwrite.io
- Pilih project: **6935585d000912ee1a86**
- Pilih database: **693558df001f7968fabd**

### 2. Buat Collection Baru
- Klik "Add Collection"
- **Collection ID**: `team_task_photos` (HARUS SAMA!)
- **Collection Name**: Team Task Photos
- Klik "Create"

### 3. Tambahkan Attributes

Klik tab "Attributes" dan tambahkan field berikut:

| Attribute Key | Type   | Size    | Required | Array | Default |
|---------------|--------|---------|----------|-------|---------|
| `teamTaskId`  | String | 255     | ✅ Yes   | ❌ No  | -       |
| `photoType`   | String | 50      | ✅ Yes   | ❌ No  | -       |
| `base64Data`  | String | 1000000 | ✅ Yes   | ❌ No  | -       |
| `createdAt`   | String | 255     | ✅ Yes   | ❌ No  | -       |
| `sizeKB`      | Double | -       | ❌ No    | ❌ No  | -       |

**PENTING untuk `base64Data`:**
- Type: **String**
- Size: **1000000** (1 juta karakter = ~750KB Base64)
- Required: **Yes**

### 4. Setup Permissions

Klik tab "Settings" → "Permissions":

**CREATE:**
- Role: `Users`
- Permission: ✅ Create

**READ:**
- Role: `Users`  
- Permission: ✅ Read

**UPDATE:**
- Role: `Users`
- Permission: ✅ Update

**DELETE:**
- Role: `Users`
- Permission: ✅ Delete

### 5. Create Indexes (Opsional, untuk performa)

Klik tab "Indexes" → "Create Index":

**Index 1:**
- Index Key: `teamTaskId_idx`
- Type: Key
- Attributes: `teamTaskId` (ascending)

**Index 2:**
- Index Key: `teamTaskId_photoType_idx`
- Type: Key  
- Attributes: `teamTaskId` (ascending), `photoType` (ascending)

---

## Verifikasi Setup

Setelah setup selesai, pastikan:
- ✅ Collection ID = `team_task_photos`
- ✅ Database ID = `693558df001f7968fabd`
- ✅ Semua 5 attributes sudah dibuat
- ✅ Permissions sudah di-set untuk Users

## Testing

Setelah setup, aplikasi akan otomatis:
1. Upload foto "before" ke Appwrite Documents (bukan Firestore)
2. Upload foto "after" ke Appwrite Documents
3. Hanya simpan reference ID di Firestore (~200 bytes)

**Hasil:**
- Firestore: 400KB → 200 bytes (99.95% lebih kecil!)
- Appwrite: Store actual Base64 photos
- Total capacity: 1GB (Firestore) + 2GB (Appwrite) = 3GB!

---

## Troubleshooting

**Error: "Collection not found"**
→ Pastikan Collection ID = `team_task_photos` (exact match)

**Error: "Attribute not found"**  
→ Cek apakah semua 5 attributes sudah dibuat

**Error: "Document size exceeded"**
→ Naikkan size `base64Data` menjadi 1000000

**Error: "Permission denied"**
→ Pastikan permissions untuk Users sudah di-set
