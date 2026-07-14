# Nara V1 — Offline Implementation Plan

Plan ini hanya mencakup V1 offline. Integrasi AI/cloud tidak dikerjakan dalam versi ini.

## Status fase

| Fase | Status |
|---|---|
| Fase 0 — Project baseline | Selesai |
| Fase 1 — Foundation lokal | Selesai |
| Fase 2 — Keuangan | Selesai |
| Fase 3 — Produktivitas | Selesai |
| Fase 4 — Assistant lokal | Selesai |
| Fase 5 — Smart Scan lokal | Selesai |
| Fase 6 — Backup, security, dan hardening | Implementasi selesai; acceptance perangkat berjalan |

## Fase 0 — Project baseline

- rapikan metadata aplikasi dan dokumentasi;
- pasang Riverpod, GoRouter, Drift/SQLite, Intl, dan UUID;
- buat app bootstrap, theme, router, navigation shell, core result/error;
- buat schema database lokal V1;
- pastikan format, analyze, test, dan debug APK lulus.

Exit: starter Nara dapat dibuka sebagai aplikasi offline dan quality gate lulus.

## Fase 1 — Foundation lokal

Status: **selesai pada 14 Juli 2026**. Detail implementasi dan bukti quality
gate tersedia di `docs/PHASE_1_FOUNDATION.md`.

- onboarding dan profil lokal;
- seed kategori awal;
- settings bahasa, Rupiah, `Asia/Jakarta`, dan theme;
- migration dan database test;
- repository contract serta implementation pertama;
- app lock skeleton dan lifecycle handling.

Exit: profile/settings tersimpan setelah aplikasi ditutup dan dibuka kembali.

## Fase 2 — Keuangan

Status: **selesai pada 14 Juli 2026**. Detail implementasi, cara penggunaan,
dan bukti quality gate tersedia di `docs/PHASE_2_FINANCE.md`.

- account dan category CRUD;
- transaction domain model, validation, repository, dan use case;
- form/list/detail transaksi;
- filter, search, monthly summary;
- saving goal dan transfer internal atomic;
- unit, widget, dan integration test.

Exit: seluruh alur keuangan utama berjalan tanpa koneksi.

## Fase 3 — Produktivitas

Status: **selesai pada 14 Juli 2026**. Detail implementasi dan penggunaan
tersedia di `docs/PHASE_3_PRODUCTIVITY.md`.

- task, subtask, priority, deadline, status, recurrence;
- schedule dan agenda harian;
- reminder lokal dan reschedule setelah restart;
- activity log serta ringkasan harian/mingguan;
- integrasi ringkasan ke dashboard.

Exit: task, agenda, reminder, dan aktivitas berfungsi offline di Android.

## Fase 4 — Assistant lokal

Status: **selesai pada 14 Juli 2026**. Detail arsitektur, perintah yang
didukung, dan safety guarantee tersedia di `docs/PHASE_4_LOCAL_ASSISTANT.md`.

- intent dan entity parser berbasis aturan;
- tool schema, allowlist, validator, dispatcher, dan audit log;
- perintah lokal untuk transaksi, task, dan schedule;
- preview, edit, konfirmasi, cancel, dan error state;
- test input ambigu, invalid, serta konfirmasi ditolak.

Exit: perintah umum dapat diproses tanpa model/API dan tidak pernah menyimpan tanpa konfirmasi.

## Fase 5 — Smart Scan lokal

Status: **selesai pada 14 Juli 2026**. Detail arsitektur, privasi, penggunaan,
dan quality gate tersedia di `docs/PHASE_5_SMART_SCAN.md`.

- spike kamera/gallery, OCR, dan klasifikasi lokal pada Android;
- preprocessing dan document classifier;
- normalizer/parser struk;
- draft transaksi yang dapat diedit;
- permission, low-confidence, dan failure state;
- fixture anonim dan latency test.

Exit: gambar diproses lokal dan hanya draft terkonfirmasi yang masuk database.

## Fase 6 — Backup, security, dan hardening

Status: **implementasi selesai pada 14 Juli 2026**. Detail rancangan keamanan,
recovery, penggunaan, serta bukti quality gate tersedia di
`docs/PHASE_6_SECURITY_HARDENING.md`. Acceptance pada perangkat nyata tetap
dicatat terpisah sebelum V1 diberi tag final.

- backup/restore lokal terenkripsi;
- PIN hash dan biometrik sistem;
- migration rehearsal dan corruption recovery;
- accessibility, empty/error states, serta performance profiling;
- acceptance test seluruh flow V1 pada perangkat nyata.

Exit: seluruh acceptance criteria offline V1 dan Definition of Done terpenuhi.

## Increment pertama (selesai)

`Transaction` value object → repository contract → Drift implementation →
service/use case → form/list UI → tests. Pola ini sudah diterapkan pada Fase 2
dan menjadi template untuk feature berikutnya.

## Backlog V2 (tidak dikerjakan sekarang)

- LLM gateway;
- online chat;
- RAG;
- cloud sync;
- multi-device;
- voice online;
- local LLM.
