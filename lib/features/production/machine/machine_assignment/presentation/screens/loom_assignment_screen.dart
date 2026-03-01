import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/core/widgets/responsive_layout.dart';
import 'package:owvds/features/production/loom_state/product/domain/product_model.dart';
import 'package:owvds/features/production/loom_state/product/presentation/bloc/product_cubit.dart';
import 'package:owvds/features/production/machine/machine/presentation/bloc/machine_cubit.dart';

import '../dialogs/machine_control_dialog.dart';

class LoomAssignmentScreen extends StatefulWidget {
  const LoomAssignmentScreen({super.key});

  @override
  State<LoomAssignmentScreen> createState() => _LoomAssignmentScreenState();
}

class _LoomAssignmentScreenState extends State<LoomAssignmentScreen> {
  Product? _selectedProduct;

  @override
  void initState() {
    super.initState();
    // Tải danh sách sản phẩm và máy móc khi vào màn hình
    context.read<ProductCubit>().loadProducts();
    context.read<MachineCubit>().loadMachines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Điều độ Sản xuất (Gán Mã Hàng)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF003366),
        elevation: 0.5,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- CỘT TRÁI: DANH SÁCH MÃ HÀNG ---
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm mã hàng...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) =>
                        context.read<ProductCubit>().searchProducts(val),
                  ),
                ),
                Expanded(
                  child: BlocBuilder<ProductCubit, ProductState>(
                    builder: (context, state) {
                      if (state is ProductLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is ProductLoaded) {
                        return ListView.separated(
                          itemCount: state.displayedProducts.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey.shade100),
                          itemBuilder: (context, index) {
                            final p = state.displayedProducts[index];
                            final isSelected = _selectedProduct?.id == p.id;

                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: const Color(
                                0xFF003366,
                              ).withOpacity(0.08),
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? const Color(0xFF003366)
                                    : Colors.grey.shade200,
                                child: Icon(
                                  Icons.inventory_2,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                p.itemCode,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                p.note,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => setState(() => _selectedProduct = p),
                            );
                          },
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          ),

          // --- CỘT PHẢI: DANH SÁCH MÁY DỆT ---
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedProduct == null
                              ? "Vui lòng chọn một Mã hàng ở cột bên trái, sau đó chọn Máy dệt để gán."
                              : "Đang chọn mã hàng: ${_selectedProduct!.itemCode}. Bấm vào một máy dệt bên dưới để gán.",
                          style: TextStyle(
                            color: _selectedProduct == null
                                ? Colors.grey.shade700
                                : Colors.blue.shade800,
                            fontWeight: _selectedProduct == null
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocBuilder<MachineCubit, MachineState>(
                    builder: (context, state) {
                      if (state is MachineLoading)
                        return const Center(child: CircularProgressIndicator());
                      if (state is MachineLoaded) {
                        // CHỈ LỌC CÁC MÁY DỆT
                        final weavingMachines = state.allMachines
                            .where(
                              (m) => m.polymorphicType == 'weaving_machine',
                            )
                            .toList();

                        // Lấy chiều rộng màn hình để chia cột thay cho hàm isTablet() bị thiếu
                        final screenWidth = MediaQuery.of(context).size.width;
                        int crossAxisCount = 4; // Desktop
                        if (ResponsiveLayout.isMobile(context)) {
                          crossAxisCount = 2; // Mobile
                        } else if (screenWidth < 1100) {
                          crossAxisCount = 3; // Kích thước Tablet/Màn hình vừa
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: 1.2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: weavingMachines.length,
                          itemBuilder: (context, index) {
                            final m = weavingMachines[index];
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (_) => MachineControlDialog(
                                    machine: m,
                                    selectedProduct: _selectedProduct,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.precision_manufacturing,
                                        size: 40,
                                        color: Color(0xFF003366),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        m.machineName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        m.area?.areaName ?? 'Chưa phân khu',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
