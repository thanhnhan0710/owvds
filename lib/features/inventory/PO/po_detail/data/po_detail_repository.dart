import 'package:dio/dio.dart';
import 'package:owvds/core/network/api_client.dart';
import '../domain/po_detail_model.dart';

class PODetailRepository {
  final Dio _dio = ApiClient().dio;

  Future<PurchaseOrderDetail> getDetail(int detailId) async {
    try {
      final response = await _dio.get('/api/v1/po-details/$detailId');
      return PurchaseOrderDetail.fromJson(response.data);
    } catch (e) {
      throw Exception("Lỗi tải PO Detail: $e");
    }
  }

  Future<void> createDetail(int poId, PurchaseOrderDetail detail) async {
    try {
      await _dio.post('/api/v1/po-details/po/$poId', data: detail.toJson());
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> updateDetail(
    int detailId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      await _dio.put('/api/v1/po-details/$detailId', data: updateData);
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> deleteDetail(int detailId) async {
    try {
      await _dio.delete('/api/v1/po-details/$detailId');
    } catch (e) {
      throw Exception(e);
    }
  }
}
