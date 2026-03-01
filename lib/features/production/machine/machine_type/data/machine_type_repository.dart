import 'package:dio/dio.dart';
import 'package:owvds/core/network/api_client.dart';

import '../domain/machine_type_model.dart';

class MachineTypeRepository {
  final Dio _dio = ApiClient().dio;

  Future<List<MachineType>> getTypes() async {
    final response = await _dio.get('/api/v1/machine-types/');
    return (response.data as List).map((e) => MachineType.fromJson(e)).toList();
  }

  Future<List<MachineType>> searchTypes(String keyword) async {
    final response = await _dio.get(
      '/api/v1/machine-types/search',
      queryParameters: {'keyword': keyword},
    );
    return (response.data as List).map((e) => MachineType.fromJson(e)).toList();
  }

  Future<void> createType(MachineType item) async =>
      await _dio.post('/api/v1/machine-types/', data: item.toJson());
  Future<void> updateType(MachineType item) async =>
      await _dio.put('/api/v1/machine-types/${item.id}', data: item.toJson());
  Future<void> deleteType(int id) async =>
      await _dio.delete('/api/v1/machine-types/$id');
}
