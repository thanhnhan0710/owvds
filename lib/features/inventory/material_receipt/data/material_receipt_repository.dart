import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/material_receipt_model.dart';

class MaterialReceiptRepository {
  final Dio _dio = ApiClient().dio;

  static const String _endpoint = '/api/v1/material-receipts/';

  Future<List<MaterialReceipt>> getReceipts() async {
    try {
      final response = await _dio.get(
        _endpoint,
        queryParameters: {'skip': 0, 'limit': 100},
      );

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

  Future<List<MaterialReceipt>> searchReceipts(String keyword) async {
    try {
      final response = await _dio.get(
        _endpoint,
        queryParameters: {'search': keyword, 'skip': 0, 'limit': 100},
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
      await _dio.put('$_endpoint${receipt.id}', data: receipt.toJson());
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
}
