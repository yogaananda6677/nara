# PRODUCT REQUIREMENTS DOCUMENT (PRD)

## AI Personal Assistant untuk Keuangan dan Produktivitas

> **Scope implementasi aktif — V1 Offline:** seluruh data dan pemrosesan V1
> berjalan di perangkat. Bagian yang membahas LLM API, RAG online, cloud, dan
> layanan AI online adalah visi/backlog V2 dan bukan acceptance criteria V1.
> Baseline teknis aktif ada di `docs/REQUIREMENTS.md` dan urutan pengerjaan ada
> di `docs/IMPLEMENTATION_PLAN.md`.

## 1. Informasi Dokumen

| Atribut | Nilai |
|---|---|
| Nama Produk Sementara | Nara Personal Assistant |
| Jenis Produk | Aplikasi mobile asisten personal |
| Platform Utama | Android |
| Pendekatan Sistem | Offline-only pada V1; hybrid AI ditunda ke V2 |
| Fokus Utama | Keuangan pribadi, to-do list, jadwal, log aktivitas, dan asisten AI |
| Mode Interaksi | Teks, suara, formulir manual, dan pemindaian dokumen |
| Teknologi Utama | Flutter, Riverpod, Drift/SQLite, TensorFlow Lite, ML Kit OCR, local notification |
| Arsitektur Assistant V1 | Local Command Parser, Intent Routing, Tool Calling Lokal |
| Status Dokumen | Baseline Implementasi V1 Offline |
| Versi | 1.0 |
| Tujuan Dokumen | Menjadi dasar pengajuan, pengembangan, dan planning untuk AI coding agent |

## 2. Ringkasan Produk

Nara Personal Assistant adalah aplikasi mobile yang membantu pengguna mengelola aktivitas pribadi melalui satu aplikasi terintegrasi.

Aplikasi mencakup:

- pengelolaan keuangan pribadi;
- pencatatan pemasukan dan pengeluaran;
- target tabungan;
- to-do list;
- jadwal;
- reminder;
- log aktivitas;
- pencatatan transaksi melalui Smart Scan;
- perintah berbasis suara;
- percakapan dengan AI;
- analisis data pengguna melalui RAG;
- eksekusi perintah melalui tool calling.

Aplikasi dirancang dengan pendekatan **offline-first**. Fitur inti seperti keuangan, to-do list, jadwal, reminder, log aktivitas, OCR, dan penyimpanan data dapat digunakan tanpa internet. Fitur AI generatif yang memerlukan penalaran kompleks, percakapan bebas, rangkuman, rekomendasi, dan analisis data menggunakan layanan online ketika tersedia.

Ketika perangkat tidak terhubung ke internet, pengguna tetap dapat menggunakan fitur inti dan perintah sederhana melalui local command parser.

## 3. Latar Belakang

Pengguna sering menggunakan beberapa aplikasi terpisah untuk mengatur kebutuhan pribadi, seperti aplikasi pencatat keuangan, to-do list, kalender, reminder, notes, habit tracker, dan chatbot AI. Pemisahan tersebut menyebabkan data tersebar, pengguna harus berpindah aplikasi, dan sulit memperoleh ringkasan menyeluruh mengenai keuangan, tugas, jadwal, dan aktivitas.

Sebagian besar asisten AI juga belum terintegrasi langsung dengan data pribadi pengguna secara aman. AI biasanya hanya menjawab pertanyaan, tetapi tidak mampu mengelola tugas, transaksi, jadwal, atau log aktivitas pengguna secara terstruktur.

Selain itu, penggunaan layanan cloud secara penuh menimbulkan beberapa masalah:

- aplikasi tidak dapat digunakan ketika offline;
- data pribadi bergantung pada server;
- biaya API dapat meningkat;
- privasi pengguna menjadi perhatian;
- akses terhadap data tidak selalu tersedia.

Nara dikembangkan sebagai asisten personal hybrid yang memadukan fitur offline dengan AI online secara terkontrol.

## 4. Permasalahan

1. Pengguna menggunakan banyak aplikasi terpisah untuk mengelola keuangan dan aktivitas.
2. Pencatatan transaksi, tugas, dan aktivitas masih banyak dilakukan secara manual.
3. Pengguna sering lupa mencatat pengeluaran atau menyelesaikan tugas.
4. Informasi pribadi pengguna belum dapat dianalisis secara terpadu.
5. Asisten AI biasa belum memiliki akses aman terhadap data terstruktur pengguna.
6. Aplikasi berbasis cloud tidak dapat digunakan sepenuhnya tanpa internet.
7. Pengguna membutuhkan interaksi yang lebih cepat melalui suara dan bahasa natural.
8. Data keuangan dan aktivitas bersifat sensitif sehingga perlu dikontrol penggunaannya.

## 5. Tujuan Produk

### 5.1 Tujuan Utama

Mengembangkan aplikasi asisten personal berbasis mobile yang membantu pengguna mengelola keuangan, tugas, jadwal, dan aktivitas melalui interaksi manual, teks, suara, Smart Scan, serta AI.

### 5.2 Tujuan Teknis

- Membangun aplikasi menggunakan arsitektur modular.
- Menyediakan fungsi utama yang tetap berjalan tanpa internet.
- Menjalankan OCR dan klasifikasi gambar secara lokal.
- Menyimpan data pengguna secara lokal.
- Menggunakan tool calling untuk menjalankan perintah.
- Menggunakan RAG untuk menjawab berdasarkan data pengguna.
- Menggunakan AI online hanya untuk fungsi yang memerlukan pemahaman dan penalaran kompleks.
- Mencegah AI mengubah data tanpa konfirmasi.
- Menjaga privasi dan keamanan data pengguna.
- Memungkinkan pengembangan local LLM pada versi lanjutan.

## 6. Visi Produk

Menjadi aplikasi asisten personal yang membantu pengguna mengelola kehidupan sehari-hari melalui satu antarmuka yang sederhana, kontekstual, aman, dan dapat digunakan dalam kondisi online maupun offline.

## 7. Nilai Utama Produk

### 7.1 Terintegrasi
Keuangan, tugas, jadwal, reminder, dan aktivitas berada dalam satu aplikasi.

### 7.2 Offline-First
Fitur inti tetap tersedia tanpa internet.

### 7.3 AI-Assisted
AI membantu memahami perintah, menyusun ringkasan, dan memberikan rekomendasi.

### 7.4 User-Controlled
Setiap perubahan penting harus dikonfirmasi pengguna.

### 7.5 Privacy-Oriented
Data utama disimpan secara lokal dan hanya data relevan yang dikirim ke AI.

### 7.6 Multi-Modal
Pengguna dapat berinteraksi melalui teks, suara, form manual, kamera, dan galeri.

## 8. Target Pengguna

### 8.1 Pengguna Utama

- mahasiswa;
- pelajar;
- pekerja;
- freelancer;
- pelaku usaha kecil;
- ibu rumah tangga;
- pengguna umum yang ingin meningkatkan produktivitas.

### 8.2 Karakteristik Pengguna

- menggunakan smartphone Android;
- memiliki banyak aktivitas;
- sering lupa mencatat transaksi;
- membutuhkan pengingat;
- ingin mengelola tugas dan jadwal;
- ingin berinteraksi melalui suara;
- membutuhkan aplikasi yang tetap dapat digunakan tanpa internet;
- memperhatikan privasi data pribadi.

### 8.3 Persona Pengguna

#### Persona 1 — Mahasiswa
Kebutuhan: mencatat pengeluaran, mengatur jadwal kuliah, menyimpan tugas, mencatat kegiatan, dan meminta AI membuat ringkasan aktivitas.

#### Persona 2 — Pekerja
Kebutuhan: mengatur agenda, mencatat tugas, memantau keuangan, membuat reminder, dan meminta AI menyusun prioritas.

#### Persona 3 — Freelancer
Kebutuhan: mencatat pemasukan, mengatur deadline, melacak aktivitas kerja, mengelola pembayaran, dan membuat laporan ringkas.

## 9. Ruang Lingkup Produk

### 9.1 Dalam Lingkup MVP

#### Modul Dasar
- onboarding;
- profil lokal;
- PIN atau biometrik;
- pengaturan aplikasi;
- penyimpanan lokal;
- backup dan restore lokal.

#### Modul Keuangan
- akun keuangan;
- pemasukan;
- pengeluaran;
- kategori;
- target tabungan;
- riwayat transaksi;
- laporan bulanan;
- pencarian transaksi;
- Smart Scan struk;
- Smart Scan bukti transfer;
- OCR lokal;
- klasifikasi dokumen lokal.

#### Modul Produktivitas
- to-do list;
- prioritas;
- deadline;
- status tugas;
- reminder;
- jadwal;
- aktivitas berulang;
- agenda harian;
- pencarian tugas.

#### Modul Log Aktivitas
- catatan aktivitas;
- waktu mulai;
- waktu selesai;
- kategori aktivitas;
- deskripsi;
- ringkasan harian;
- ringkasan mingguan.

#### Modul Asisten
- chat teks;
- voice input;
- text-to-speech;
- intent routing;
- tool calling;
- RAG;
- local command parser;
- konfirmasi tindakan;
- riwayat percakapan lokal.

### 9.2 Di Luar Lingkup MVP

- transfer uang;
- pembayaran otomatis;
- integrasi rekening bank resmi;
- integrasi DANA, OVO, GoPay, atau e-wallet;
- akses OTP;
- scraping aplikasi keuangan;
- always-listening wake word;
- sinkronisasi multi-device;
- AI yang mengubah data tanpa konfirmasi;
- local LLM penuh;
- integrasi wearable;
- dukungan desktop;
- integrasi kalender eksternal.

## 10. Pembagian Fitur Online dan Offline

### 10.1 Fitur Offline

- tambah, edit, dan hapus transaksi;
- kategori keuangan;
- target tabungan;
- laporan dasar;
- OCR;
- klasifikasi gambar;
- Smart Scan;
- to-do list;
- jadwal;
- reminder;
- log aktivitas;
- pencarian lokal;
- local command parser;
- speech-to-text lokal jika tersedia;
- text-to-speech lokal;
- backup lokal.

### 10.2 Fitur Online — Backlog V2

Tidak ada fitur online yang menjadi bagian implementasi atau acceptance criteria
V1. Daftar berikut dipertahankan sebagai arah pengembangan V2:

- percakapan AI bebas;
- pemahaman bahasa natural kompleks;
- analisis pola aktivitas;
- rekomendasi keuangan;
- rangkuman mingguan;
- perencanaan tugas;
- pembuatan agenda otomatis;
- natural language query;
- reasoning lintas modul;
- RAG dengan LLM online.

### 10.3 Mode Degradasi

Ketika internet tidak tersedia:

- chat AI online dinonaktifkan;
- pengguna tetap dapat menggunakan perintah sederhana;
- aplikasi menampilkan status mode offline;
- data tetap tersimpan lokal;
- tidak ada fungsi inti yang hilang.

## 11. Fitur Utama

### 11.1 Dashboard

Dashboard menampilkan:

- saldo total;
- pemasukan bulan ini;
- pengeluaran bulan ini;
- tugas aktif;
- jadwal hari ini;
- reminder berikutnya;
- aktivitas terbaru;
- progres tabungan;
- shortcut Smart Scan;
- shortcut voice assistant.

### 11.2 Keuangan

- tambah akun;
- tambah transaksi;
- pilih kategori;
- transfer antar akun;
- target tabungan;
- laporan;
- filter;
- pencarian;
- Smart Scan.

### 11.3 To-Do List

- judul tugas;
- deskripsi;
- prioritas;
- deadline;
- status;
- kategori;
- subtugas;
- reminder;
- tugas berulang.

### 11.4 Jadwal

- judul kegiatan;
- tanggal;
- waktu mulai;
- waktu selesai;
- lokasi;
- catatan;
- reminder;
- agenda berulang.

### 11.5 Log Aktivitas

- aktivitas;
- kategori;
- durasi;
- catatan;
- mood opsional;
- ringkasan harian;
- statistik sederhana.

### 11.6 Asisten Chat

Pengguna dapat membuat transaksi, membuat tugas, membuat jadwal, mencatat aktivitas, bertanya tentang data, meminta rangkuman, meminta rekomendasi, dan mengubah data setelah konfirmasi.

### 11.7 Voice Assistant

```text
Tekan tombol mikrofon
        ↓
Speech-to-Text
        ↓
Intent Router
        ↓
Tool Calling atau RAG
        ↓
Konfirmasi
        ↓
Eksekusi
        ↓
Text-to-Speech
```

## 12. Contoh Perintah Pengguna

### 12.1 Perintah Keuangan

> Catat pengeluaran makan siang 25 ribu.

```json
{
  "tool": "create_transaction",
  "arguments": {
    "type": "expense",
    "amount": 25000,
    "category": "Makanan",
    "description": "Makan siang"
  }
}
```

### 12.2 Perintah Tugas

> Tambahkan tugas menyelesaikan laporan PKL besok sore.

```json
{
  "tool": "create_task",
  "arguments": {
    "title": "Menyelesaikan laporan PKL",
    "due_date": "tomorrow",
    "time_period": "afternoon"
  }
}
```

### 12.3 Perintah Jadwal

> Jadwalkan rapat hari Jumat jam 9.

```json
{
  "tool": "create_schedule",
  "arguments": {
    "title": "Rapat",
    "date": "next_friday",
    "time": "09:00"
  }
}
```

### 12.4 Pertanyaan RAG

> Kenapa pengeluaran saya bulan ini meningkat?

Sistem mengambil total pengeluaran, bulan sebelumnya, kategori terbesar, transaksi tidak biasa, dan frekuensi transaksi. Data relevan kemudian dikirim ke LLM untuk menghasilkan jawaban.

## 13. Arsitektur Sistem

### 13.1 Prinsip Arsitektur

- Clean Architecture;
- feature-first;
- offline-first;
- repository pattern;
- dependency inversion;
- modular AI services;
- tool-based execution;
- local data ownership;
- unidirectional data flow;
- human confirmation;
- privacy by design.

### 13.2 Diagram Tingkat Tinggi

```text
┌─────────────────────────────────────────────────────┐
│                 Flutter Mobile Application          │
├─────────────────────────────────────────────────────┤
│ Presentation Layer                                  │
│ Pages, Widgets, Providers, State                    │
├─────────────────────────────────────────────────────┤
│ Application Layer                                   │
│ Use Cases, Intent Router, Tool Dispatcher           │
├─────────────────────────────────────────────────────┤
│ Domain Layer                                        │
│ Entities, Rules, Repository Contracts               │
├─────────────────────────────────────────────────────┤
│ Data Layer                                          │
│ Repository Implementations, Data Sources            │
├──────────────────────┬──────────────────────────────┤
│ AI Layer             │ Local Storage Layer          │
│ LLM Client           │ Drift / SQLite               │
│ RAG Service          │ Secure Storage               │
│ Tool Calling         │ Local Files                  │
│ Voice Services       │ Preferences                  │
│ OCR / Classifier     │ Backup                       │
└──────────────────────┴──────────────────────────────┘
```

## 14. Arsitektur AI

### 14.1 Intent Router

Intent Router menentukan jenis permintaan:

```text
Command
Question
Analysis
Conversation
Unknown
```

- **Command**: membuat atau mengubah data.
- **Question**: mengambil informasi langsung.
- **Analysis**: menganalisis dan merangkum data.
- **Conversation**: percakapan umum yang tidak mengubah data.

## 15. Arsitektur Tool Calling

### 15.1 Prinsip

AI tidak mengakses database secara langsung. AI hanya menghasilkan perintah terstruktur. Aplikasi kemudian:

1. memvalidasi tool;
2. memvalidasi argument;
3. menampilkan preview;
4. meminta konfirmasi;
5. menjalankan use case;
6. mengembalikan hasil ke AI.

### 15.2 Tool Minimum

```text
create_transaction
update_transaction
delete_transaction
get_finance_summary
create_task
update_task
complete_task
delete_task
get_tasks
create_schedule
update_schedule
delete_schedule
get_schedule
create_activity_log
update_activity_log
delete_activity_log
get_activity_summary
create_saving_goal
update_saving_goal
get_saving_progress
```

### 15.3 Tool Safety

Setiap tool harus memiliki schema, validation, permission, confirmation, audit log, dan error handling.

## 16. Arsitektur RAG

### 16.1 Fungsi RAG

RAG digunakan untuk menjawab pertanyaan berdasarkan data pengguna.

Sumber data:

- transaksi;
- kategori;
- tabungan;
- tugas;
- jadwal;
- log aktivitas;
- catatan;
- riwayat percakapan yang diizinkan.

### 16.2 Retrieval Terstruktur

Data numerik dan tanggal diambil menggunakan query database.

```sql
SELECT category_id, SUM(amount)
FROM transactions
WHERE transaction_date BETWEEN ? AND ?
GROUP BY category_id;
```

### 16.3 Retrieval Semantik

Digunakan untuk catatan aktivitas, deskripsi tugas, jurnal, dan catatan panjang. MVP tidak wajib menggunakan vector database. Tahap awal dapat memakai keyword search, full-text search, filter tanggal, dan ranking sederhana.

### 16.4 Alur RAG

```text
User Question
      ↓
Intent Router
      ↓
Retrieval Planner
      ↓
Local Database Query
      ↓
Context Builder
      ↓
Privacy Filter
      ↓
LLM
      ↓
Answer
```

## 17. Arsitektur Smart Scan

```text
Camera / Gallery
      ↓
Image Preprocessing
      ↓
MobileNetV3 TFLite
      ↓
Receipt / Transfer / Non-Financial
      ↓
ML Kit OCR
      ↓
Text Normalization
      ↓
Receipt / Transfer Parser
      ↓
Draft Transaction
      ↓
User Confirmation
      ↓
Local Database
```

Kelas klasifikasi:

```text
receipt
transfer_proof
non_financial
```

Data ekstraksi:

- merchant;
- nominal;
- tanggal;
- jenis transaksi;
- kategori;
- nomor referensi;
- sumber transaksi.

## 18. Model Domain

### 18.1 UserProfile

```text
id
name
preferredLanguage
timezone
assistantName
createdAt
updatedAt
```

### 18.2 Transaction

```text
id
accountId
categoryId
type
amount
date
merchant
description
source
scanId
createdAt
updatedAt
```

### 18.3 Task

```text
id
title
description
priority
status
dueDate
reminderAt
repeatRule
createdAt
updatedAt
```

### 18.4 Schedule

```text
id
title
description
startAt
endAt
location
reminderAt
repeatRule
createdAt
updatedAt
```

### 18.5 ActivityLog

```text
id
title
category
startAt
endAt
duration
notes
mood
createdAt
updatedAt
```

### 18.6 AssistantConversation

```text
id
title
createdAt
updatedAt
```

### 18.7 AssistantMessage

```text
id
conversationId
role
content
intent
toolName
createdAt
```

## 19. Struktur Folder

```text
lib/
├── app/
│   ├── app.dart
│   ├── bootstrap.dart
│   ├── router/
│   ├── theme/
│   └── config/
├── core/
│   ├── errors/
│   ├── result/
│   ├── validators/
│   ├── security/
│   ├── permissions/
│   └── utils/
├── database/
│   ├── app_database.dart
│   ├── tables/
│   ├── daos/
│   └── migrations/
├── ai/
│   ├── assistant/
│   ├── intent_router/
│   ├── tools/
│   ├── rag/
│   ├── privacy/
│   ├── llm/
│   ├── voice/
│   ├── ocr/
│   └── classifier/
├── features/
│   ├── onboarding/
│   ├── dashboard/
│   ├── finance/
│   ├── tasks/
│   ├── schedules/
│   ├── activities/
│   ├── savings/
│   ├── scan/
│   ├── assistant/
│   ├── reports/
│   └── settings/
└── shared/
    ├── widgets/
    ├── providers/
    └── models/
```

## 20. Functional Requirements

- **FR-001 Dashboard:** sistem menampilkan ringkasan keuangan, tugas, jadwal, aktivitas, dan tabungan.
- **FR-002 Keuangan:** sistem mendukung CRUD transaksi, kategori, akun, dan tabungan.
- **FR-003 Smart Scan:** sistem mengklasifikasikan gambar dan menghasilkan draft transaksi.
- **FR-004 To-Do:** sistem mendukung tugas, deadline, prioritas, status, dan reminder.
- **FR-005 Jadwal:** sistem mendukung agenda, waktu, lokasi, dan reminder.
- **FR-006 Aktivitas:** sistem mendukung pencatatan aktivitas dan ringkasan.
- **FR-007 Voice:** sistem menerima input suara dan mengubahnya menjadi teks.
- **FR-008 Tool Calling:** sistem mengubah perintah menjadi tool terstruktur.
- **FR-009 RAG:** sistem menjawab berdasarkan data pengguna yang relevan.
- **FR-010 Konfirmasi:** sistem meminta konfirmasi sebelum tindakan penting.
- **FR-011 Offline Mode:** sistem tetap menyediakan fitur inti tanpa internet.

## 21. Non-Functional Requirements

### NFR-001 Privasi

- data utama disimpan lokal;
- data sensitif tidak dikirim tanpa persetujuan;
- konteks AI harus diminimalkan;
- nomor rekening dapat dimasking;
- gambar tidak dikirim ke AI.

### NFR-002 Keamanan

- PIN disimpan dalam bentuk hash;
- biometric menggunakan API sistem;
- tidak ada secret dalam source code;
- komunikasi AI menggunakan HTTPS;
- tool tidak boleh mengeksekusi query mentah.

### NFR-003 Kinerja

Target:

- dashboard kurang dari 1 detik;
- CRUD kurang dari 500 ms;
- klasifikasi kurang dari 2 detik;
- OCR kurang dari 5 detik;
- tool execution kurang dari 2 detik setelah konfirmasi.

### NFR-004 Reliability

- transaksi database atomic;
- reminder tetap aktif setelah restart;
- tidak ada perubahan tanpa konfirmasi;
- aplikasi memiliki fallback offline.

### NFR-005 Maintainability

- business logic tidak berada di UI;
- repository contract berada di domain;
- AI provider dapat diganti;
- tool modular;
- setiap feature independen.

## 22. Privacy Filter

Sebelum data dikirim ke AI:

1. pilih data relevan;
2. hapus field yang tidak dibutuhkan;
3. masking nomor rekening;
4. masking identifier;
5. ringkas transaksi;
6. minta persetujuan pengguna jika data sensitif;
7. jangan kirim gambar;
8. jangan kirim seluruh database.

Contoh konteks aman:

```json
{
  "period": "July 2026",
  "total_expense": 1850000,
  "top_categories": [
    {
      "name": "Makanan",
      "amount": 720000
    }
  ]
}
```

## 23. Error Handling

Kategori error:

- ValidationFailure;
- DatabaseFailure;
- NetworkFailure;
- LlmFailure;
- ToolFailure;
- RagFailure;
- VoiceFailure;
- PermissionFailure;
- OcrFailure;
- ClassificationFailure;
- SchedulingFailure.

Setiap error harus memiliki pesan pengguna, detail teknis, kode error, kemungkinan retry, dan fallback.

## 24. Testing Strategy

### 24.1 Unit Test

- parser transaksi;
- intent router;
- tool validator;
- retrieval planner;
- finance calculation;
- task status;
- schedule validation;
- activity summary;
- privacy filter.

### 24.2 Widget Test

- form transaksi;
- task form;
- schedule form;
- assistant chat;
- confirmation dialog;
- offline state;
- error state.

### 24.3 Integration Test

1. membuat transaksi manual;
2. membuat transaksi melalui suara;
3. membuat tugas melalui chat;
4. membuat jadwal melalui AI;
5. scan struk;
6. bertanya tentang pengeluaran;
7. bertanya tentang tugas;
8. mode offline;
9. AI gagal;
10. pengguna menolak konfirmasi.

### 24.4 Security Test

- tool injection;
- prompt injection;
- invalid JSON;
- data leakage;
- unauthorized action;
- malformed model output.

## 25. Acceptance Criteria MVP

V1 dinyatakan selesai apabila:

- aplikasi dapat digunakan tanpa internet;
- transaksi manual berfungsi;
- to-do list berfungsi;
- jadwal dan reminder berfungsi;
- log aktivitas berfungsi;
- Smart Scan menghasilkan draft;
- local command parser berfungsi tanpa jaringan;
- tool calling lokal berfungsi;
- ringkasan dan pencarian lokal dapat menjawab berdasarkan data terstruktur;
- seluruh tindakan penting memerlukan konfirmasi;
- data sensitif tidak dikirim tanpa filter;
- aplikasi tidak crash pada alur utama;
- test utama lulus.

## 26. Roadmap

### Fase 1 — Foundation
- setup proyek;
- Clean Architecture;
- database;
- router;
- theme;
- security.

### Fase 2 — Keuangan
- akun;
- transaksi;
- kategori;
- tabungan;
- laporan.

### Fase 3 — Produktivitas
- to-do;
- jadwal;
- reminder;
- aktivitas.

### Fase 4 — Smart Scan
- kamera;
- classifier;
- OCR;
- parser;
- confirmation.

### Fase 5 — Assistant Core
- chat;
- intent router;
- local command parser;
- tool registry;
- tool dispatcher.

### Backlog V2 — AI Online (bukan bagian V1)
- LLM client;
- prompt management;
- structured output;
- voice;
- TTS.

### Backlog V2 — RAG (bukan bagian V1)
- retrieval planner;
- SQL retrieval;
- context builder;
- privacy filter;
- response generation.

### Fase 8 — Quality
- testing;
- optimization;
- security;
- documentation;
- evaluation.

## 27. Prioritas untuk AI Coding Agent

AI coding agent harus:

1. membaca PRD lengkap;
2. membuat implementation plan;
3. mengerjakan satu fase per waktu;
4. membuat domain model sebelum UI;
5. membuat repository contract;
6. menulis migration;
7. membuat test;
8. tidak mengakses database langsung dari UI;
9. tidak memberikan LLM akses langsung ke database;
10. tidak mengeksekusi tool tanpa validasi;
11. tidak menyimpan perubahan tanpa konfirmasi;
12. menjaga fitur offline tetap berjalan;
13. mendokumentasikan keputusan.

## 28. Definition of Done

Fitur dianggap selesai apabila:

- sesuai requirement;
- memiliki validasi;
- memiliki error state;
- memiliki test;
- tidak memiliki lint error;
- aman untuk data pengguna;
- bekerja offline bila termasuk fitur inti;
- terdokumentasi;
- tidak mengubah scope;
- telah diuji pada perangkat nyata.

## 29. Risiko dan Mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Scope terlalu luas | Proyek tidak selesai | Implementasi bertahap |
| AI salah memahami | Data salah | Konfirmasi wajib |
| RAG mengambil data salah | Jawaban tidak akurat | Retrieval terstruktur |
| Data bocor | Risiko privasi | Privacy filter |
| Internet tidak tersedia | AI tidak bekerja | Local command parser |
| OCR salah | Transaksi salah | Review pengguna |
| Model lambat | UX buruk | Model ringan |
| API mahal | Biaya meningkat | Limit dan caching |
| Prompt injection | Tool berbahaya | Tool allowlist |
| Reminder gagal | Tugas terlewat | Alarm lokal dan testing |

## 30. Saran Judul Pengajuan

### Judul Utama

**Pengembangan Aplikasi Asisten Personal Berbasis Hybrid AI untuk Pengelolaan Keuangan dan Produktivitas Menggunakan Tool Calling dan Retrieval-Augmented Generation**

### Alternatif

**Pengembangan Aplikasi Asisten Personal Offline-First dengan Fitur Voice Command, Smart Scan, dan Retrieval-Augmented Generation**

### Alternatif Lebih Ringkas

**Pengembangan Asisten Personal Mobile untuk Pengelolaan Keuangan, Tugas, Jadwal, dan Aktivitas Berbasis Hybrid AI**

## 31. Ringkasan Arsitektur Final

```text
Text / Voice / Scan / Manual Input
                ↓
          Intent Router
                ↓
    ┌───────────┴───────────┐
    │                       │
Local Command            Online AI
    │                       │
    └───────────┬───────────┘
                ↓
       Tool Calling / RAG
                ↓
       Validation & Privacy
                ↓
       User Confirmation
                ↓
Finance / Task / Schedule / Activity
                ↓
         Local Database
```

Produk ini diposisikan sebagai asisten personal hybrid yang tetap berguna tanpa internet dan menjadi lebih cerdas ketika layanan AI tersedia.
