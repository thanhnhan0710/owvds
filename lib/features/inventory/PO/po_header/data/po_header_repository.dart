import 'package:dio/dio.dart';
import 'dart:typed_data';
import '../../../../../core/network/api_client.dart';
import '../domain/po_header_model.dart';

class POHeaderRepository {
  final Dio _dio = ApiClient().dio;

  Future<String> getNextPONumber() async {
    try {
      final response = await _dio.get('/api/v1/purchase-orders/next-number');
      return response.data.toString().replaceAll('"', '');
    } catch (e) {
      return "AUTO";
    }
  }

  Future<int> getPOCount({int? vendorId, int? statusId, String? search}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (vendorId != null) queryParams['vendor_id'] = vendorId;
      if (statusId != null) queryParams['status_id'] = statusId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        '/api/v1/purchase-orders/count',
        queryParameters: queryParams,
      );
      return response.data as int;
    } catch (e) {
      return 0;
    }
  }

  Future<List<PurchaseOrderHeader>> getPOs({
    int skip = 0,
    int limit = 200,
    int? vendorId,
    int? statusId,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{'skip': skip, 'limit': limit};
      if (vendorId != null) queryParams['vendor_id'] = vendorId;
      if (statusId != null) queryParams['status_id'] = statusId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        '/api/v1/purchase-orders/',
        queryParameters: queryParams,
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => PurchaseOrderHeader.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Lỗi tải Purchase Orders: $e");
    }
  }

  Future<PurchaseOrderHeader> getPOById(int poId) async {
    try {
      final response = await _dio.get('/api/v1/purchase-orders/$poId');
      return PurchaseOrderHeader.fromJson(response.data);
    } catch (e) {
      throw Exception("Lỗi tải chi tiết PO: $e");
    }
  }

  Future<void> createPO(PurchaseOrderHeader po) async {
    try {
      await _dio.post('/api/v1/purchase-orders/', data: po.toJsonForCreate());
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> updatePO(PurchaseOrderHeader po) async {
    try {
      await _dio.put(
        '/api/v1/purchase-orders/${po.poId}',
        data: po.toJsonForUpdate(),
      );
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> deletePO(int id) async {
    try {
      await _dio.delete('/api/v1/purchase-orders/$id');
    } catch (e) {
      throw Exception(e);
    }
  }

  // --- [MỚI]: GỌI API XUẤT EXCEL TỪ BACKEND ---
  Future<Uint8List> exportExcel({
    int? vendorId,
    int? statusId,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (vendorId != null) queryParams['vendor_id'] = vendorId;
      if (statusId != null) queryParams['status_id'] = statusId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get<List<int>>(
        '/api/v1/purchase-orders/export',
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.bytes),
      );

      return Uint8List.fromList(response.data!);
    } catch (e) {
      throw Exception("Lỗi xuất Excel: $e");
    }
  }
}
