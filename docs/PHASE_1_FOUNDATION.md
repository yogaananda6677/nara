# Fase 1 — Foundation Lokal

Status: selesai
Tanggal: 14 Juli 2026
Scope: Nara V1 offline

## Hasil implementasi

- onboarding profile lokal dengan validasi nama pengguna dan nama asisten;
- application gate yang menampilkan loading, recovery error, onboarding, atau home;
- `FoundationRepository` sebagai domain contract;
- implementasi repository Drift tanpa akses database langsung dari UI;
- use case initialize, save profile, dan save preferences;
- settings Bahasa Indonesia, IDR, `Asia/Jakarta`, dan theme system/light/dark;
- theme berubah langsung dan tersimpan di SQLite;
- profile dapat diedit dari halaman pengaturan;
- lifecycle app-lock guard tersedia tetapi tidak dapat diaktifkan sebelum PIN/biometrik Fase 6;
- foreign key SQLite diaktifkan saat database dibuka;
- database schema version 1 mempunyai explicit `MigrationStrategy`;
- seed kategori dan default settings bersifat idempotent.

## Seed kategori V1

Expense: Makanan, Transportasi, Tagihan, Belanja, Kesehatan, Pendidikan,
Hiburan, dan Lainnya.

Income: Gaji, Usaha, Hadiah, dan Pemasukan lain.

Seluruh seed memakai ID stabil dan `insertOrIgnore`, sehingga initialization
berulang tidak membuat duplikasi.

## Alur startup

```text
ProviderScope
    ↓
FoundationController
    ↓
Repository.initialize()
    ├── migration/open database
    ├── seed kategori
    └── seed settings
    ↓
Load profile + settings
    ├── profile belum ada → Onboarding
    ├── profile tersedia → Home
    └── database gagal → Error + Retry
```

## Keputusan teknis

- Profile dan settings berada di Drift/SQLite agar hanya ada satu source of truth.
- UI berinteraksi melalui controller/use case/repository, tidak melalui DAO.
- App-lock tidak dapat diaktifkan sekarang. Menampilkan switch aktif tanpa
  autentikasi aman akan memberi rasa aman palsu; aktivasi menunggu secure PIN
  hash dan biometric system API pada Fase 6.
- Data waktu ditulis dalam UTC. Default display timezone adalah `Asia/Jakarta`.
- Tidak ada dependency HTTP, backend, analytics cloud, atau AI API.

## Quality gate

- `dart run build_runner build`: lulus;
- `flutter analyze`: tidak ada issue;
- `flutter test`: 10 test lulus;
- `flutter build apk --debug`: lulus.

Test mencakup schema version, SQLite CRUD, seed idempotent, default settings,
profile/settings persistence melalui repository baru, validasi profile,
onboarding, dynamic theme, dan navigation.

APK debug: `build/app/outputs/flutter-apk/app-debug.apk`.

## Exit criteria

Profile dan settings tetap dapat dibaca melalui repository baru, yang
merepresentasikan aplikasi dibuka kembali. Fase 1 dinyatakan selesai dan Fase 2
Keuangan dapat dimulai.
