# PLAN — Aplikasi Cuaca Flutter (Responsi Flutter)

> Dokumen ini adalah rencana kerja untuk dieksekusi bertahap oleh opencode.
> Bagian 0 sebaiknya disalin ke `AGENTS.md` di root project agar selalu terbaca.
> Kerjakan **satu phase per prompt**. Setelah tiap phase, jalankan `flutter analyze` dan `flutter run`, lalu commit.

---

## 0. Konteks & Aturan Proyek (salin ke AGENTS.md)

**Tujuan:** Aplikasi cuaca Flutter (Dart) dengan UI seperti aplikasi cuaca bawaan HP (gradien biru, suhu besar di tengah, kartu transparan). Data cuaca dari **Open-Meteo** (REST, GET, JSON). Pencarian kota lewat **Open-Meteo Geocoding API**. Favorit & riwayat disimpan di **local storage**.

**Aturan wajib (dari soal responsi):**
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

**Konvensi kode:**
- Nama file `snake_case.dart`, class `PascalCase`.
- ViewModel **tidak boleh** import `package:flutter/material.dart` (kecuali `foundation.dart` untuk `ChangeNotifier`). Tidak ada `BuildContext` di ViewModel.
- Semua konstanta URL/parameter di `core/constants/api_constants.dart`.
- Beri komentar singkat (bahasa Indonesia) di bagian penting, karena kode harus bisa dijelaskan di video.
- Jangan tambah package di luar daftar tanpa alasan.

**Package:** `http`, `provider`, `shared_preferences`, `intl`.

---

## 1. Referensi UI (dari screenshot)

Gunakan deskripsi ini sebagai acuan; gambar referensi disimpan di `docs/reference/ui-1.jpg` dan `docs/reference/ui-2.jpg`.

### Weather Screen (satu halaman scroll, background gradien biru)
| # | Elemen | Detail |
|---|---|---|
| 1 | Header | Nama kota kiri atas (putih, ~32sp, medium). Kanan atas: tombol bulat semi-transparan berisi ikon settings. |
| 2 | Hero suhu | Angka suhu sangat besar (~140sp, weight tipis/regular) di tengah, simbol `°` kecil di kanan atas angka (superscript). |
| 3 | Ringkasan | Satu baris di bawah suhu: `{kondisi}  {min}° / {max}°  Kualitas udara: 31 – Baik` (putih, ~18sp). |
| 4 | Kartu jam-per-jam | Kartu putih transparan, sudut 24. Kolom: label waktu (`Sekarang`, `17.00`, …), ikon cuaca, suhu. Jika matahari terbit/terbenam jatuh di rentang itu, sisipkan kolom khusus (mis. `17.44` dengan ikon matahari). Scroll horizontal. |
| 5 | Kartu prakiraan multi-hari | Judul `Prakiraan multi-hari` + toggle segmen `Line` / `List`. Mode Line: tiap hari satu kolom: `Hari ini/Besok/Jum/Sab`, tanggal `25 Nov`, kondisi teks, ikon, peluang hujan `%`, suhu max, **grafik garis** (titik max & min tiap hari), suhu min. Mode List: satu baris per hari. Tombol `Lihat detail` di bawah. |
| 6 | Kartu kualitas udara | `Baik 31`, teks `Kualitas udara cocok untuk aktivitas luar ruangan.`, bar gradien hijau→kuning→merah→ungu→marun dengan penanda posisi nilai. (**Bonus**, lihat Phase 8.) |
| 7 | Grid detail 3 kolom | Tile: `UV`, `Terasa seperti`, `Kelembapan`, `Angin`, `Tekanan udara`, `Jarak pandang`, + `Peluang hujan`, `Curah hujan`, `Matahari terbit/terbenam`. Tiap tile: ikon kecil, label (redup), nilai besar + satuan kecil. |
| 8 | FAB | Tombol bulat kanan bawah (ikon list+) → membuka Search Screen. |

Kartu "Pollen" di screenshot **dilewati** (data pollen Open-Meteo hanya untuk Eropa).

**Gradien background** berdasarkan `weather_code` + `is_day` (dipetakan di `weather_gradients.dart`):
- Cerah siang: `#2D7DD2 → #9ED2FF`
- Hujan / badai: `#2A5CB8 → #8FBCF5` (hujan), `#3B4A6B → #8A9BB8` (badai)
- Berawan: `#5B7BA6 → #B5C7DB`
- Malam: `#0B1A3A → #2E4A7D`

Warna kartu: `Colors.white` dengan alpha ±0.18, tanpa elevation, radius 24. Teks utama putih, teks sekunder putih alpha ±0.6.

### Search Screen
- Gunakan gradien/gaya yang sama agar konsisten.
- Field pencarian membulat di atas (ikon back). Ketik → debounce 500 ms → request geocoding.
- Saat field kosong: tampilkan **Lokasi Favorit** (ikon bintang terisi) dan **Riwayat Pencarian** (tombol hapus semua).
- Saat mengetik: daftar hasil (`nama`, `admin1, negara`), ikon bintang untuk toggle favorit, tap baris → pilih lokasi → kembali ke Weather Screen.
- State: loading (progress indicator), empty (`Kota tidak ditemukan`), error (pesan + `Coba lagi`).

---

## 2. Spesifikasi API (Open-Meteo)

> Tidak perlu API key.

### 2.1 Forecast
`GET https://api.open-meteo.com/v1/forecast`

| Parameter | Nilai |
|---|---|
| `latitude`, `longitude` | dari lokasi terpilih |
| `current` | `temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,surface_pressure,is_day,uv_index,visibility` |
| `hourly` | `temperature_2m,weather_code,precipitation_probability` |
| `daily` | `weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset` |
| `timezone` | `auto` |
| `forecast_days` | `7` |
| `wind_speed_unit` | `kmh` (default) |

Struktur respons: `current{...}`, `hourly{time[], temperature_2m[], ...}`, `daily{time[], ...}`, plus `utc_offset_seconds`, `timezone`. Array `hourly`/`daily` itu **paralel** — gabungkan per indeks menjadi list objek.

### 2.2 Geocoding
`GET https://geocoding-api.open-meteo.com/v1/search?name={q}&count=10&language=id&format=json`

Respons: `results: [{id, name, latitude, longitude, country, admin1, timezone, ...}]`. **Jika tidak ada hasil, key `results` tidak ada sama sekali** (bukan list kosong) → perlakukan sebagai state *empty*.

### 2.3 Air Quality (bonus)
`GET https://air-quality-api.open-meteo.com/v1/air-quality?latitude=..&longitude=..&current=us_aqi&timezone=auto`
Kategori US AQI: 0–50 Baik, 51–100 Sedang, 101–150 Tidak sehat bagi kelompok sensitif, 151–200 Tidak sehat, 201–300 Sangat tidak sehat, 301+ Berbahaya.

### 2.4 Kode cuaca WMO → label & ikon Material
| Kode | Label | Icon |
|---|---|---|
| 0 | Cerah | `wb_sunny` (malam: `nightlight_round`) |
| 1, 2 | Cerah berawan | `wb_cloudy` / `cloud_queue` |
| 3 | Berawan | `cloud` |
| 45, 48 | Berkabut | `foggy` |
| 51, 53, 55, 56, 57 | Gerimis | `grain` |
| 61, 63, 65, 66, 67 | Hujan | `water_drop` / `umbrella` |
| 71, 73, 75, 77, 85, 86 | Salju | `ac_unit` |
| 80, 81, 82 | Hujan lebat/sesaat | `shower` / `water_drop` |
| 95, 96, 99 | Badai petir | `thunderstorm` |

### 2.5 Catatan penting parsing
- Waktu di respons (`2026-11-25T17:00`) **tanpa offset**, sudah dalam zona waktu lokasi. Jangan bandingkan dengan `DateTime.now()` perangkat. Gunakan `current.time` sebagai "sekarang", lalu ambil jam-per-jam yang `>= current.time` (dibulatkan ke jam).
- Nilai bisa `int` atau `double` → selalu `(v as num).toDouble()`.
- Nilai peluang hujan bisa `null` → tipe nullable, tampilkan `-`.
- Respons error Open-Meteo: `{"error": true, "reason": "..."}` dengan status 400.

---

## 3. Struktur Folder (MVVM)

```
lib/
├─ main.dart                      # runApp + MultiProvider (DI)
├─ app.dart                       # MaterialApp + theme
├─ core/
│  ├─ constants/api_constants.dart
│  ├─ theme/app_theme.dart        # ThemeData + TextTheme
│  ├─ theme/weather_gradients.dart
│  ├─ utils/weather_code_mapper.dart   # code → label/icon/gradient
│  ├─ utils/aqi_helper.dart
│  └─ errors/app_exception.dart
├─ data/                          # ===== MODEL layer =====
│  ├─ models/
│  │  ├─ location.dart
│  │  ├─ current_weather.dart
│  │  ├─ hourly_forecast.dart
│  │  ├─ daily_forecast.dart
│  │  ├─ weather_data.dart
│  │  └─ air_quality.dart
│  ├─ services/
│  │  ├─ weather_api_service.dart       # GET forecast (+ AQI)
│  │  ├─ geocoding_api_service.dart     # GET search kota
│  │  └─ local_storage_service.dart     # SharedPreferences
│  └─ repositories/
│     ├─ weather_repository.dart
│     └─ location_repository.dart       # favorit, riwayat, lokasi terakhir
├─ viewmodels/                    # ===== VIEWMODEL layer =====
│  ├─ view_state.dart             # enum ViewState {initial, loading, success, empty, error}
│  ├─ weather_viewmodel.dart
│  ├─ search_viewmodel.dart
│  └─ favorites_viewmodel.dart
└─ views/                         # ===== VIEW layer =====
   ├─ screens/
   │  ├─ weather_screen.dart
   │  └─ search_screen.dart
   └─ widgets/
      ├─ gradient_background.dart
      ├─ glass_card.dart
      ├─ temperature_hero.dart
      ├─ hourly_forecast_card.dart
      ├─ daily_forecast_card.dart     # toggle Line/List
      ├─ temperature_line_chart.dart  # CustomPainter
      ├─ air_quality_card.dart
      ├─ detail_tile.dart
      ├─ loading_view.dart
      ├─ error_view.dart
      └─ empty_view.dart
test/
├─ weather_data_parsing_test.dart
└─ weather_code_mapper_test.dart
docs/
├─ reference/ui-1.jpg, ui-2.jpg
├─ screenshots/…                  # untuk README
└─ DOCUMENTATION.md
```

**Alur data (untuk dijelaskan di video):**
`View` → memanggil method `ViewModel` → `Repository` → `Service` (HTTP / SharedPreferences) → JSON → `Model` → `ViewModel.notifyListeners()` → `Consumer` di View rebuild.

**Dependency injection** (`main.dart`):
```dart
MultiProvider(providers: [
  Provider(create: (_) => LocalStorageService()),
  Provider(create: (_) => WeatherApiService()),
  Provider(create: (_) => GeocodingApiService()),
  ProxyProvider<...>(...) // repositories
  ChangeNotifierProvider(create: (c) => WeatherViewModel(...)),
  ChangeNotifierProvider(create: (c) => SearchViewModel(...)),
  ChangeNotifierProvider(create: (c) => FavoritesViewModel(...)),
], child: const WeatherApp());
```

---

## 4. Peran Tiap ViewModel

**WeatherViewModel**
- State: `ViewState state`, `Location? location`, `WeatherData? weather`, `AirQuality? airQuality`, `String? errorMessage`, `bool showLineChart`.
- Method: `init()` (muat lokasi terakhir dari storage; jika tidak ada pakai default **Jakarta** −6.2146, 106.8451), `selectLocation(Location)` (simpan + fetch), `refresh()`, `retry()`, `toggleChartMode(bool)`.
- Getter turunan: `hourlyItems` (jam-per-jam mulai sekarang + sisipan sunrise/sunset), `todayMin/todayMax`.

**SearchViewModel**
- State: `ViewState state`, `List<Location> results`, `List<Location> history`, `String query`, `String? errorMessage`.
- `onQueryChanged(String)` → debounce `Timer` 500 ms, minimal 2 karakter, abaikan respons usang (simpan token/query terakhir), `search()`, `addToHistory(Location)`, `clearHistory()`, `retry()`.

**FavoritesViewModel**
- `List<Location> favorites`, `isFavorite(Location)`, `toggleFavorite(Location)`, `load()`. Perbandingan lokasi berdasarkan lat/lon.

**Local storage keys** (SharedPreferences, simpan sebagai JSON string): `favorites`, `search_history` (maks 10, tanpa duplikat, terbaru di atas), `last_location`.

---

## 5. Fase Pengerjaan

Setiap fase = satu prompt ke opencode. Di bawah ada **Tujuan**, **Prompt siap salin**, dan **Cek selesai**.

### Phase 0 — Setup (±20 menit)

Manual di terminal:
```bash
flutter create --org com.namamu --platforms android weather_app
cd weather_app
flutter pub add http provider shared_preferences intl
git init && git add . && git commit -m "chore: init flutter project"
mkdir -p docs/reference docs/screenshots
# salin PDF soal + 2 screenshot UI ke docs/reference/
# buat repo di GitHub lalu: git remote add origin ... && git push -u origin main
```
Lalu:
1. Tempel **Bagian 0** dokumen ini ke `AGENTS.md`, dan simpan seluruh dokumen ini sebagai `PLAN.md` di root.
2. Pastikan `android/app/src/main/AndroidManifest.xml` punya (di atas tag `<application>`):
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   ```
   (Tanpa ini, request jalan saat debug tapi **gagal di APK release**.)
3. Verifikasi API dari komputermu (belum bisa diuji sebelum ini):
   ```bash
   curl "https://geocoding-api.open-meteo.com/v1/search?name=Purwokerto&count=3&language=id&format=json"
   curl "https://api.open-meteo.com/v1/forecast?latitude=-7.42&longitude=109.23&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,surface_pressure,is_day,uv_index,visibility&hourly=temperature_2m,weather_code,precipitation_probability&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset&timezone=auto&forecast_days=7"
   ```
   Simpan contoh JSON-nya ke `test/fixtures/forecast.json` untuk unit test.

**Cek selesai:** `flutter run` menampilkan app counter default; repo sudah di GitHub.

---

### Phase 1 — Core: konstanta, tema, mapper
**Prompt:**
> Baca `AGENTS.md` dan `PLAN.md` (bagian 1, 2.4, 3). Kerjakan Phase 1: buat folder struktur `lib/` sesuai bagian 3 (folder kosong boleh dibuat nanti). Implementasikan `core/constants/api_constants.dart` (base URL, path, parameter `current/hourly/daily` sebagai konstanta), `core/errors/app_exception.dart` (class `AppException` dengan `message`), `core/theme/app_theme.dart` (Material 3 `ThemeData` dark-ish dengan `TextTheme` kustom: ukuran besar untuk suhu hero ±140, headline 32, body 16–18, label kecil 12–13, semua putih), `core/theme/weather_gradients.dart` (fungsi `gradientFor(weatherCode, isDay)` sesuai PLAN bagian 1), dan `core/utils/weather_code_mapper.dart` (kode WMO → label Indonesia + `IconData` sesuai tabel 2.4, memperhitungkan `isDay`). Buat `app.dart` dan `main.dart` dengan `MaterialApp` + tema, home sementara `Scaffold` kosong. Jangan buat fitur lain.

**Cek selesai:** `flutter analyze` bersih; unit test sederhana untuk mapper lulus.

---

### Phase 2 — Model + parsing JSON
**Prompt:**
> Kerjakan Phase 2. Buat model di `lib/data/models/` sesuai bagian 3 & 5.x: `Location` (fromGeocodingJson, toJson/fromJson untuk storage, `==` & `hashCode` berdasarkan latitude+longitude, getter `displayName` = "nama, admin1, negara" tanpa bagian null), `CurrentWeather`, `HourlyForecast`, `DailyForecast`, `WeatherData` (factory `fromJson(Map, Location)` yang menggabungkan array paralel `hourly` dan `daily` menjadi list objek; simpan `currentTime` dari `current.time`), dan `AirQuality` (`usAqi` + getter kategori/label). Ikuti catatan parsing di PLAN bagian 2.5 (num→double, nullable, waktu tanpa offset). Buat `test/weather_data_parsing_test.dart` memakai `test/fixtures/forecast.json` untuk memastikan semua field wajib terparse (temperature_2m, relative_humidity_2m, apparent_temperature, precipitation, weather_code, wind_speed_10m, daily max/min, precipitation_probability_max).

**Cek selesai:** `flutter test` lulus.

---

### Phase 3 — Service (HTTP + Local storage)
**Prompt:**
> Kerjakan Phase 3. Buat `WeatherApiService.fetchForecast(lat, lon)` dan `fetchAirQuality(lat, lon)`, `GeocodingApiService.searchCity(String name)` memakai package `http` dengan `Uri.https(...)`, method GET, timeout 10 detik. Kembalikan `Map<String, dynamic>` hasil `jsonDecode` (atau list hasil untuk geocoding; jika key `results` tidak ada, kembalikan list kosong). Bungkus semua kegagalan (SocketException, TimeoutException, http.ClientException, status != 200, body `{"error":true}`) menjadi `AppException` dengan pesan Indonesia yang ramah (mis. "Tidak ada koneksi internet", "Server terlalu lama merespons"). Buat `LocalStorageService` di atas `shared_preferences` dengan method baca/tulis string list/JSON untuk key `favorites`, `search_history`, `last_location`. Service tidak boleh tahu soal model UI/ViewModel.

**Cek selesai:** `flutter analyze` bersih.

---

### Phase 4 — Repository
**Prompt:**
> Kerjakan Phase 4. `WeatherRepository.getWeather(Location)` memanggil service forecast, mengubah JSON menjadi `WeatherData`; `getAirQuality(Location)` mengembalikan `AirQuality?` (jika gagal, kembalikan null — AQI hanya bonus dan tidak boleh menggagalkan layar). `LocationRepository`: `searchCities(String)` → `List<Location>`, `getFavorites/saveFavorites`, `getHistory/addHistory/clearHistory` (maks 10, unik, terbaru di atas), `getLastLocation/saveLastLocation`. Konstruktor menerima service (dependency injection).

---

### Phase 5 — ViewModel + Provider wiring
**Prompt:**
> Kerjakan Phase 5 sesuai PLAN bagian 4. Buat `ViewState` enum, `WeatherViewModel`, `SearchViewModel` (debounce 500 ms, min 2 karakter, abaikan respons usang), `FavoritesViewModel`, semuanya `ChangeNotifier`, tanpa import `material.dart`. Daftarkan semua service/repository/viewmodel di `main.dart` dengan `MultiProvider`. Buat screen sementara yang hanya menampilkan `state`, nama kota, dan suhu saat ini dari `WeatherViewModel` (pakai `Consumer`) untuk membuktikan alur API → ViewModel → View sudah jalan. Panggil `init()` saat app mulai.

**Cek selesai:** Saat `flutter run`, suhu kota default tampil dari API (cek dengan mematikan internet → muncul state error).

---

### Phase 6 — Weather Screen (UI sesuai screenshot)
Pecah menjadi 3 prompt agar hasilnya rapi:

**6a — Kerangka & hero**
> Kerjakan Phase 6a. Buat `weather_screen.dart` (StatelessWidget + `Consumer<WeatherViewModel>`), `gradient_background.dart`, `glass_card.dart`, `temperature_hero.dart`. Layout: `Stack` dengan gradien penuh layar, `SafeArea`, `RefreshIndicator` + `CustomScrollView`. Header (nama kota + tombol settings bulat), suhu hero besar dengan `°` superscript, baris ringkasan `{kondisi} {min}° / {max}°` (+ `Kualitas udara` jika tersedia), FAB kanan bawah (ikon `playlist_add`) yang `Navigator.push` ke `SearchScreen` (buat placeholder). Tangani `loading` (`loading_view`), `error` (`error_view` + tombol Coba lagi), `empty`. Tampilkan juga hero suhu dari state success. Ikuti PLAN bagian 1 untuk ukuran/warna.

**6b — Kartu jam-per-jam & multi-hari**
> Kerjakan Phase 6b. Buat `hourly_forecast_card.dart` (scroll horizontal; item pertama `Sekarang`, label jam format `HH.mm` dengan `intl`; sisipkan item sunrise/sunset jika jatuh dalam rentang), `daily_forecast_card.dart` dengan toggle `Line`/`List` (state di `WeatherViewModel.showLineChart`), `temperature_line_chart.dart` (`CustomPainter`: garis halus + titik untuk suhu max dan suhu min tiap hari, selaras dengan kolom hari di atasnya). Tiap kolom hari: `Hari ini`/`Besok`/nama hari singkat bahasa Indonesia, tanggal `25 Nov`, label kondisi, ikon, peluang hujan %, suhu max, grafik, suhu min. Panggil `initializeDateFormatting('id_ID')` di `main()` sebelum `runApp`.

**6c — Grid detail & kartu AQI**
> Kerjakan Phase 6c. Buat `detail_tile.dart` dan grid 3 kolom (bukan `GridView` yang scrollable di dalam scroll — gunakan `Wrap`/`GridView` `shrinkWrap` + `NeverScrollableScrollPhysics`) berisi 9 tile: UV (beserta label Sangat lemah/Lemah/Sedang/Kuat/Sangat kuat/Ekstrem), Terasa seperti, Kelembapan %, Angin km/h, Tekanan udara hPa, Jarak pandang km (meter/1000), Peluang hujan (daily[0].precipitation_probability_max), Curah hujan mm, Matahari terbit/terbenam. Buat `air_quality_card.dart` (nilai + kategori + bar gradien dengan penanda; sembunyikan kartu jika `airQuality == null`). Pastikan tidak overflow di layar 360dp dan teks skala besar.

**Cek selesai:** Tampilan mendekati screenshot; pull-to-refresh bekerja.

---

### Phase 7 — Search Screen + Favorit + Riwayat
**Prompt:**
> Kerjakan Phase 7 sesuai PLAN bagian 1 (Search Screen). Buat `search_screen.dart` dengan gaya/gradien konsisten. Field pencarian (autofocus) terhubung ke `SearchViewModel.onQueryChanged`. Saat kosong: section "Lokasi Favorit" (dari `FavoritesViewModel`) dan "Riwayat Pencarian" (+ tombol hapus). Saat mengetik: state loading / hasil / empty ("Kota tidak ditemukan") / error (+ Coba lagi). Tiap baris hasil: nama, `admin1, negara`, ikon bintang toggle favorit; tap baris → `SearchViewModel.addToHistory`, `WeatherViewModel.selectLocation`, lalu `Navigator.pop`. Favorit & riwayat harus bertahan setelah app di-restart.

**Cek selesai:** Cari "Purwokerto" → pilih → cuaca berubah sesuai kota; jadikan favorit; tutup app total & buka lagi → lokasi terakhir, favorit, riwayat masih ada.

---

### Phase 8 — Polish
**Prompt:**
> Kerjakan Phase 8: (1) integrasikan AQI bonus end-to-end bila belum; (2) tombol settings: buka bottom sheet sederhana (mis. info aplikasi / segarkan data); (3) transisi halus `AnimatedSwitcher` untuk loading↔konten; (4) gradien berubah sesuai `weather_code` & `is_day` kota terpilih; (5) uji layar kecil (360×640) dan tablet/landscape: tidak ada overflow, konten di-center dengan `ConstrainedBox(maxWidth: 600)` pada layar lebar; (6) `Semantics`/tooltip untuk tombol ikon; (7) rapikan `flutter analyze` sampai 0 warning; (8) hapus kode/komentar mati.

---

### Phase 9 — Pengujian & Checklist Wajib

Checklist (centang sebelum kumpul):
- [ ] Minimal 2 screen (Weather, Search)
- [ ] Weather: nama kota, kondisi, suhu, kelembapan, angin, peluang hujan, prakiraan beberapa hari
- [ ] Search: input, daftar hasil, pilih lokasi, simpan favorit
- [ ] Semua data cuaca dari API (cari `grep` angka/teks hardcode)
- [ ] Pencarian benar-benar request ke API geocoding
- [ ] Loading, empty, error tertangani (tes dengan mode pesawat & nama kota ngawur seperti `zzzqqq`)
- [ ] Favorit/riwayat/lokasi terakhir tersimpan & tampil lagi setelah restart
- [ ] MVVM: View tidak import service/repository; ViewModel tidak import `material.dart`
- [ ] Theme + TextTheme terpusat, tidak ada warna/ukuran font acak tersebar di widget
- [ ] `flutter analyze` 0 issue, `flutter test` lulus
- [ ] `flutter build apk --release` berhasil & data tetap muncul di APK (cek permission INTERNET)

---

### Phase 10 — Dokumen & Pengumpulan

**1. README.md** (root) berisi: deskripsi, fitur, tech stack, cara menjalankan (`flutter pub get`, `flutter run`), struktur folder, dan **screenshot setiap screen** (Weather Screen — loading/sukses/error bila perlu, Search Screen — kosong/hasil/favorit) dari `docs/screenshots/`.

**2. docs/DOCUMENTATION.md** (singkat): 
- Struktur aplikasi (pohon folder + fungsi tiap layer)
- Implementasi API (endpoint, parameter, field yang dipakai, contoh respons, penanganan error)
- Penerapan MVVM (diagram alur View→ViewModel→Repository→Service→Model, contoh satu fitur end-to-end: pencarian kota)
- Local storage (key & format data)
- State management (Provider, kapan `notifyListeners`)

Prompt opencode:
> Buat `README.md` dan `docs/DOCUMENTATION.md` berdasarkan kode aktual di repo ini (jangan mengarang). Sertakan placeholder gambar `docs/screenshots/weather.png`, `search.png`, `favorites.png`. Jelaskan MVVM dengan contoh alur pencarian kota dari `SearchScreen` sampai API.

**3. Video penjelasan kode** (±5–8 menit, rekam layar + suara). Urutan:
1. Demo singkat app (cari kota, favorit, restart app, mode pesawat → error).
2. Struktur folder & mapping MVVM.
3. Ikuti satu alur: ketik kota → `SearchViewModel` → `LocationRepository` → `GeocodingApiService` → JSON → `Location` → UI.
4. `WeatherData.fromJson` (penggabungan array paralel) & `WeatherViewModel` state.
5. Local storage (key, format JSON).
6. Theme/TextTheme & penanganan loading/empty/error.

**4. Pengumpulan:** push ke GitHub (repo publik/akses dosen), tempel link repo + video di **https://forms.gle/vz5LUdPVZmJ2F5uKA**.

⏰ **Batas: 26 November 2026, jam 10.00 pagi.**

---

## 6. Rekomendasi Alokasi Waktu (karena deadline mepet)
| Blok | Phase | Estimasi |
|---|---|---|
| 1 | 0–2 | 45–60 mnt |
| 2 | 3–5 | 60–75 mnt |
| 3 | 6a–6c | 90 mnt |
| 4 | 7 | 45 mnt |
| 5 | 8–9 | 45 mnt |
| 6 | 10 (README, dokumen, video, kumpul) | 60–75 mnt |

Prioritas jika waktu habis: **fitur wajib dulu** (Phase 0–7, kartu hourly/daily sederhana tanpa grafik), baru AQI, grafik garis, dan polish. Grafik garis & AQI adalah bonus, bukan syarat soal.

---

## 7. Persiapan Menjelaskan Kode (syarat nomor 10)
Setelah tiap phase, minta opencode: *"Jelaskan file yang baru dibuat baris per baris dalam bahasa Indonesia sederhana."* Pastikan kamu bisa menjawab:
1. Kenapa dipisah Model/ViewModel/View? Apa yang terjadi saat `notifyListeners()` dipanggil?
2. Kenapa memakai `Consumer`/`context.watch` vs `context.read`?
3. Bagaimana JSON array paralel `daily` diubah jadi list `DailyForecast`?
4. Bagaimana debounce mencegah request berlebih, dan bagaimana respons usang diabaikan?
5. Bagaimana favorit disimpan (key, format JSON) dan dimuat ulang?
6. Di mana loading/empty/error ditangani dan bagaimana UI menampilkannya?
7. Kenapa `results` bisa tidak ada di respons geocoding?

## 8. Jebakan Umum
- Lupa permission `INTERNET` → APK release tidak bisa ambil data.
- `DateTime.now()` dipakai untuk membandingkan waktu API → salah di zona waktu lain; pakai `current.time`.
- `results` null di geocoding → crash `null is not a List`.
- `int` vs `double` dari JSON → `type 'int' is not a subtype of 'double'`; selalu lewat `num`.
- `ListView`/`GridView` di dalam scroll tanpa `shrinkWrap` → error layout tak terbatas.
- `setState`/`notifyListeners` setelah `dispose` (Timer debounce) → batalkan Timer di `dispose()` ViewModel.
- Memanggil `context.read` di `build` untuk data yang berubah → UI tidak update; pakai `watch`/`Consumer`.
