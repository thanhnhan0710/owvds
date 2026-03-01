import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/core/bloc/language_cubit.dart';
import 'package:owvds/features/area/data/area_repository.dart';
import 'package:owvds/features/area/presentation/bloc/area_cubit.dart';
import 'package:owvds/features/production/loom_state/product/data/product_repository.dart';
import 'package:owvds/features/production/loom_state/product/presentation/bloc/product_cubit.dart';
import 'package:owvds/features/production/loom_state/product_type/data/product_type_repository.dart';
import 'package:owvds/features/production/loom_state/product_type/presentation/bloc/product_type_cubit.dart';
import 'package:owvds/features/production/machine/machine/data/machine_repository.dart';
import 'package:owvds/features/production/machine/machine/presentation/bloc/machine_cubit.dart';
import 'package:owvds/features/production/machine/machine_assignment/data/machine_assignment_repository.dart';
import 'package:owvds/features/production/machine/machine_assignment/presentation/bloc/gobal_assignment_cubit.dart';
import 'package:owvds/features/production/machine/machine_status/data/machine_status_repository.dart';
import 'package:owvds/features/production/machine/machine_status/presentation/bloc/machine_status_cubit.dart';
import 'package:owvds/features/production/machine/machine_type/data/machine_type_repository.dart';
import 'package:owvds/features/production/machine/machine_type/presentation/bloc/machine_type_cubit.dart';

class AppProviders {
  // Dùng 'static final' để Dart tự động giữ lại chính xác kiểu dữ liệu thay vì ép về dạng List<dynamic>
  static final providers = [
    // 1. Core Providers
    // [QUAN TRỌNG] Phải có <LanguageCubit> ở đây để hệ thống nhận diện đúng loại Cubit
    BlocProvider<LanguageCubit>(create: (context) => LanguageCubit()),

    // 2. HR & Admin Providers
    // Sau này khi thêm các Cubit khác, bạn cũng bắt buộc phải viết rõ tên Cubit trong cặp ngoặc <>.
    // Ví dụ: BlocProvider<DepartmentCubit>(create: (context) => DepartmentCubit()),
    BlocProvider<AreaCubit>(create: (context) => AreaCubit(AreaRepository())),

    // 3. Inventory Providers

    // 4. Production Providers
    BlocProvider<ProductTypeCubit>(
      create: (context) => ProductTypeCubit(ProductTypeRepository()),
    ),
    BlocProvider<ProductCubit>(
      create: (context) => ProductCubit(ProductRepository()),
    ),

    BlocProvider<MachineTypeCubit>(
      create: (context) => MachineTypeCubit(MachineTypeRepository()),
    ),

    BlocProvider<MachineStatusCubit>(
      create: (context) => MachineStatusCubit(MachineStatusRepository()),
    ),

    BlocProvider<MachineCubit>(
      create: (context) => MachineCubit(MachineRepository()),
    ),

    BlocProvider<GlobalAssignmentCubit>(
      create: (context) => GlobalAssignmentCubit(MachineAssignmentRepository()),
    ),
  ];
}
