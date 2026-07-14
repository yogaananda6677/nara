# Security Policy

## Supported version

Nara masih berada pada pengembangan V1. Hanya branch `main` terbaru yang
menerima perbaikan keamanan.

## Melaporkan kerentanan

Jangan membuat issue publik untuk kerentanan, credential yang bocor, atau data
pribadi. Gunakan **GitHub Security Advisories** pada repository ini:

`Security` → `Advisories` → `Report a vulnerability`

Sertakan versi/commit, langkah reproduksi minimal, dampak, dan saran mitigasi
jika ada. Jangan sertakan database, screenshot, struk, nominal, atau informasi
pribadi pengguna nyata.

## Data sensitif

Repository tidak boleh memuat API key, signing keystore, password, PIN,
biometric material, backup pengguna, database SQLite pengguna, atau gambar OCR
nyata. Gunakan fixture anonim untuk test.
