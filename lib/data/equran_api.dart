import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Klien tipis untuk API eQuran.id v2 (tanpa API key).
///   GET /surat          -> daftar 114 surat
///   GET /surat/{nomor}  -> detail surat + ayat + audio per ayat
/// Respons dibungkus { code, message, data }.
class EQuranApi {
  EQuranApi([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;
  static const baseUrl = 'https://equran.id/api/v2';

  /// Mengembalikan body mentah (string JSON) supaya bisa di-cache apa adanya.
  Future<String> get(String path) async {
    final res = await _client
        .get(Uri.parse('$baseUrl$path'))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw ApiException('Server mengembalikan status ${res.statusCode}');
    }
    return utf8.decode(res.bodyBytes);
  }
}
