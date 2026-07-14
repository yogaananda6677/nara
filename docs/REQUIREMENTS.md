# Nara V1 — Offline Requirements

Status: baseline implementasi V1
Target utama: Android
Versi aplikasi: `1.0.0+1`

## Tujuan V1

Nara V1 adalah personal assistant yang seluruh fitur intinya berjalan dan menyimpan data di perangkat. V1 tidak membutuhkan akun cloud, backend, API key, LLM online, ataupun koneksi internet.

## Ruang lingkup V1

### Foundation

- onboarding dan profil lokal;
- pengaturan bahasa, mata uang, timezone, dan tema;
- PIN/biometrik perangkat;
- database SQLite lokal dengan migration;
- backup dan restore file lokal;
- status dan error handling yang jelas.

### Keuangan

- akun, kategori, pemasukan, dan pengeluaran;
- transfer internal antar akun;
- target tabungan;
- pencarian, filter, dan laporan bulanan;
- nilai uang disimpan sebagai integer unit terkecil.

### Produktivitas

- task, prioritas, deadline, subtugas, status, dan pengulangan;
- jadwal, lokasi, catatan, serta agenda harian;
- reminder lokal;
- log aktivitas dan ringkasan harian/mingguan.

### Assistant offline

- command parser berbasis aturan untuk perintah sederhana;
- intent lokal untuk membuat transaksi, task, dan jadwal;
- preview dan konfirmasi sebelum menyimpan perubahan;
- audit log lokal untuk tindakan assistant.

### Smart Scan offline

- input kamera atau galeri;
- OCR dilakukan di perangkat;
- parser struk menghasilkan draft transaksi;
- gambar tidak dikirim keluar perangkat;
- hasil wajib diperiksa dan dikonfirmasi pengguna.

## Di luar V1

- LLM/API online;
- RAG dengan model online;
- backend dan sinkronisasi cloud;
- multi-device sync;
- integrasi bank/e-wallet dan transfer dana eksternal;
- vector database;
- analytics atau crash reporting cloud;
- voice assistant yang memerlukan internet;
- local LLM penuh.

Fitur tersebut hanya dapat masuk V2 setelah V1 offline stabil dan ada keputusan privacy/security baru.

## Arsitektur

```text
Presentation (pages, widgets, providers)
                 ↓
Application (use cases, local command dispatcher)
                 ↓
Domain (entities, value objects, repository contracts)
                 ↑
Data (repository implementation, Drift/SQLite, local files)
```

Aturan wajib:

- struktur feature-first dengan dependency mengarah ke domain;
- UI tidak boleh mengakses database/DAO secara langsung;
- repository contract berada di domain;
- operasi yang mengubah beberapa record harus atomic;
- waktu disimpan dalam UTC dan ditampilkan sesuai timezone pengguna;
- assistant memakai use case yang sama dengan UI;
- tidak ada perubahan dari assistant tanpa validasi, preview, dan konfirmasi;
- business logic tidak berada di widget.

## Toolchain dan dependency awal

| Area | Pilihan |
|---|---|
| SDK | Flutter 3.44 / Dart >=3.12 <4.0 |
| State/DI | Riverpod |
| Routing | GoRouter |
| Database | Drift + SQLite |
| Local settings | Drift/SQLite sebagai satu source of truth |
| Formatting | Intl |
| ID | UUID |
| Testing | Flutter Test |

Plugin OCR, notifikasi, biometrik, kamera, dan file backup ditambahkan pada fasenya setelah spike Android. Tidak ada dependency HTTP pada baseline V1.

## Model data lokal V1

Schema awal menyediakan:

- `profiles`;
- `accounts`;
- `categories`;
- `transaction_entries`;
- `saving_goals`;
- `tasks`;
- `schedules`;
- `activity_logs`;
- `reminders`;
- `tool_audits`;
- `app_settings`.

Setiap tabel mutable menggunakan ID stabil serta `created_at` dan `updated_at` bila relevan. Setiap perubahan schema wajib menaikkan `schemaVersion`, mempunyai migration, dan migration test.

## Security dan privacy

- tidak ada secret atau PII dalam source, fixture, log, dan screenshot;
- PIN tidak disimpan plaintext;
- biometrik memakai API sistem;
- backup sensitif harus dienkripsi sebelum release candidate;
- OCR dan parsing gambar dilakukan lokal;
- log teknis tidak boleh memuat nominal/deskripsi pribadi secara lengkap;
- seluruh data dapat dihapus pengguna dari perangkat.

## Quality gate

Setiap increment wajib lulus:

```text
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

Fitur native wajib diuji pada emulator dan minimal satu perangkat Android nyata sebelum dinyatakan selesai.

## Target performa

- dashboard tampil kurang dari 1 detik setelah database siap;
- CRUD lokal kurang dari 500 ms;
- klasifikasi lokal kurang dari 2 detik;
- OCR lokal kurang dari 5 detik;
- command execution kurang dari 2 detik setelah konfirmasi.
