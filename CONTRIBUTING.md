# Contributing to Nara

Terima kasih sudah membantu Nara. Semua perubahan dimulai dari issue agar scope,
acceptance criteria, dan dampak data lokal dapat ditinjau sebelum implementasi.

## Workflow

1. Cari atau buat issue menggunakan form yang tersedia.
2. Buat branch baru dari `main` yang sudah diperbarui.
3. Implementasikan satu scope yang terukur.
4. Jalankan format, analyze, test, dan build yang relevan.
5. Push branch dan buka pull request menggunakan template.
6. Merge hanya setelah CI lulus dan review selesai.

## Format branch

```text
feature/<nomor-issue>-<deskripsi-singkat>
fix/<nomor-issue>-<deskripsi-singkat>
docs/<nomor-issue>-<deskripsi-singkat>
test/<nomor-issue>-<deskripsi-singkat>
chore/<nomor-issue>-<deskripsi-singkat>
```

Contoh:

```text
feature/12-encrypted-backup
fix/18-smart-scan-total-parser
docs/21-android-setup
```

Gunakan huruf kecil, angka, dan tanda hubung. Hindari branch yang memuat banyak
issue atau perubahan tidak terkait.

## Format commit

Gunakan Conventional Commits:

```text
feat(scan): improve total extraction
fix(finance): prevent duplicate transfer
docs(readme): clarify Android setup
test(backup): cover wrong password
chore(ci): update Flutter action
```

## Pull request

- Hubungkan issue dengan `Closes #<nomor>` jika PR menyelesaikannya.
- Jelaskan perubahan, alasan, dampak pengguna/data, dan cara verifikasi.
- Sertakan screenshot untuk perubahan UI tanpa data pribadi.
- Jangan commit `.env`, API key, keystore, `key.properties`, database pengguna,
  gambar struk nyata, atau build artifact.
- Perubahan schema wajib menaikkan `schemaVersion`, menambahkan migration, dan
  menyertakan migration/repository test.
- Fitur yang menulis data melalui Assistant atau Smart Scan wajib tetap memakai
  preview serta konfirmasi eksplisit.

## Quality gate lokal

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Perubahan native wajib diuji minimal pada emulator. Issue atau PR acceptance V1
yang menyatakan dukungan perangkat nyata harus mencantumkan model perangkat,
versi Android, dan hasil uji tanpa informasi pribadi.
