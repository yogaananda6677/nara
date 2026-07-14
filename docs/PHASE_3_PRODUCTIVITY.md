# Nara V1 — Fase 3 Produktivitas

Status: **selesai pada 14 Juli 2026**.

Fase 3 mengganti placeholder Task dan Jadwal dengan modul produktivitas offline
yang terhubung ke Drift/SQLite dan dashboard.

## Task

- tambah, edit, hapus, cari, filter, dan tandai selesai;
- prioritas rendah, sedang, dan tinggi;
- status belum mulai, dikerjakan, dan selesai;
- deskripsi, kategori, deadline, serta subtask;
- pengulangan harian, mingguan, atau bulanan;
- reminder lokal; reminder task selesai otomatis dibatalkan;
- penghapusan task utama turut membersihkan subtask dan reminder terkait.

## Jadwal dan aktivitas

- agenda per hari dengan waktu mulai/selesai, lokasi, dan catatan;
- navigasi hari sebelumnya/berikutnya;
- jadwal berulang dan reminder sebelum acara;
- log aktivitas berisi kategori, mulai/selesai, durasi otomatis, catatan, dan
  mood opsional;
- layout satu kolom pada ponsel dan dua kolom pada layar mulai 760 dp.

## Reminder Android

Reminder menggunakan notifikasi lokal dan tidak memerlukan internet. Jadwal
notifikasi disimpan oleh Android, dipulihkan setelah reboot atau aplikasi
diperbarui, dan memakai timezone `Asia/Jakarta`. Izin notifikasi baru diminta
saat pengguna pertama kali menyimpan reminder.

Penjadwalan memakai mode inexact agar tidak meminta izin exact alarm yang lebih
sensitif. Pada perangkat dengan pembatasan baterai agresif, pengguna mungkin
perlu mengizinkan Nara berjalan di latar belakang melalui pengaturan sistem.

## Database dan migrasi

Schema naik ke versi 3 dengan penambahan `category` pada tabel `tasks`. Data
Fase 1 dan Fase 2 tetap dipertahankan oleh migrasi berurutan:

- v1 → v2: progress target tabungan;
- v2 → v3: kategori task.

Tabel Task, Jadwal, Activity Log, dan Reminder yang telah tersedia pada baseline
kini digunakan melalui repository dan service Fase 3.

## Dashboard

Dashboard menampilkan jumlah task aktif, jumlah jadwal hari ini, total menit
aktivitas hari ini, dan reminder berikutnya berdasarkan data lokal nyata.

## Quality gate

- `dart analyze`: **lulus tanpa issue**;
- `flutter test`: **27 test lulus**;
- test meliputi schema v3, repository Task/Jadwal/Aktivitas, reminder persisten,
  validasi service, penjadwalan reminder, pembuatan task melalui UI, dan seluruh
  regression test Fase 1–2 serta viewport responsif.

Debug APK telah dipasang sebagai update tanpa menghapus data lama dan berhasil
dijalankan pada Infinix X6882. Main activity terverifikasi aktif setelah migrasi
database v3.

## Batas scope

Tidak ada sinkronisasi kalender eksternal atau cloud. Pengulangan pada V1
menjadwalkan reminder berulang dan menyimpan aturan pada item; aplikasi tidak
membuat salinan item baru. Semua data tetap berada di perangkat.
