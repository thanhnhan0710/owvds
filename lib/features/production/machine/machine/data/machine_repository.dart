import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:owvds/core/network/api_client.dart';
import '../domain/machine_model.dart';

class MachineRepository {
  final Dio _dio = ApiClient().dio;

  Future<List<Machine>> getMachines({int? areaId, int? statusId}) async {
    final Map<String, dynamic> query = {'skip': 0, 'limit': 200};
    if (areaId != null) query['area_id'] = areaId;
    if (statusId != null) query['status_id'] = statusId;

    final response = await _dio.get(
      '/api/v1/machines/',
      queryParameters: query,
    );
    return (response.data as List).map((e) => Machine.fromJson(e)).toList();
  }

  Future<List<Machine>> searchMachines(String keyword) async {
    final response = await _dio.get(
      '/api/v1/machines/search',
      queryParameters: {'keyword': keyword},
    );
    return (response.data as List).map((e) => Machine.fromJson(e)).toList();
  }

  Future<void> createMachine(Machine item) async =>
      await _dio.post('/api/v1/machines/', data: item.toJson());
  Future<void> updateMachine(Machine item) async =>
      await _dio.put('/api/v1/machines/${item.id}', data: item.toJson());
  Future<void> deleteMachine(int id) async =>
      await _dio.delete('/api/v1/machines/$id');

  // Import / Export
  Future<Map<String, dynamic>> importExcel(PlatformFile file) async {
    if (file.bytes == null) throw Exception("File data is empty.");
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
    });
    final response = await _dio.post('/api/v1/machines/import', data: formData);
    return response.data;
  }

  Future<Uint8List> exportExcel() async {
    final response = await _dio.get(
      '/api/v1/machines/export',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data);
  }
}
