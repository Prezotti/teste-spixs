import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:teste_spixs/core/errors/app_exception.dart';

class AppHttpClient {
  AppHttpClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 10);

  Future<Map<String, dynamic>> get(Uri uri, {Map<String, String>? headers}) async {
    return _send(() => _client.get(uri, headers: headers).timeout(_timeout));
  }

  Future<Map<String, dynamic>> post(Uri uri, {Map<String, String>? headers, Map<String, dynamic>? body}) async {
    return _send(
      () => _client
          .post(uri, headers: {'Content-Type': 'application/json', ...?headers}, body: jsonEncode(body ?? const {}))
          .timeout(_timeout),
    );
  }

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request();
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const NetworkException('Resposta inválida do servidor.');
      }

      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        throw NetworkException(
          error['message'] as String? ?? 'Falha de rede. Tente novamente.',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw NetworkException('Falha de rede (${response.statusCode}). Tente novamente.');
      }

      return decoded;
    } on AppException {
      rethrow;
    } catch (error) {
      throw NetworkException('Sem internet ou serviço indisponível. Tente novamente.', cause: error);
    }
  }
}
