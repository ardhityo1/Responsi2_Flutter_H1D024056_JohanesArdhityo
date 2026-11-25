# Dokumentasi Aplikasi Cuaca

Dokumen ini menjelaskan implementasi aktual aplikasi: arsitektur MVVM, integrasi Open-Meteo, penyimpanan lokal, state management, dan pengujian.

## 1. Ringkasan

Aplikasi memiliki dua layar utama:

1. **Weather Screen** (`lib/views/screens/weather_screen.dart`) — menampilkan cuaca saat ini, ringkasan suhu + AQI, prakiraan per jam, prakiraan 7 hari (grafik garis/daftar), kartu kualitas udara, dan 9 tile detail.
2. **Search Screen** (`lib/views/screens/search_screen.dart`) — pencarian kota via API, daftar favorit, dan riwayat pencarian.

Data berasal dari Open-Meteo dan disimpan sebagian di perangkat:

- Cuaca saat ini, per jam, dan harian: `api.open-meteo.com/v1/forecast`
- Pencarian kota: `geocoding-api.open-meteo.com/v1/search`
- Kualitas udara (bonus): `air-quality-api.open-meteo.com/v1/air-quality`
- Favorit, riwayat, lokasi terakhir: `shared_preferences`

## 2. Struktur dan Peran Layer

```
lib/
├─ main.dart                  # WidgetsFlutterBinding, intl, SharedPreferences, MultiProvider
├─ app.dart                   # MaterialApp + AppTheme
├─ core/
│  ├─ constants/api_constants.dart      # host, path, field, timeout, jumlah hari
│  ├─ constants/app_constants.dart      # nama app, kota default, key storage, limit
│  ├─ errors/app_exception.dart         # error dengan pesan siap tampil
│  ├─ theme/app_theme.dart              # ThemeData, TextTheme, warna kaca
│  ├─ theme/weather_gradients.dart      # gradien berdasarkan kode cuaca + is_day
│  ├─ utils/weather_code_mapper.dart    # kode WMO → label Indonesia + ikon
│  ├─ utils/aqi_helper.dart             # kategori, deskripsi, warna, posisi AQI
│  └─ utils/json_parser.dart            # konversi aman num/string/DateTime
├─ data/                                # ===== MODEL / DATA LAYER =====
│  ├─ models/
│  │  ├─ location.dart                  # data kota + displayName + JSON storage
│  │  ├─ current_weather.dart
│  │  ├─ hourly_forecast.dart
│  │  ├─ daily_forecast.dart
│  │  ├─ weather_data.dart              # gabungan current/hourly/daily
│  │  └─ air_quality.dart
│  ├─ services/
│  │  ├─ api_client.dart                # GET + timeout + error handling
│  │  ├─ weather_api_service.dart       # forecast + air quality
│  │  ├─ geocoding_api_service.dart     # pencarian kota
│  │  └─ local_storage_service.dart     # pembungkus SharedPreferences
│  └─ repositories/
│     ├─ weather_repository.dart        # JSON → WeatherData / AirQuality
│     └─ location_repository.dart       # pencarian + favorit + riwayat + lokasi terakhir
├─ viewmodels/                          # ===== VIEWMODEL LAYER =====
│  ├─ view_state.dart                   # initial, loading, success, empty, error
│  ├─ weather_viewmodel.dart
│  ├─ search_viewmodel.dart
│  └─ favorites_viewmodel.dart
└─ views/                               # ===== VIEW LAYER =====
   ├─ screens/weather_screen.dart
   ├─ screens/search_screen.dart
   └─ widgets/…                         # kartu, grafik, tile, loading/error/empty
```

Aturan yang dijaga:

- View hanya membaca state dari ViewModel dan memanggil method ViewModel. View tidak memanggil service HTTP atau `SharedPreferences` secara langsung.
- ViewModel hanya mengimpor `package:flutter/foundation.dart` (untuk `ChangeNotifier`), tidak mengimpor `material.dart`, dan tidak menyimpan `BuildContext`.
- Service mengetahui HTTP/storage; repository mengubah data mentah menjadi model; ViewModel mengatur state; View merender.

## 3. Alur Data (contoh: mencari kota)

1. Pengguna membuka Search Screen dari FAB Weather Screen.
2. `TextField.onChanged` memanggil `SearchViewModel.onQueryChanged(value)`.
3. ViewModel membatalkan timer sebelumnya, menaikkan `_requestToken`, dan memulai debounce 500 ms. Jika query < 2 karakter, hasil dikosongkan dan state kembali `initial`.
4. Setelah debounce, `_search(query)` memanggil `LocationRepository.searchCities(query)`.
5. Repository memanggil `GeocodingApiService.searchCity(query)`.
6. Service membentuk `Uri.https(...)` dan memanggil `ApiClient.getJson(uri)` (GET, timeout 10 detik).
7. `ApiClient` men-decode JSON dan menerjemahkan kegagalan menjadi `AppException` berbahasa Indonesia.
8. Hasil `results` (atau list kosong jika key tidak ada) dipetakan menjadi `Location` lewat `Location.fromGeocodingJson`.
9. ViewModel memeriksa token: jika pengguna sudah mengetik query lain, respons lama diabaikan. Jika valid, `results` diisi dan `notifyListeners()` dipanggil.
10. `Consumer2<SearchViewModel, FavoritesViewModel>` di View membangun ulang daftar hasil.
11. Saat baris dipilih: `addToHistory(location)` → `WeatherViewModel.selectLocation(location)` → `Navigator.pop()`.
12. `selectLocation` menyimpan lokasi terakhir, mengosongkan data lama, set state `loading`, lalu mengambil forecast + AQI. Setelah selesai, `notifyListeners()` membuat Weather Screen menampilkan kota baru.

Alur singkat:

```
View → ViewModel → Repository → Service (HTTP / SharedPreferences)
     ← notifyListeners() ← model hasil parsing ← JSON
```

## 4. Integrasi API

Semua host, path, nama field, jumlah hari, dan timeout berada di `lib/core/constants/api_constants.dart`.

### 4.1 Forecast

```
GET https://api.open-meteo.com/v1/forecast
```

Parameter yang dipakai:

| Parameter | Nilai |
|---|---|
| `latitude`, `longitude` | koordinat lokasi terpilih |
| `current` | `temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,surface_pressure,is_day,uv_index,visibility` |
| `hourly` | `temperature_2m,weather_code,precipitation_probability` |
| `daily` | `weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset` |
| `timezone` | `auto` |
| `forecast_days` | `7` |
| `wind_speed_unit` | `kmh` |

`WeatherData.fromJson` menggabungkan array paralel `hourly.time[i]`, `hourly.temperature_2m[i]`, dan seterusnya menjadi `List<HourlyForecast>`; hal yang sama dilakukan untuk `daily`. Waktu dari API tidak memiliki offset dan sudah dalam zona waktu lokasi, sehingga aplikasi memakai `current.time` sebagai acuan "sekarang", bukan `DateTime.now()` perangkat.

### 4.2 Geocoding

```
GET https://geocoding-api.open-meteo.com/v1/search?name={query}&count=10&language=id&format=json
```

Jika tidak ada kecocokan, Open-Meteo **tidak mengirim key `results`**. Service mengembalikan list kosong, lalu ViewModel mengubah state menjadi `empty` dan UI menampilkan "Kota tidak ditemukan".

### 4.3 Kualitas udara (bonus)

```
GET https://air-quality-api.open-meteo.com/v1/air-quality?latitude=…&longitude=…&current=us_aqi&timezone=auto
```

`WeatherRepository.getAirQuality` menangkap semua kegagalan dan mengembalikan `null`. Dengan begitu, kartu AQI hanya disembunyikan dan kegagalan AQI tidak menggagalkan Weather Screen.

### 4.4 Penanganan error

`ApiClient` memetakan:

- Timeout → "Server terlalu lama merespons. Silakan coba lagi."
- `http.ClientException` → "Tidak dapat terhubung ke server. Periksa koneksi internet."
- Status non-200 → pesan `reason` dari Open-Meteo bila ada, atau status HTTP.
- Body `{"error": true}` → pesan `reason`.
- JSON tidak valid → "Format respons server tidak valid."

Semua error dibungkus `AppException` agar View hanya menampilkan `errorMessage` yang ramah.

## 5. State Management

Semua ViewModel adalah `ChangeNotifier` dan didaftarkan di `main.dart` melalui `MultiProvider`.

### WeatherViewModel

- State: `ViewState`, `Location?`, `WeatherData?`, `AirQuality?`, `errorMessage`, `showLineChart`.
- `init()` membaca lokasi terakhir; jika belum ada, memakai Jakarta sebagai fallback (bukan data cuaca hardcode).
- `selectLocation()` menyimpan lokasi, set loading, lalu memuat forecast dan AQI.
- `refresh()` mempertahankan data lama saat gagal (pull-to-refresh tidak mengosongkan layar).
- Getter `hourlyItems` mengambil 24 jam mulai jam `current.time`, menyisipkan `sunrise`/`sunset` jika jatuh dalam rentang, lalu menandai item pertama sebagai "Sekarang".
- `toggleChartMode()` mengganti mode Garis/Daftar dan memanggil `notifyListeners()`.

### SearchViewModel

- Debounce 500 ms dan minimal 2 karakter.
- `_requestToken` mencegah respons lama menimpa hasil query terbaru.
- `loadHistory()`, `addToHistory()`, dan `clearHistory()` berkomunikasi dengan repository.
- `reset()` mengosongkan query/hasil saat Search Screen dibuka lagi, sehingga hasil pencarian sesi sebelumnya tidak muncul saat field masih kosong. Dipanggil dari `initState` dengan `notify: false` karena layar belum dibangun.
- Timer dibatalkan di `dispose()`; `notifyListeners()` tidak dipanggil setelah ViewModel di-dispose.

### FavoritesViewModel

- Memuat daftar favorit dari storage.
- `isFavorite()` membandingkan lokasi berdasarkan latitude + longitude (implementasi `==` di `Location`).
- `toggleFavorite()` langsung memperbarui list di memori, menyimpan ke storage, lalu `notifyListeners()`.

`notifyListeners()` dipanggil setiap kali state/data berubah. View memakai `Consumer`/`Consumer2` agar hanya bagian yang bergantung pada ViewModel tersebut yang dibangun ulang.

## 6. Local Storage

`LocalStorageService` membungkus `SharedPreferences`. Repository menyimpan data sebagai **string JSON**.

| Key | Format | Keterangan |
|---|---|---|
| `favorites` | JSON array objek `Location` | Daftar kota favorit, terbaru di atas. |
| `search_history` | JSON array objek `Location` | Maksimal 10, tanpa duplikat koordinat, terbaru di atas. |
| `last_location` | JSON objek `Location` | Dipakai `WeatherViewModel.init()` saat aplikasi dibuka. |

Contoh objek lokasi:

```json
{
  "id": 123,
  "name": "Kota Purwokerto",
  "latitude": -7.42139,
  "longitude": 109.23444,
  "country": "Indonesia",
  "admin1": "Jawa Tengah",
  "timezone": "Asia/Jakarta"
}
```

Saat aplikasi dibuka ulang: `WeatherViewModel.init()` membaca `last_location`, `FavoritesViewModel.load()` membaca `favorites`, dan `SearchViewModel.loadHistory()` membaca `search_history`.

## 7. Tampilan, Tema, dan Responsivitas

- `AppTheme.theme` memusatkan `ThemeData` Material 3, `TextTheme`, warna teks, input, snackbar, bottom sheet, dan tombol. Ukuran suhu hero, headline, body, dan label didefinisikan di satu tempat.
- Warna kartu: putih dengan alpha 0.18, border putih alpha 0.14, radius 24, tanpa elevation (efek "kaca").
- `WeatherGradients.forCode(code, isDay)` memetakan kondisi cuaca + siang/malam ke gradien. Malam selalu memakai gradien gelap.
- `GradientBackground` menambahkan beberapa lingkaran radial lembut agar latar tidak datar.
- Konten Weather Screen dibatasi `ConstrainedBox(maxWidth: 620)` dan di-center pada layar lebar; padding halaman 16.
- Kartu jam-per-jam dan grafik 7 hari memakai scroll horizontal, sehingga tidak memaksa lebar layar.
- Grid detail memakai `Wrap` 3 kolom dengan lebar tile dihitung dari `LayoutBuilder`, bukan `GridView` scrollable di dalam scroll.
- Layout telah diperiksa pada 360×640, 390×844, dan tablet; tidak ada overflow dan konten tetap bisa di-scroll.

## 8. State Loading / Empty / Error

| Layar | Loading | Empty | Error |
|---|---|---|---|
| Weather | `LoadingView` selama forecast pertama dimuat | `EmptyView` jika data tidak tersedia | `ErrorView` + tombol **Coba lagi** |
| Search | `LoadingView` saat debounce/request | "Kota tidak ditemukan" / minimal 2 karakter | `ErrorView` + **Coba lagi** |

Saat pull-to-refresh gagal dan data lama masih ada, data lama tetap ditampilkan agar pengguna tidak kehilangan konteks.

## 9. Pengujian dan Verifikasi

Perintah:

```bash
flutter analyze
flutter test
```

Test yang tersedia:

- `test/weather_data_parsing_test.dart` — parsing lokasi, cuaca saat ini, array hourly/daily paralel, timezone, dan AQI memakai fixture JSON asli di `test/fixtures/`.
- `test/weather_code_mapper_test.dart` — label/ikon kode WMO, gradien siang/malam, kategori dan deskripsi AQI.
- `test/search_viewmodel_test.dart` — penyimpanan favorit/lokasi terakhir, riwayat unik maksimal 10 dengan urutan terbaru, `reset()` pencarian, dan regression test yang memastikan Search Screen menampilkan riwayat (bukan query lama) saat dibuka kembali.
- `test/weather_viewmodel_test.dart` — fallback lokasi Jakarta vs `last_location`, susunan `hourlyItems` beserta sisipan sunset, ketahanan saat AQI gagal, pertahanan data saat `refresh()` gagal, dan persistensi `FavoritesViewModel`.

Verifikasi manual yang sudah dilakukan (web build, viewport 390×844):

1. Cari "Purwokerto" → daftar hasil muncul dari API.
2. Pilih "Kota Purwokerto" → Weather Screen berubah dan gradien malam dipakai.
3. Reload aplikasi → lokasi terakhir tetap Purwokerto.
4. Buka pencarian → riwayat berisi Purwokerto.
5. Tandai favorit → reload → favorit tetap tersimpan dan tampil.
6. Buka pencarian lagi tanpa reload → tampil riwayat, bukan hasil query sebelumnya.
7. Cari "zzzqqq" → state kosong "Kota tidak ditemukan".
8. Mode offline → pilih kota → muncul error koneksi dan tombol **Coba lagi**; setelah online, tombol tersebut memuat data kembali.
9. Layout 360×640 dan tablet tidak overflow; pengaturan, detail 7 hari, dan mode Daftar berfungsi.

## 10. Poin yang Perlu Dijelaskan Saat Video

- **Kenapa MVVM?** View fokus pada tampilan, ViewModel mengatur state dan aturan UI, repository/service menangani data. Perubahan data cukup lewat `notifyListeners()`.
- **`Consumer` vs `context.read`:** `Consumer`/`watch` dipakai untuk data yang berubah dan perlu rebuild; `read` dipakai untuk memanggil aksi (mis. tombol).
- **Array paralel:** `daily.time[i]`, `daily.temperature_2m_max[i]`, dst. digabung per indeks menjadi `DailyForecast`.
- **Debounce & respons usang:** timer 500 ms mengurangi request; token memastikan hanya respons untuk query terakhir yang dipakai.
- **Persistence:** favorit/riwayat/lokasi disimpan sebagai JSON string di `SharedPreferences`, lalu diparse kembali saat aplikasi dibuka.
- **Tanpa hardcode:** suhu, kondisi, prakiraan, dan hasil pencarian selalu berasal dari respons API; Jakarta hanya fallback koordinat awal.
