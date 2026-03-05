import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/employee_group_model.dart';

class EmployeeGroupRepository {
  final Dio _dio = ApiClient().dio;
  final String _basePath = '/api/v1/employee-groups';

  Future<List<EmployeeGroup>> getGroups({int skip = 0, int limit = 200}) async {
    try {
      final response = await _dio.get(
        '$_basePath/',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => EmployeeGroup.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load employee groups: $e");
    }
  }

  Future<List<EmployeeGroup>> getGroupsByDepartment(
    int departmentId, {
    int skip = 0,
    int limit = 200,
  }) async {
    try {
      final response = await _dio.get(
        '$_basePath/department/$departmentId',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => EmployeeGroup.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load groups for department $departmentId: $e");
    }
  }

  Future<List<EmployeeGroup>> searchGroups(
    String keyword, {
    int skip = 0,
    int limit = 200,
  }) async {
    try {
      final response = await _dio.get(
        '$_basePath/search',
        queryParameters: {'keyword': keyword, 'skip': skip, 'limit': limit},
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => EmployeeGroup.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to search employee groups: $e");
    }
  }

  Future<EmployeeGroup> createGroup(EmployeeGroup group) async {
    try {
      final response = await _dio.post('$_basePath/', data: group.toJson());
      return EmployeeGroup.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to create employee group: $e");
    }
  }

  Future<EmployeeGroup> updateGroup(EmployeeGroup group) async {
    try {
      final response = await _dio.put(
        '$_basePath/${group.id}',
        data: group.toJson(),
      );
      return EmployeeGroup.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to update employee group: $e");
    }
  }

  Future<void> deleteGroup(int id) async {
    try {
      await _dio.delete('$_basePath/$id');
    } catch (e) {
      throw Exception("Failed to delete employee group: $e");
    }
  }
}
