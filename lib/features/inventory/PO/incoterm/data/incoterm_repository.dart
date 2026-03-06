import 'package:dio/dio.dart';
import 'package:owvds/core/network/api_client.dart';
import '../domain/incoterm_model.dart';

class IncotermRepository {
  final Dio _dio = ApiClient().dio;

  Future<List<Incoterm>> getIncoterms({String? search}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      final response = await _dio.get(
        '/api/v1/incoterms/',
        queryParameters: queryParams,
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Incoterm.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Lỗi tải Incoterms: $e");
    }
  }

  Future<void> createIncoterm(Incoterm incoterm) async {
    try {
      await _dio.post('/api/v1/incoterms/', data: incoterm.toJson());
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> updateIncoterm(Incoterm incoterm) async {
    try {
      await _dio.put(
        '/api/v1/incoterms/${incoterm.incotermId}',
        data: incoterm.toJson(),
      );
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> deleteIncoterm(int id) async {
    try {
      await _dio.delete('/api/v1/incoterms/$id');
    } catch (e) {
      throw Exception(e);
    }
  }
}
