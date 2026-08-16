import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  bool _refreshing = false;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.accessToken;
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        print('📤 Requête: ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('📥 Réponse: ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) async {
        print('❌ Erreur: ${error.message} (status: ${error.response?.statusCode})');
        final isAuthError = error.response?.statusCode == 401;
        final isRefreshCall = error.requestOptions.path.contains('/auth/refresh');
        if (isAuthError && !isRefreshCall && !_refreshing) {
          _refreshing = true;
          final refreshed = await _tryRefresh();
          _refreshing = false;
          if (refreshed) {
            try {
              final clone = await _dio.fetch(error.requestOptions);
              return handler.resolve(clone);
            } catch (_) {}
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await TokenStorage.refreshToken;
    if (refreshToken == null) return false;
    try {
      final response = await _dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
      await TokenStorage.saveAccessToken(response.data['accessToken']);
      return true;
    } catch (_) {
      await TokenStorage.clear();
      return false;
    }
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _request(() => _dio.get(path, queryParameters: query));

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) =>
      _request(() => _dio.post(path, data: data));

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? data}) =>
      _request(() => _dio.put(path, data: data));

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? data}) =>
      _request(() => _dio.patch(path, data: data));

  Future<Map<String, dynamic>> delete(String path) => _request(() => _dio.delete(path));

  Future<Map<String, dynamic>> uploadImage(String path, {required List<int> bytes, required String fileName}) async {
    final formData = FormData.fromMap({'file': MultipartFile.fromBytes(bytes, filename: fileName)});
    return _request(() => _dio.post(path, data: formData));
  }

  Future<Map<String, dynamic>> _request(Future<Response> Function() call) async {
    try {
      final response = await call();
      print('✅ Succès: ${response.statusCode}');

      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      } else if (response.data is String) {
        try {
          final parsed = jsonDecode(response.data as String);
          if (parsed is Map) {
            return Map<String, dynamic>.from(parsed);
          }
          return {'data': parsed};
        } catch (_) {
          return {'data': response.data};
        }
      }
      return {};
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      String message = "Impossible de contacter le serveur. Vérifiez votre connexion.";
      if (e.response?.data != null) {
        if (e.response!.data is Map) {
          message = e.response!.data['error'] ?? message;
        } else if (e.response!.data is String) {
          message = e.response!.data as String;
        }
      }
      throw ApiException(message, statusCode: e.response?.statusCode);
    } catch (e) {
      print('❌ Erreur inattendue: $e');
      throw ApiException('Une erreur inattendue est survenue.');
    }
  }
}