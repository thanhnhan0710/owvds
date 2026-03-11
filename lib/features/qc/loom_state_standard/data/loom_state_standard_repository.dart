import 'package:dio/dio.dart';
import 'package:owvds/features/qc/loom_state_standard/domain/loom_state_standard_model.dart';
import '../../../../core/network/api_client.dart';

import 'package:file_picker/file_picker.dart';

class StandardRepository {
  final Dio _dio = ApiClient().dio;

  Future<List<Standard>> getStandards() async {
    try {
      final response = await _dio.get('/api/v1/standards/');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Standard.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load standards: $e");
    }
  }

  Future<List<Standard>> searchStandards(String keyword) async {
    try {
      final response = await _dio.get(
        '/api/v1/standards/search',
        queryParameters: {'keyword': keyword},
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Standard.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to search standards: $e");
    }
  }

  Future<Standard> getStandardById(int id) async {
    try {
      final response = await _dio.get('/api/v1/standards/$id');
      return Standard.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load standard details: $e');
    }
  }

  Future<void> createStandard(Standard standard) async {
    try {
      await _dio.post('/api/v1/standards/', data: standard.toJson());
    } catch (e) {
      throw Exception("Failed to create standard: $e");
    }
  }

  Future<void> updateStandard(Standard standard) async {
    try {
      await _dio.put(
        '/api/v1/standards/${standard.standardId}',
        data: standard.toJson(),
      );
    } catch (e) {
      throw Exception("Failed to update standard: $e");
    }
  }

  Future<void> deleteStandard(int id) async {
    try {
      await _dio.delete('/api/v1/standards/$id');
    } catch (e) {
      throw Exception("Failed to delete standard: $e");
    }
  }

  Future<Map<String, dynamic>> importExcel(PlatformFile file) async {
    try {
      FormData formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(file.bytes!, filename: file.name),
      });

      final response = await _dio.post(
        '/api/v1/standards/import',
        data: formData,
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to import Excel: $e');
    }
  }
}
