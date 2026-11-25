# AGENTS.md — Aplikasi Cuaca Flutter (Responsi Flutter)

**Tujuan:** Aplikasi cuaca Flutter (Dart) dengan UI seperti aplikasi cuaca bawaan HP (gradien biru, suhu besar di tengah, kartu transparan). Data cuaca dari **Open-Meteo** (REST, GET, JSON). Pencarian kota lewat **Open-Meteo Geocoding API**. Favorit & riwayat disimpan di **local storage**.

## Aturan wajib (dari soal responsi)

1. Flutter + Dart, Material Design (Material 3), `StatelessWidget`/`StatefulWidget` sesuai kebutuhan.
2. Implementasi `ThemeData` terpusat + `TextTheme` (typography konsisten & terbaca). Layout responsif (tidak overflow di layar kecil, bisa di-scroll).
3. Arsitektur **MVVM** (Model – View – ViewModel). View tidak boleh memanggil HTTP/storage langsung.
4. State management: **Provider** (`ChangeNotifier`).
5. Local storage: **shared_preferences** (favorit, riwayat pencarian, lokasi terakhir). Data harus tampil kembali saat app dibuka ulang.
6. Networking: package `http`, method **GET**, JSON → model Dart (parse manual, `fromJson`).
7. Tangani state **loading, empty, error** (dengan tombol coba lagi).
8. Data cuaca **tidak boleh hardcode**. Pencarian **harus** request ke API.
9. Minimal 2 screen: **Weather Screen** dan **Search Screen**.
10. Bahasa UI: Indonesia. Satuan: °C, km/h, mm, hPa, km.

## Konvensi kode

- Nama file `snake_case.dart`, class `PascalCase`.
- ViewModel **tidak boleh** import `package:flutter/material.dart` (kecuali `foundation.dart` untuk `ChangeNotifier`). Tidak ada `BuildContext` di ViewModel.
- Semua konstanta URL/parameter di `core/constants/api_constants.dart`.
- Beri komentar singkat (bahasa Indonesia) di bagian penting, karena kode harus bisa dijelaskan di video.
- Jangan tambah package di luar daftar tanpa alasan.

**Package:** `http`, `provider`, `shared_preferences`, `intl`.

## Perintah kerja

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
flutter build apk --release
```

## Referensi

- `PLAN.md` — rencana lengkap.
- `docs/reference/soal-responsi.pdf` — soal asli.
- `docs/reference/ui-1.jpg`, `docs/reference/ui-2.jpg` — referensi UI (atas & bawah Weather Screen).
