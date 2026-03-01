import 'package:dio/dio.dart';
import 'package:owvds/core/network/api_client.dart';
import '../domain/machine_status_model.dart';

class MachineStatusRepository {
  final Dio _dio = ApiClient().dio;

  Future<List<MachineStatus>> getStatuses() async {
    final response = await _dio.get('/api/v1/machine-statuses/');
    return (response.data as List)
        .map((e) => MachineStatus.fromJson(e))
        .toList();
  }

  // [THÊM] Phương thức tìm kiếm gọi thẳng xuống Backend
  Future<List<MachineStatus>> searchStatuses(String keyword) async {
    final response = await _dio.get(
      '/api/v1/machine-statuses/search',
      queryParameters: {'keyword': keyword, 'skip': 0, 'limit': 100},
    );
    return (response.data as List)
        .map((e) => MachineStatus.fromJson(e))
        .toList();
  }

  Future<void> createStatus(MachineStatus item) async =>
      await _dio.post('/api/v1/machine-statuses/', data: item.toJson());
  Future<void> updateStatus(MachineStatus item) async => await _dio.put(
    '/api/v1/machine-statuses/${item.id}',
    data: item.toJson(),
  );
  Future<void> deleteStatus(int id) async =>
      await _dio.delete('/api/v1/machine-statuses/$id');
}
