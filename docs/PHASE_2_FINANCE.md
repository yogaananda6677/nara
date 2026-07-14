# Nara V1 — Fase 2 Keuangan

Status: **selesai pada 14 Juli 2026**.

Fase 2 menghadirkan alur keuangan utama yang sepenuhnya offline sekaligus
merombak dashboard agar lebih mudah dipahami, responsif, dan nyaman digunakan
di ponsel maupun layar lebar.

## Fitur yang tersedia

- CRUD akun kas, bank, dan e-wallet dengan saldo awal;
- CRUD kategori pemasukan dan pengeluaran;
- pencatatan, edit, dan hapus transaksi pemasukan/pengeluaran;
- transfer antarakun dalam satu transaksi database atomik;
- pencarian transaksi, filter pemasukan/pengeluaran, dan navigasi bulan;
- total saldo serta ringkasan pemasukan dan pengeluaran bulanan;
- target tabungan, jumlah terkumpul, progres, akun terkait, dan target tanggal;
- pengarsipan akun yang sudah mempunyai histori agar ledger tetap aman;
- data tetap disimpan lokal melalui Drift/SQLite tanpa API atau internet.

## Perubahan desain dan usability

- warna merah tetap menjadi identitas dominan Nara dengan Material 3;
- dashboard menampilkan ringkasan keuangan nyata dan akses utama ke Keuangan,
  Jadwal, serta Task;
- ponsel menggunakan bottom navigation, sedangkan layar mulai 800 dp memakai
  navigation rail;
- halaman Keuangan berubah menjadi dua kolom mulai 840 dp dan satu kolom pada
  layar kecil;
- form tampil sebagai bottom sheet di ponsel dan dialog terbatas lebarnya di
  layar lebar;
- empty, loading, error, konfirmasi hapus, validasi input, tooltip, semantics,
  dan refresh state tersedia pada alur utama;
- nominal dan judul transaksi ditata agar tidak overflow pada layar sempit.

Menu Asisten tetap ditampilkan di navigasi dengan status **Coming Soon** sesuai
scope V1 offline saat ini.

## Model data dan konsistensi

Schema database naik dari versi 1 ke versi 2. Kolom `saved_amount` ditambahkan
ke `saving_goals`; migrasi mengisi data lama dari `initial_amount` sehingga
progress yang sudah ada tetap terbaca.

Saldo akun dihitung dari saldo awal dan ledger transaksi. Transfer disimpan
sebagai dua entry berpasangan—keluar dan masuk—di dalam satu database
transaction. Riwayat hanya menampilkan sisi keluar agar satu transfer tidak
tampak dua kali, sementara kedua entry tetap digunakan dalam perhitungan saldo.

## Cara menggunakan

1. Buka tab **Keuangan**, lalu tekan ikon tambah akun.
2. Buat minimal satu akun untuk mencatat transaksi; dua akun diperlukan untuk
   transfer.
3. Gunakan tombol **Transaksi** untuk mencatat pemasukan atau pengeluaran.
4. Gunakan quick action **Kategori**, **Transfer**, atau **Tabungan** untuk
   alur terkait.
5. Gunakan panah bulan, kolom pencarian, dan filter pada bagian riwayat.

Seluruh langkah dapat digunakan tanpa koneksi internet.

## Arsitektur

- `domain`: entity serta kontrak repository;
- `application`: validasi dan service/use case;
- `data`: implementasi repository Drift dan operasi atomik;
- `presentation`: Riverpod controller, halaman responsif, dan form reusable.

## Quality gate

Pada penyelesaian fase:

- `dart analyze`: **lulus tanpa issue**;
- `flutter test`: **20 test lulus**;
- cakupan test mencakup schema v2, persistence foundation, perhitungan ledger,
  ringkasan bulanan, transfer atomik, progress tabungan, validasi service,
  onboarding/settings, navigasi, pembuatan akun melalui UI, serta layout pada
  viewport ponsel 390 dp dan layar lebar 1200 dp.

Debug APK berhasil dibangun, dipasang sebagai update tanpa menghapus data lama,
dan dijalankan pada perangkat Infinix X6882.

## Batas scope

Fase ini tidak menambahkan backend, sinkronisasi cloud, LLM, RAG, maupun API
online. Jadwal dan Task baru mempunyai entry point dashboard; implementasi
penuhnya dikerjakan pada Fase 3.
