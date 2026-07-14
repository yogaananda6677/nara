# Fase 5 — Smart Scan Lokal

Status: **selesai pada 14 Juli 2026**.

Fase ini menambahkan alur scan struk dan bukti transfer yang berjalan offline
di Android. Pengguna dapat mengambil foto melalui kamera atau memilih gambar
dari galeri, memeriksa hasil ekstraksi, mengedit draft, lalu mengonfirmasi
transaksi ke modul Keuangan.

## Hasil implementasi

- akses Smart Scan dari Dashboard dan halaman Keuangan;
- pengambilan gambar dari kamera/galeri serta recovery ketika Android menutup
  activity pemilih gambar;
- preprocessing lokal: koreksi orientasi, resize maksimum 1.800 px, grayscale,
  contrast, dan file kerja sementara;
- OCR Latin menggunakan Google ML Kit yang dijalankan native di perangkat;
- classifier V1 deterministik untuk `struk`, `bukti transfer`, dan
  `non-financial` berdasarkan sinyal teks OCR;
- parser lokal untuk nominal, tanggal, merchant/penerima, saran kategori,
  confidence, dan warning;
- draft responsif yang dapat diedit sebelum disimpan;
- state kamera/galeri gagal, OCR kosong, dokumen tidak dikenali, confidence
  rendah, processing, cancel, dan sukses;
- metadata audit scan pada schema database versi 5 serta relasi `scanId` pada
  transaksi yang dikonfirmasi.

Classifier V1 belum memakai MobileNet/TFLite karena project belum memiliki
dataset dan model klasifikasi dokumen yang tervalidasi. Implementasi rule-based
memberikan perilaku deterministik dan mudah diuji untuk scope offline V1. Model
terlatih dapat menggantikannya di versi berikutnya tanpa mengubah kontrak UI
atau service.

## Alur data dan privasi

1. Gambar dipilih dan diproses di storage sementara aplikasi.
2. OCR, klasifikasi, dan parsing berjalan lokal di perangkat.
3. Database hanya menerima metadata audit berstatus `pending`; gambar dan teks
   OCR mentah tidak disimpan ke database.
4. Pengguna memeriksa dan dapat mengubah seluruh field draft.
5. Transaksi dibuat hanya setelah tombol **Simpan transaksi** ditekan.
6. Scan ditandai `confirmed` dan transaksi menyimpan `source=smart_scan` serta
   `scanId`. Konfirmasi kedua untuk scan yang sama ditolak.
7. File hasil preprocessing dihapus setelah pipeline selesai. Cancel tidak
   membuat transaksi.

Tidak ada backend, upload gambar, API OCR cloud, analytics cloud, atau AI API
pada alur ini.

## Cara menggunakan

1. Pastikan minimal satu akun tersedia di menu Keuangan.
2. Buka Dashboard lalu pilih **Smart Scan**, atau gunakan tombol Smart Scan di
   halaman Keuangan.
3. Pilih **Kamera** atau **Galeri**.
4. Pastikan dokumen terlihat utuh, terang, sejajar, dan tidak buram.
5. Periksa tipe transaksi, nominal, merchant, akun, kategori, dan tanggal.
6. Jika confidence rendah atau ada warning, koreksi field secara manual.
7. Tekan **Simpan transaksi** untuk menulis ke ledger Keuangan, atau **Batal**
   untuk membuang draft.

## Batasan V1

- OCR dioptimalkan untuk teks Latin dan format nominal/tanggal Indonesia;
- tulisan tangan, gambar sangat buram, refleksi, atau layout tidak umum dapat
  memerlukan koreksi manual;
- klasifikasi berasal dari teks OCR, bukan model vision terlatih;
- Smart Scan hanya menghasilkan draft transaksi Keuangan dan belum mengekstrak
  rincian tiap item belanja.

## Quality gate

- `dart analyze`: lulus tanpa issue;
- `flutter test`: **48/48 test lulus**;
- fixture anonim mencakup struk, bukti transfer, dan dokumen non-financial;
- classifier dan parser lokal diuji 200 iterasi di bawah batas 500 ms;
- repository test memastikan database tidak menyimpan image path atau OCR text;
- service dan widget test memastikan tidak ada transaksi sebelum konfirmasi,
  konfirmasi hanya sekali, dan OCR kosong tidak menulis transaksi;
- debug APK terbaru berhasil dipasang sebagai update (`adb install -r`) pada
  Infinix X6882 agar data aplikasi lama tetap dipertahankan.

## Exit criteria

Gambar diproses lokal, hasil selalu ditampilkan sebagai draft yang dapat
diedit, dan hanya draft terkonfirmasi yang masuk ke database Keuangan. Dengan
exit criteria ini terpenuhi, pekerjaan berikutnya berpindah ke Fase 6: backup,
security, dan hardening.
