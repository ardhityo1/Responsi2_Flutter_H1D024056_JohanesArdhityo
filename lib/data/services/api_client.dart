import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exception.dart';

/// Pembungkus HTTP GET yang menerjemahkan kegagalan teknis menjadi
/// pesan berbahasa Indonesia yang bisa ditampilkan di UI.
class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> getJson(Uri uri) async {
    try {
      final response = await _client
          .get(uri)
          .timeout(ApiConstants.requestTimeout);

      Map<String, dynamic>? decoded;
      try {
        final value = jsonDecode(response.body);
        if (value is Map<String, dynamic>) decoded = value;
      } on FormatException {
        decoded = null;
      }

      if (response.statusCode != 200) {
        final reason = decoded?['reason'];
        if (reason is String && reason.isNotEmpty) {
          throw AppException('Permintaan gagal: $reason');
        }
        throw AppException(
          'Server mengembalikan status ${response.statusCode}.',
        );
      }

      if (decoded == null) {
        throw const AppException('Respons server tidak dapat dibaca.');
      }

      if (decoded['error'] == true) {
        final reason = decoded['reason'];
        throw AppException(
          reason is String && reason.isNotEmpty
              ? 'Permintaan gagal: $reason'
              : 'Permintaan ke server gagal.',
        );
      }

      return decoded;
    } on AppException {
      rethrow;
    } on TimeoutException {
      throw const AppException(
        'Server terlalu lama merespons. Silakan coba lagi.',
      );
    } on http.ClientException {
      throw const AppException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
    } on FormatException {
      throw const AppException('Format respons server tidak valid.');
    } catch (_) {
      throw const AppException(
        'Terjadi kesalahan saat mengambil data. Silakan coba lagi.',
      );
    }
  }
}
