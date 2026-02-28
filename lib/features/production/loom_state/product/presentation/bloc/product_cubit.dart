import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/product_repository.dart';
import 'package:file_saver/file_saver.dart';
import '../../domain/product_model.dart';

abstract class ProductState {}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<Product> allProducts;
  final List<Product> displayedProducts;
  final int? currentTypeId;

  ProductLoaded({
    required this.allProducts,
    required this.displayedProducts,
    this.currentTypeId,
  });
}

class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
}

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _repo;
  List<Product> _allProductsCache = [];

  ProductCubit(this._repo) : super(ProductInitial());

  Future<void> loadProducts({int? typeId, bool forceRefresh = false}) async {
    emit(ProductLoading());
    try {
      if (_allProductsCache.isEmpty || forceRefresh || typeId == null) {
        _allProductsCache = await _repo.getProducts();

        // [THÊM]: Sắp xếp toàn bộ cache theo ID giảm dần (Mới nhất lên đầu)
        _allProductsCache.sort((a, b) => b.id.compareTo(a.id));
      }

      List<Product> filtered = _allProductsCache;
      if (typeId != null) {
        filtered = _allProductsCache
            .where((p) => p.productTypeId == typeId)
            .toList();
      }

      emit(
        ProductLoaded(
          allProducts: _allProductsCache,
          displayedProducts: filtered,
          currentTypeId: typeId,
        ),
      );
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> searchProducts(String keyword) async {
    if (keyword.trim().isEmpty) {
      int? currentType;
      if (state is ProductLoaded) {
        currentType = (state as ProductLoaded).currentTypeId;
      }
      loadProducts(typeId: currentType);
      return;
    }

    emit(ProductLoading());
    try {
      final list = await _repo.searchProducts(keyword);

      // [THÊM]: Sắp xếp kết quả tìm kiếm theo ID giảm dần
      list.sort((a, b) => b.id.compareTo(a.id));

      emit(
        ProductLoaded(
          allProducts: _allProductsCache,
          displayedProducts: list,
          currentTypeId: null,
        ),
      );
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> saveProduct({
    required Product product,
    PlatformFile? imageFile,
    required bool isEdit,
  }) async {
    try {
      String finalImageUrl = product.imageUrl;

      if (imageFile != null) {
        finalImageUrl = await _repo.uploadProductImage(imageFile);
      }

      final newProduct = Product(
        id: product.id,
        itemCode: product.itemCode,
        productTypeId: product.productTypeId,
        note: product.note,
        imageUrl: finalImageUrl,
      );

      if (isEdit) {
        await _repo.updateProduct(newProduct);
      } else {
        await _repo.createProduct(newProduct);
      }

      loadProducts(forceRefresh: true);
    } catch (e) {
      emit(ProductError("Error saving product: $e"));
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _repo.deleteProduct(id);
      loadProducts(forceRefresh: true);
    } catch (e) {
      emit(ProductError("Error deleting: $e"));
    }
  }

  Future<void> importExcel(PlatformFile file) async {
    emit(ProductLoading());
    try {
      final result = await _repo.importExcel(file);
      await loadProducts(forceRefresh: true);

      if (result['errors'] != null && (result['errors'] as List).isNotEmpty) {
        emit(
          ProductError(
            "Đã import ${result['success_count']} dòng. Các lỗi:\n${(result['errors'] as List).join('\n')}",
          ),
        );
      }
    } catch (e) {
      emit(ProductError(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> exportExcel() async {
    try {
      final bytes = await _repo.exportExcel();

      await FileSaver.instance.saveFile(
        name: 'ItemCode${DateTime.now().millisecondsSinceEpoch}.xlsx',
        bytes: bytes,
        mimeType: MimeType.microsoftExcel,
      );
    } catch (e) {
      emit(
        ProductError(
          "Lỗi xuất file: ${e.toString().replaceAll("Exception: ", "")}",
        ),
      );
    }
  }
}
