import 'package:dio/dio.dart';
import 'package:owvds/core/network/api_client.dart';
import '../domain/po_status_model.dart';

class POStatusRepository {
  final Dio _dio = ApiClient().dio;

  Future<List<POStatus>> getStatuses({String? search}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      final response = await _dio.get(
        '/api/v1/po-statuses/',
        queryParameters: queryParams,
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => POStatus.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Lỗi tải Trạng thái PO: $e");
    }
  }

  Future<void> createStatus(POStatus status) async {
    try {
      await _dio.post('/api/v1/po-statuses/', data: status.toJson());
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> updateStatus(POStatus status) async {
    try {
      await _dio.put(
        '/api/v1/po-statuses/${status.statusId}',
        data: status.toJson(),
      );
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> deleteStatus(int id) async {
    try {
      await _dio.delete('/api/v1/po-statuses/$id');
    } catch (e) {
      throw Exception(e);
    }
  }
}
