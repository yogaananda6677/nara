# Fase 6 — Backup, Security, dan Hardening

Tanggal implementasi: 14 Juli 2026
Target: Nara V1 offline, Android API 24+

## Hasil

Fase 6 menutup placeholder keamanan V1 dan menambahkan jalur recovery lokal.
Semua operasi tetap offline; Nara tidak menambahkan backend, analytics, HTTP
client, atau penyimpanan cloud.

## Backup dan restore

- Menu tersedia di **Pengaturan → Backup lokal**.
- Pemilihan lokasi memakai Android Storage Access Framework melalui document
  picker sistem, tanpa izin akses seluruh penyimpanan.
- File menggunakan ekstensi `.nara` dan berisi snapshot logis database.
- Payload dienkripsi AES-256-GCM. Kunci diturunkan dari password minimal delapan
  karakter dengan PBKDF2-HMAC-SHA256, salt acak, dan 210.000 iterasi.
- Header hanya memuat versi format, parameter KDF, nonce, MAC, dan ciphertext.
- Seluruh row divalidasi sebelum transaksi restore dimulai.
- Restore menghapus dan memasukkan data dalam satu transaksi Drift. Error,
  foreign-key failure, atau integrity failure melakukan rollback otomatis.
- Backup dari schema lebih baru ditolak agar data tidak ditafsirkan secara
  salah.

PIN hash, salt PIN, jumlah percobaan gagal, status biometrik, dan timeout lock
tidak diekspor. Sesudah restore, app lock selalu nonaktif dan pengguna perlu
mengaturnya kembali. Ini mencegah backup lama mengunci pemilik data dari app.

Password backup tidak disimpan. Kehilangan password berarti file tidak dapat
dipulihkan; tidak ada recovery cloud pada V1.

## PIN, biometrik, dan lifecycle

- PIN wajib tepat enam digit.
- Database hanya menyimpan hasil PBKDF2-HMAC-SHA256 256-bit, salt acak, dan
  parameter KDF; PIN asli tidak disimpan.
- Setelah lima kesalahan, verifikasi ditunda 30 detik. Jeda meningkat pada
  kelompok kegagalan berikutnya sampai batas aman.
- Biometrik memakai prompt sistem Android melalui `local_auth`, dengan PIN
  sebagai fallback.
- Pengguna dapat memilih lock langsung, 30 detik, satu menit, atau lima menit
  setelah app masuk background.
- Cold start terkunci apabila app lock aktif.
- Android OS cloud backup dinonaktifkan untuk mencegah penyalinan database di
  luar mekanisme backup terenkripsi Nara.

## Migration dan recovery

Schema database naik dari v5 ke v6. Migration hanya menambah tabel
`security_credentials`, sehingga data Fase 1–5 tidak ditulis ulang. Setiap
backup dan akhir restore menjalankan `PRAGMA quick_check`. Restore memakai
snapshot logis, bukan penggantian file SQLite mentah, agar schema dan constraint
versi aplikasi tetap menjadi sumber kebenaran.

Jika file salah, password salah, autentikasi ciphertext gagal, struktur row
rusak, atau backup berasal dari schema lebih baru, restore dihentikan dan data
aktif tidak berubah.

## Accessibility dan usability

- Layar lock memakai label semantik untuk status terkunci.
- Pesan PIN/biometrik menggunakan live region agar perubahan dibaca screen
  reader.
- Setiap tindakan keamanan memiliki label teks, tidak hanya ikon.
- Pengaturan menggunakan list yang dapat di-scroll dan diuji pada text scale
  200% di viewport 360 × 800.
- Operasi backup/restore menampilkan progress dan hasil yang eksplisit.

## Cara menguji pada ponsel

1. Buka **Pengaturan → Keamanan**, aktifkan kunci aplikasi dan buat PIN.
2. Aktifkan biometrik, pindahkan Nara ke background melewati timeout, lalu buka
   dengan biometrik dan ulangi dengan PIN.
3. Masukkan PIN salah lima kali dan pastikan jeda 30 detik muncul.
4. Buat data uji, pilih **Buat backup terenkripsi**, lalu simpan file `.nara`.
5. Ubah data, pilih **Pulihkan dari backup**, dan masukkan password yang benar.
6. Pastikan data kembali dan app lock nonaktif.
7. Ulangi restore dengan password salah; pastikan data aktif tidak berubah.
8. Jalankan alur keuangan, task, jadwal/reminder, asisten, dan Smart Scan tanpa
   koneksi internet.

## Quality gate

Perintah wajib:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Test Fase 6 mencakup hash/validasi PIN, throttling kegagalan, round-trip
enkripsi, penolakan password/file rusak, exclusion kredensial, atomic restore,
integrity check, serta UI pada text scale 200%. Acceptance perangkat nyata
harus dicatat sebelum tag V1 final dibuat.
