import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/core/bloc/language_cubit.dart';
import 'package:owvds/features/area/data/area_repository.dart';
import 'package:owvds/features/area/presentation/bloc/area_cubit.dart';
import 'package:owvds/features/hr/department/data/department_repository.dart';
import 'package:owvds/features/hr/department/presentation/bloc/department_cubit.dart';
import 'package:owvds/features/hr/employee/data/employee_repository.dart';
import 'package:owvds/features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'package:owvds/features/hr/employee_group/data/employee_group_repository.dart';
import 'package:owvds/features/hr/employee_group/presentation/bloc/employee_group_cubit.dart';
import 'package:owvds/features/hr/work_schedule/data/work_schedule_repository.dart';
import 'package:owvds/features/hr/work_schedule/presentation/bloc/work_schedule_cubit.dart';
import 'package:owvds/features/hr/work_schedule/shift/data/shift_repository.dart';
import 'package:owvds/features/hr/work_schedule/shift/presentation/bloc/shift_cubit.dart';
import 'package:owvds/features/inventory/material/data/material_repository.dart';
import 'package:owvds/features/inventory/material/presentation/bloc/material_cubit.dart';
import 'package:owvds/features/inventory/material_type/data/material_type_repository.dart';
import 'package:owvds/features/inventory/material_type/presentation/bloc/material_type_cubit.dart';
import 'package:owvds/features/inventory/supplier/data/supplier_repository.dart';
import 'package:owvds/features/inventory/supplier/presentation/bloc/supplier_cubit.dart';
import 'package:owvds/features/inventory/supplier_category/data/supplier_category_repository.dart';
import 'package:owvds/features/inventory/supplier_category/presentation/bloc/supplier_category_cubit.dart';
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
    BlocProvider<EmployeeCubit>(
      create: (context) => EmployeeCubit(EmployeeRepository()),
    ),
    BlocProvider<DepartmentCubit>(
      create: (context) => DepartmentCubit(DepartmentRepository()),
    ),
    BlocProvider<ShiftCubit>(
      create: (context) => ShiftCubit(ShiftRepository()),
    ),
    BlocProvider<WorkScheduleCubit>(
      create: (context) => WorkScheduleCubit(WorkScheduleRepository()),
    ),
    BlocProvider<EmployeeGroupCubit>(
      create: (context) => EmployeeGroupCubit(EmployeeGroupRepository()),
    ),

    // Sau này khi thêm các Cubit khác, bạn cũng bắt buộc phải viết rõ tên Cubit trong cặp ngoặc <>.
    // Ví dụ: BlocProvider<DepartmentCubit>(create: (context) => DepartmentCubit()),
    BlocProvider<AreaCubit>(create: (context) => AreaCubit(AreaRepository())),

    // 3. Inventory Providers
    BlocProvider<SupplierCategoryCubit>(
      create: (context) => SupplierCategoryCubit(SupplierCategoryRepository()),
    ),
    BlocProvider<SupplierCubit>(
      create: (context) => SupplierCubit(SupplierRepository()),
    ),
    BlocProvider<MaterialCubit>(
      create: (context) => MaterialCubit(MaterialRepository()),
    ),
    BlocProvider<MaterialTypeCubit>(
      create: (context) => MaterialTypeCubit(MaterialTypeRepository()),
    ),

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
