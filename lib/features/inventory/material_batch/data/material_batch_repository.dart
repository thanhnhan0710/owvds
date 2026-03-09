import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/material_batch_model.dart';

class MaterialBatchRepository {
  final Dio _dio = ApiClient().dio;

  static const String _endpoint = '/api/v1/batches/';

  Future<List<MaterialBatch>> getBatches() async {
    try {
      final response = await _dio.get(
        _endpoint,
        queryParameters: {'skip': 0, 'limit': 100},
      );

      if (response.data is List) {
        return (response.data as List)
            .map((e) => MaterialBatch.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load material batches: $e");
    }
  }

  Future<List<MaterialBatch>> searchBatches(String keyword) async {
    try {
      final response = await _dio.get(
        _endpoint,
        queryParameters: {'search': keyword, 'skip': 0, 'limit': 100},
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => MaterialBatch.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Material batches not found: $e");
    }
  }

  Future<void> createBatch(MaterialBatch batch) async {
    try {
      final data = batch.toJson();
      data.remove('batch_id');

      await _dio.post(_endpoint, data: data);
    } catch (e) {
      throw Exception("Failed to create material batch: $e");
    }
  }

  Future<void> updateBatch(MaterialBatch batch) async {
    try {
      await _dio.put('$_endpoint${batch.id}', data: batch.toJson());
    } catch (e) {
      throw Exception("Failed to update material batch: $e");
    }
  }

  Future<void> deleteBatch(int id) async {
    try {
      await _dio.delete('$_endpoint$id');
    } catch (e) {
      throw Exception("Failed to delete material batch: $e");
    }
  }
}
