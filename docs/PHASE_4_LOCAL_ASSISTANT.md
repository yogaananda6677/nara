# Nara V1 — Fase 4 Assistant Lokal

Status: **selesai pada 14 Juli 2026**.

Fase 4 mengganti halaman Asisten `Coming Soon` dengan asisten berbasis aturan
yang berjalan sepenuhnya offline. Tidak ada prompt, chat, atau data pribadi yang
dikirim ke server.

## Kemampuan

Asisten menerima perintah bahasa Indonesia sederhana untuk:

- mencatat pemasukan atau pengeluaran;
- membuat task beserta deadline relatif dan prioritas;
- membuat jadwal dengan tanggal/hari serta jam;
- membaca ringkasan keuangan bulan berjalan;
- membaca task aktif;
- membaca agenda hari ini.

Contoh:

```text
Catat pengeluaran makan siang 25 ribu
Buat task laporan besok sore
Jadwalkan rapat Jumat jam 9
Ringkasan keuangan bulan ini
```

Parser memahami format nominal seperti `25 ribu`, `25rb`, `25.000`, dan
`1,5 juta`, serta waktu relatif `hari ini`, `besok`, `lusa`, nama hari, pagi,
siang, sore, malam, dan `jam 9`.

## Human confirmation

Alur create selalu:

```text
Input → Parse → Validate → Preview → Ubah/Konfirmasi/Batal → Service → Audit
```

- preview diberi label **BELUM DISIMPAN**;
- data belum ditulis saat preview muncul;
- pengguna dapat mengubah nominal/kategori/deskripsi atau judul/prioritas;
- hanya tombol **Konfirmasi** yang mengeksekusi service aplikasi;
- **Batal** membersihkan pending action tanpa perubahan data;
- satu pending action harus diselesaikan sebelum perintah mutation lain.

Query read-only dijalankan langsung karena tidak mengubah data.

## Tool allowlist

Assistant tidak menerima nama tool dinamis dan tidak menjalankan query SQL.
Hanya enam tool terkompilasi berikut yang tersedia:

- `create_transaction`;
- `create_task`;
- `create_schedule`;
- `get_finance_summary`;
- `get_tasks`;
- `get_schedule`.

Dispatcher tetap memakai `FinanceService` dan `ProductivityService`, sehingga
validasi domain Fase 2–3 tidak dilewati.

Instruksi seperti “abaikan konfirmasi”, “tanpa konfirmasi”, “hapus semua”,
“jalankan diam-diam”, dan referensi `system prompt` ditolak serta diaudit.
Input dibatasi maksimal 500 karakter dan perintah ambigu tidak menghasilkan
draft tool.

## Persistence dan audit

Schema database naik ke versi 4 dengan tabel:

- `assistant_conversations`;
- `assistant_messages`.

Riwayat chat disimpan lokal dan dapat dihapus dari UI. Audit tool tetap berada
pada `tool_audits` walaupun chat dihapus, mencakup preview, success, failure,
cancel, serta rejection. Pending action sengaja tidak dipulihkan setelah restart
agar tidak ada mutation tertunda yang bisa berjalan tanpa konteks pengguna.

## UI dan accessibility

- chat bubble membedakan pesan pengguna dan Nara;
- contoh perintah tersedia sebagai action chip;
- composer mendukung hingga empat baris dan 500 karakter;
- preview auto-scroll ke area terlihat dan action menggunakan key/tooltip;
- layout dibatasi maksimal 900 dp agar tetap nyaman di ponsel dan layar lebar;
- status **Lokal • Offline** selalu terlihat.

## Quality gate

- `dart analyze`: **lulus tanpa issue**;
- `flutter test`: **39 test lulus**;
- test mencakup parser nominal/tanggal, input ambigu, safety bypass, schema v4,
  persistence chat, audit, preview/edit/confirm/cancel, serta seluruh regression
  test Fase 1–3.

Debug APK berhasil dibangun, dipasang sebagai update tanpa menghapus data Fase
1–3, dan dijalankan pada Infinix X6882. Main activity terverifikasi aktif
setelah migrasi database v4.

## Batas scope

Asisten ini bukan LLM dan tidak melakukan percakapan bebas atau reasoning
kompleks. Voice, LLM online, dan RAG generatif tetap berada di backlog V2.
Perintah update/delete melalui chat belum diaktifkan pada Fase 4 agar mutation
berisiko tetap dilakukan melalui UI modul masing-masing.
