import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/area_model.dart';

class AreaRepository {
  final Dio _dio = ApiClient().dio;

  Future<List<Area>> getAreas() async {
    final response = await _dio.get('/api/v1/areas/');
    return (response.data as List).map((e) => Area.fromJson(e)).toList();
  }

  Future<List<Area>> searchAreas(String keyword) async {
    final response = await _dio.get(
      '/api/v1/areas/search',
      queryParameters: {'keyword': keyword},
    );
    return (response.data as List).map((e) => Area.fromJson(e)).toList();
  }

  Future<void> createArea(Area item) async {
    await _dio.post('/api/v1/areas/', data: item.toJson());
  }

  Future<void> updateArea(Area item) async {
    await _dio.put('/api/v1/areas/${item.id}', data: item.toJson());
  }

  Future<void> deleteArea(int id) async {
    await _dio.delete('/api/v1/areas/$id');
  }
}
