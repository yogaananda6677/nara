# Nara

[![CI](https://github.com/yogaananda6677/nara/actions/workflows/ci.yml/badge.svg)](https://github.com/yogaananda6677/nara/actions/workflows/ci.yml)

Nara adalah personal assistant Flutter yang mengelola keuangan, task, jadwal,
reminder, aktivitas, Assistant berbasis aturan, dan Smart Scan langsung di
perangkat Android. Nara V1 dirancang offline-first: tidak memakai backend,
akun cloud, API AI, atau koneksi internet untuk fitur inti.

> Status V1: Phase 0–5 selesai. Phase 6 (backup terenkripsi, PIN/biometrik,
> hardening, accessibility, dan acceptance test perangkat nyata) masih perlu
> diselesaikan sebelum V1 dinyatakan final.

## Fitur

- **Keuangan:** akun, kategori, pemasukan/pengeluaran, transfer internal,
  target tabungan, pencarian, filter, dan ringkasan bulanan.
- **Produktivitas:** task, subtask, prioritas, deadline, jadwal, reminder lokal,
  activity log, serta ringkasan harian/mingguan.
- **Assistant lokal:** memahami perintah sederhana untuk Keuangan, Task, dan
  Jadwal; selalu menampilkan preview sebelum perubahan disimpan.
- **Smart Scan:** kamera/galeri, preprocessing, OCR lokal, klasifikasi struk
  atau bukti transfer, parsing nominal/tanggal, dan draft transaksi yang dapat
  diedit.
- **Privasi lokal:** SQLite/Drift menjadi source of truth. Gambar dan teks OCR
  mentah tidak disimpan ke database atau dikirim ke server.

## Batasan saat ini

- Target utama dan perangkat yang sudah dipakai untuk smoke test adalah
  Android; platform lain belum menjadi acceptance target V1.
- Hasil Smart Scan wajib diperiksa manual sebelum dikonfirmasi, terutama untuk
  gambar buram, reflektif, tulisan tangan, dan layout struk tidak umum.
- Backup terenkripsi, restore, PIN, biometrik, dan recovery database berada di
  Phase 6.
- APK dari workflow CD adalah **debug-signed test release**, bukan artefak yang
  siap dikirim ke Google Play.

## Teknologi

- Flutter 3.44.4 dan Dart 3.12.2
- Riverpod dan GoRouter
- Drift/SQLite
- Flutter Local Notifications
- Google ML Kit Text Recognition (on-device)
- Image Picker dan package `image` untuk preprocessing

## Persyaratan pengembangan

- Flutter `3.44.4` stable (atau versi kompatibel dengan Dart `>=3.12 <4.0`)
- JDK 17 atau lebih baru
- Android SDK dan Android platform tools (`adb`)
- Perangkat/emulator Android 7.0 (API 24) atau lebih baru

Periksa environment:

```bash
flutter doctor -v
flutter --version
adb devices
```

## Menjalankan aplikasi

Clone repository dan ambil dependency:

```bash
git clone https://github.com/yogaananda6677/nara.git
cd nara
flutter pub get
```

Jalankan pada perangkat yang tersedia:

```bash
flutter devices
flutter run
```

Untuk ponsel Android fisik, aktifkan **Developer options** dan **USB debugging**,
sambungkan kabel USB, lalu izinkan fingerprint komputer ketika diminta.

Jika schema Drift diubah, regenerasi file database sebelum menjalankan app:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Quality check

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

APK debug tersedia di:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

Instal sebagai update tanpa menghapus data aplikasi:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n ananda.yoga.nara/.MainActivity
```

## Struktur project

```text
lib/
├── app/          # bootstrap, router, dan theme
├── core/         # result, error, formatter, notification, security
├── database/     # schema serta migration Drift
├── features/     # feature-first: domain, application, data, presentation
└── shared/       # widget bersama
test/             # unit, repository/database, parser, dan widget tests
docs/             # requirement, implementation plan, dan laporan tiap phase
```

Aliran dependency utama:

```text
Presentation → Application → Domain ← Data
```

UI tidak mengakses database secara langsung. Assistant dan Smart Scan memakai
service Keuangan/Produktivitas yang sama dengan form manual.

## CI/CD

- `CI` berjalan pada pull request dan push ke `main`: dependency restore,
  formatting, analyzer, 48 test, dan build APK debug.
- `Android Test Release` berjalan saat tag `v*` didorong. Workflow mengulang
  quality gate, membangun APK debug-signed, mengunggah artifact, dan membuat
  GitHub prerelease untuk pengujian.
- Dependabot memeriksa dependency pub, Gradle, dan GitHub Actions setiap minggu.

Contoh membuat test release:

```bash
git tag v1.0.0-rc.1
git push origin v1.0.0-rc.1
```

Production signing dan distribusi Play Store sengaja belum diaktifkan sampai
Phase 6 menyelesaikan pengelolaan signing secret dan acceptance test.

## Dokumentasi

- [Product Requirements](prd.md)
- [Offline V1 Requirements](docs/REQUIREMENTS.md)
- [Implementation Plan](docs/IMPLEMENTATION_PLAN.md)
- [Phase 1 — Foundation](docs/PHASE_1_FOUNDATION.md)
- [Phase 2 — Finance](docs/PHASE_2_FINANCE.md)
- [Phase 3 — Productivity](docs/PHASE_3_PRODUCTIVITY.md)
- [Phase 4 — Local Assistant](docs/PHASE_4_LOCAL_ASSISTANT.md)
- [Phase 5 — Smart Scan](docs/PHASE_5_SMART_SCAN.md)

## Berkontribusi

Gunakan issue sebagai sumber pekerjaan, buat branch pendek dari `main`, lalu
ajukan pull request. Format branch, commit, issue, dan checklist PR dijelaskan
di [CONTRIBUTING.md](CONTRIBUTING.md).

Laporkan kerentanan melalui petunjuk di [SECURITY.md](SECURITY.md), bukan melalui
issue publik.

## Lisensi

Repository ini public, tetapi lisensi penggunaan ulang belum ditetapkan. Status
public tidak otomatis memberikan izin untuk menyalin atau mendistribusikan kode.
