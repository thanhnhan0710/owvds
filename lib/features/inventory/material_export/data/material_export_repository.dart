import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:owvds/core/network/api_client.dart'; // Thay đổi đường dẫn import theo app của bạn
import '../domain/material_export_model.dart';

class MaterialExportRepository {
  final Dio _dio = ApiClient().dio;
  final String _basePath = '/api/v1/material-exports';

  // 1. Lấy mã tự động
  Future<String> getNextExportCode() async {
    final response = await _dio.get('$_basePath/next-number');
    return response.data['export_code'];
  }

  // 2. Lấy danh sách phân trang và lọc
  Future<List<MaterialExport>> getExports({
    int skip = 0,
    int limit = 20,
    String? search,
    int? warehouseId,
    int? exporterId,
    int? receiverId,
    String? fromDate,
    String? toDate,
  }) async {
    // Lọc bỏ các tham số null để tránh lỗi 422 từ FastAPI
    final queryParams = <String, dynamic>{'skip': skip, 'limit': limit};

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search;
    }
    if (warehouseId != null) queryParams['warehouse_id'] = warehouseId;
    if (exporterId != null) queryParams['exporter_id'] = exporterId;
    if (receiverId != null) queryParams['receiver_id'] = receiverId;
    if (fromDate != null && fromDate.isNotEmpty) {
      queryParams['from_date'] = fromDate;
    }
    if (toDate != null && toDate.isNotEmpty) queryParams['to_date'] = toDate;

    final response = await _dio.get(
      '$_basePath/',
      queryParameters: queryParams,
    );
    return (response.data as List)
        .map((json) => MaterialExport.fromJson(json))
        .toList();
  }

  // 3. Lấy chi tiết 1 phiếu
  Future<MaterialExport> getExportDetail(int id) async {
    final response = await _dio.get('$_basePath/$id');
    return MaterialExport.fromJson(response.data);
  }

  // 4. Tạo mới phiếu xuất
  Future<MaterialExport> createExport(MaterialExportRequest request) async {
    final response = await _dio.post('$_basePath/', data: request.toJson());
    return MaterialExport.fromJson(response.data);
  }

  // 5. Cập nhật phiếu xuất (Header)
  Future<MaterialExport> updateExport(
    int id,
    Map<String, dynamic> updateData,
  ) async {
    final response = await _dio.put('$_basePath/$id', data: updateData);
    return MaterialExport.fromJson(response.data);
  }

  // 6. Xóa/Hủy phiếu
  Future<void> deleteExport(int id) async {
    await _dio.delete('$_basePath/$id');
  }

  // 7. Lấy danh sách batch đang hoạt động trên máy (dùng cho tạo phiếu dệt)
  Future<List<ActiveBatchOnMachine>> getActiveBatchesOnMachine(
    int machineId,
    int productId,
  ) async {
    final response = await _dio.get(
      '$_basePath/active-batches-on-machine',
      queryParameters: {'machine_id': machineId, 'product_id': productId},
    );
    return (response.data as List)
        .map((json) => ActiveBatchOnMachine.fromJson(json))
        .toList();
  }

  // 8. Xuất Excel
  Future<Uint8List> exportExcel({
    String? search,
    int? warehouseId,
    int? exporterId,
    int? receiverId,
    String? fromDate,
    String? toDate,
  }) async {
    final queryParams = <String, dynamic>{};

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search;
    }
    if (warehouseId != null) queryParams['warehouse_id'] = warehouseId;
    if (exporterId != null) queryParams['exporter_id'] = exporterId;
    if (receiverId != null) queryParams['receiver_id'] = receiverId;
    if (fromDate != null && fromDate.isNotEmpty) {
      queryParams['from_date'] = fromDate;
    }
    if (toDate != null && toDate.isNotEmpty) queryParams['to_date'] = toDate;

    final response = await _dio.get(
      '$_basePath/export-excel',
      queryParameters: queryParams,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  }
}
