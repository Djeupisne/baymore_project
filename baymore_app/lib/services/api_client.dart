import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'token_storage.dart';

/// Exception métier propre, avec le message d'erreur renvoyé par le
/// backend (`{ error: "..." }`) plutôt qu'une exception Dio brute.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

/// Client HTTP central : injecte automatiquement le token d'accès, et
/// rafraîchit la session une fois en cas de 401 avant de réessayer —
/// remplace la gestion de session automatique de Firebase Auth.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  bool _refreshing = false;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl, connectTimeout: const Duration(seconds: 15)));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.accessToken;
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) async {
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
            } catch (_) {
              // retombe sur l'erreur d'origine si le retry échoue aussi
            }
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
      return Map<String, dynamic>.from(response.data ?? {});
    } on DioException catch (e) {
      final message = e.response?.data is Map ? (e.response?.data['error'] ?? 'Une erreur est survenue.') : "Impossible de contacter le serveur. Vérifiez votre connexion.";
      throw ApiException(message, statusCode: e.response?.statusCode);
    }
  }
}
