import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/material_receipt_model.dart';

class MaterialReceiptRepository {
  final Dio _dio = ApiClient().dio;

  static const String _endpoint = '/api/v1/material-receipts/';

  // [CẬP NHẬT]: Thêm các tham số phân trang và bộ lọc thời gian
  Future<List<MaterialReceipt>> getReceipts({
    int skip = 0,
    int limit = 100,
    String? startDate,
    String? endDate,
  }) async {
    try {
      // Xây dựng map param động, chỉ thêm các param khác null
      final queryParams = <String, dynamic>{'skip': skip, 'limit': limit};

      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _dio.get(_endpoint, queryParameters: queryParams);

      if (response.data is List) {
        return (response.data as List)
            .map((e) => MaterialReceipt.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load material receipts: $e");
    }
  }

  // Cập nhật thêm hỗ trợ phân trang cho hàm tìm kiếm
  Future<List<MaterialReceipt>> searchReceipts(
    String keyword, {
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get(
        _endpoint,
        queryParameters: {'search': keyword, 'skip': skip, 'limit': limit},
      );

      if (response.data is List) {
        return (response.data as List)
            .map((e) => MaterialReceipt.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Material receipts not found: $e");
    }
  }

  Future<void> createReceipt(MaterialReceipt receipt) async {
    try {
      final data = receipt.toJson();
      data.remove('receipt_id');

      await _dio.post(_endpoint, data: data);
    } catch (e) {
      throw Exception("Failed to create material receipt: $e");
    }
  }

  Future<void> updateReceipt(MaterialReceipt receipt) async {
    try {
      await _dio.put('$_endpoint${receipt.receiptId}', data: receipt.toJson());
    } catch (e) {
      throw Exception("Failed to update material receipt: $e");
    }
  }

  Future<void> deleteReceipt(int id) async {
    try {
      await _dio.delete('$_endpoint$id');
    } catch (e) {
      throw Exception("Failed to delete material receipt: $e");
    }
  }

  // [MỚI]: Hàm Export Excel trả về Uint8List
  Future<Uint8List> exportExcel({
    String? search,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null) queryParams['status'] = status;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      // Gọi endpoint export-excel thay vì endpoint gốc
      final response = await _dio.get(
        '${_endpoint}export-excel',
        queryParameters: queryParams,
        options: Options(
          responseType: ResponseType
              .bytes, // RẤT QUAN TRỌNG: Báo cho Dio biết đây là file nhị phân
        ),
      );

      return response.data; // Trả về mảng byte
    } catch (e) {
      throw Exception("Lỗi khi tải file Excel: $e");
    }
  }
}
