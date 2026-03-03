import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';
import '../../../../core/network/api_client.dart';
import '../domain/employee_model.dart';

class EmployeeRepository {
  final Dio _dio = ApiClient().dio;

  // [MỚI] API lấy tổng số nhân viên chính xác
  Future<int> getEmployeeCount() async {
    try {
      final response = await _dio.get('/api/v1/employees/count');
      return response.data as int;
    } catch (e) {
      return 0;
    }
  }

  Future<List<Employee>> getEmployees({int skip = 0, int limit = 20}) async {
    try {
      final response = await _dio.get(
        '/api/v1/employees/',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Employee.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load employees: $e");
    }
  }

  Future<List<Employee>> searchEmployees(
    String keyword, {
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/employees/search/',
        queryParameters: {'keyword': keyword, 'skip': skip, 'limit': limit},
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Employee.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Employees not found: $e");
    }
  }

  Future<List<Employee>> getEmployeesByDepartmentId(
    int departmentId, {
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/employees/department/$departmentId',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Employee.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception(
        "Failed to load employees for department $departmentId: $e",
      );
    }
  }

  Future<void> createEmployee(Employee emp) async {
    try {
      await _dio.post('/api/v1/employees/', data: emp.toJson());
    } catch (e) {
      throw Exception("Failed to create employee: $e");
    }
  }

  Future<void> updateEmployee(Employee emp) async {
    try {
      await _dio.put('/api/v1/employees/${emp.id}', data: emp.toJson());
    } catch (e) {
      throw Exception("Failed to update employee: $e");
    }
  }

  Future<void> deleteEmployee(int id) async {
    try {
      await _dio.delete('/api/v1/employees/$id');
    } catch (e) {
      throw Exception("Failed to delete employee: $e");
    }
  }

  Future<String> uploadAvatar(PlatformFile file) async {
    try {
      if (file.bytes == null) throw Exception("File data is empty.");

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      final response = await _dio.post('/api/v1/upload/avatar', data: formData);
      return response.data['url'] ?? '';
    } catch (e) {
      throw Exception("Failed to upload avatar: $e");
    }
  }

  Future<Map<String, dynamic>> importExcel(PlatformFile file) async {
    try {
      if (file.bytes == null) throw Exception("File data is empty.");
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      });

      final response = await _dio.post(
        '/api/v1/employees/import',
        data: formData,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? e.message);
    } catch (e) {
      throw Exception("Failed to import employees: $e");
    }
  }

  Future<Uint8List> exportExcel() async {
    try {
      final response = await _dio.get(
        '/api/v1/employees/export',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data);
    } on DioException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception("Failed to export employees: $e");
    }
  }
}
