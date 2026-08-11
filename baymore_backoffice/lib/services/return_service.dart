import '../models/return_request.dart';
import 'api_client.dart';

class ReturnRequestService {
  final ApiClient _api = ApiClient();

  Future<List<ReturnRequest>> fetchAll() async {
    final data = await _api.get('/returns');
    return (data['requests'] as List).map((r) => ReturnRequest.fromJson(r)).toList();
  }

  Future<void> updateStatus(String id, ReturnStatus status, {String? staffNote}) =>
      _api.patch('/returns/$id', data: {'status': status.asString, if (staffNote != null) 'staffNote': staffNote});
}
