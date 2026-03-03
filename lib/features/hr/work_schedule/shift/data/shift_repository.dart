import 'package:dio/dio.dart';
import 'package:owvds/core/network/api_client.dart';
import 'package:owvds/features/hr/work_schedule/shift/domain/shift_model.dart';

class ShiftRepository {
  final Dio _dio = ApiClient().dio;

  // Get all departments
  Future<List<Shift>> getShifts() async {
    try {
      final response = await _dio.get('/api/v1/shifts/');
      if (response.data is List) {
        return (response.data as List).map((e) => Shift.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load shifts: $e");
    }
  }

  Future<List<Shift>> searchShifts(String keyword) async {
    try {
      final response = await _dio.get(
        '/api/v1/shifts/search/', // Endpoint theo yêu cầu
        queryParameters: {'keyword': keyword},
      );

      if (response.data is List) {
        return (response.data as List).map((e) => Shift.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to search shifts: $e");
    }
  }

  Future<void> createShift(Shift shif) async {
    try {
      await _dio.post('/api/v1/shifts/', data: shif.toJson());
    } catch (e) {
      throw Exception("Failed to create shifts: $e");
    }
  }

  Future<void> updateShift(Shift shif) async {
    try {
      await _dio.put('/api/v1/shifts/${shif.id}', data: shif.toJson());
    } catch (e) {
      throw Exception("Failed to update shift: $e");
    }
  }

  Future<void> deleteShift(int id) async {
    try {
      await _dio.delete('/api/v1/shifts/$id');
    } catch (e) {
      throw Exception("Failed to delete shift: $e");
    }
  }
}
