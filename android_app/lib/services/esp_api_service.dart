import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/api_result.dart';
import '../models/esp_status.dart';

class EspApiService {
  EspApiService({
    required Uri baseUri,
    http.Client? client,
    Duration timeout = const Duration(seconds: 3),
    int retries = 1,
  })  : _baseUri = baseUri,
        _client = client ?? http.Client(),
        _timeout = timeout,
        _retries = retries;

  final Uri _baseUri;
  final http.Client _client;
  final Duration _timeout;
  final int _retries;

  Future<ApiResult<EspStatus>> fetchStatus() async {
    final response = await _get('/status');
    if (!response.isSuccess) {
      return ApiResult.failure(response.error ?? 'ESP is offline.');
    }

    try {
      return ApiResult.success(EspStatus.fromJson(response.data!));
    } on FormatException catch (error) {
      return ApiResult.failure(error.message);
    }
  }

  Future<ApiResult<void>> startPump() => _command('/on');

  Future<ApiResult<void>> stopPump() => _command('/off');

  Future<ApiResult<void>> clearLock() => _command('/reset');

  Future<ApiResult<void>> _command(String path) async {
    final response = await _get(path);
    if (!response.isSuccess) {
      return ApiResult.failure(response.error ?? 'Command failed.');
    }

    final success = response.data!['success'];
    if (success == true) {
      return ApiResult.success(null);
    }

    final error = response.data!['error'];
    return ApiResult.failure(
      error is String ? _friendlyError(error) : 'Command was rejected.',
    );
  }

  Future<ApiResult<Map<String, dynamic>>> _get(String path) async {
    Object? lastError;

    for (var attempt = 0; attempt <= _retries; attempt++) {
      try {
        final response = await _client
            .get(_baseUri.replace(path: path))
            .timeout(_timeout);

        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          return ApiResult.failure('Malformed ESP response.');
        }

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return ApiResult.success(decoded);
        }

        final error = decoded['error'];
        return ApiResult.failure(
          error is String ? _friendlyError(error) : 'HTTP ${response.statusCode}',
        );
      } on TimeoutException catch (error) {
        lastError = error;
      } on SocketException catch (error) {
        lastError = error;
      } on http.ClientException catch (error) {
        lastError = error;
      } on FormatException catch (error) {
        return ApiResult.failure(error.message);
      }
    }

    return ApiResult.failure(_networkMessage(lastError));
  }

  String _networkMessage(Object? error) {
    if (error is TimeoutException) {
      return 'ESP request timed out.';
    }
    if (error is SocketException) {
      return 'ESP is unreachable on this network.';
    }
    return 'ESP is offline.';
  }

  String _friendlyError(String error) {
    switch (error) {
      case 'lockout_active':
        return 'Pump is locked until CLEAR LOCK is pressed.';
      case 'tank_full':
        return 'Tank is full. Pump was not started.';
      case 'not_found':
        return 'ESP endpoint was not found.';
      default:
        return error.replaceAll('_', ' ');
    }
  }

  void dispose() {
    _client.close();
  }
}
