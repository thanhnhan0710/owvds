import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/product_type_repository.dart';
import '../../domain/product_type_model.dart';

abstract class ProductTypeState {}

class ProductTypeInitial extends ProductTypeState {}

class ProductTypeLoading extends ProductTypeState {}

class ProductTypeLoaded extends ProductTypeState {
  final List<ProductType> productTypes;
  ProductTypeLoaded(this.productTypes);
}

class ProductTypeError extends ProductTypeState {
  final String message;
  ProductTypeError(this.message);
}

class ProductTypeCubit extends Cubit<ProductTypeState> {
  final ProductTypeRepository _repo;

  ProductTypeCubit(this._repo) : super(ProductTypeInitial());

  Future<void> loadProductTypes() async {
    emit(ProductTypeLoading());
    try {
      final list = await _repo.getProductTypes();

      // [THÊM]: Sắp xếp theo ID giảm dần (Mới nhất lên đầu)
      list.sort((a, b) => b.id.compareTo(a.id));

      emit(ProductTypeLoaded(list));
    } catch (e) {
      emit(ProductTypeError(e.toString()));
    }
  }

  Future<void> searchProductTypes(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadProductTypes();
      return;
    }
    emit(ProductTypeLoading());
    try {
      final list = await _repo.searchProductTypes(keyword);

      // [THÊM]: Sắp xếp kết quả tìm kiếm mới nhất lên đầu
      list.sort((a, b) => b.id.compareTo(a.id));

      emit(ProductTypeLoaded(list));
    } catch (e) {
      emit(ProductTypeError(e.toString()));
    }
  }

  Future<void> saveProductType({
    required ProductType productType,
    required bool isEdit,
  }) async {
    try {
      if (isEdit) {
        await _repo.updateProductType(productType);
      } else {
        await _repo.createProductType(productType);
      }
      loadProductTypes();
    } catch (e) {
      emit(ProductTypeError("Error saving product type: $e"));
    }
  }

  Future<void> deleteProductType(int id) async {
    try {
      await _repo.deleteProductType(id);
      loadProductTypes();
    } catch (e) {
      emit(ProductTypeError("Error deleting: $e"));
    }
  }
}
