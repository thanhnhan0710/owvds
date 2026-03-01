import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/production/loom_state/product/presentation/bloc/product_cubit.dart';
import 'package:owvds/features/production/machine/machine/presentation/bloc/machine_cubit.dart';
import 'package:owvds/features/production/machine/machine_assignment/presentation/bloc/gobal_assignment_cubit.dart';

class BatchAssignDialog extends StatefulWidget {
  const BatchAssignDialog({super.key});

  @override
  State<BatchAssignDialog> createState() => _BatchAssignDialogState();
}

class _BatchAssignDialogState extends State<BatchAssignDialog> {
  int? _selectedProductId;
  final Set<int> _selectedMachineIds = {};
  final Color _primaryColor = const Color(0xFF003366);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Dialog(
      // Trên Mobile sẽ bung tràn viền 100% màn hình
      insetPadding: isMobile
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 0 : 16),
      ),
      child: Container(
        width: isMobile ? double.infinity : 1000,
        height: isMobile ? double.infinity : 750,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 0 : 16),
        ),
        child: Column(
          children: [
            // --- HEADER ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.library_add_check,
                        color: _primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Gán Mã Hàng Loạt',
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    splashRadius: 24,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // --- BODY ---
            Expanded(
              child: isMobile
                  ? _buildMobileBody() // Dùng Tab trên Mobile
                  : _buildDesktopBody(), // Dùng chia đôi cột trên Desktop
            ),

            // --- FOOTER ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Hiển thị tóm tắt cho Mobile
                    if (isMobile)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedProductId != null
                                  ? "✓ Đã chọn 1 Mã hàng"
                                  : "⚠ Chưa chọn Mã hàng",
                              style: TextStyle(
                                color: _selectedProductId != null
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "✓ Đã chọn ${_selectedMachineIds.length} Máy dệt",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (!isMobile) const Spacer(),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: Text(
                        'Gán cho ${_selectedMachineIds.length} Máy',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed:
                          (_selectedProductId == null ||
                              _selectedMachineIds.isEmpty)
                          ? null
                          : () {
                              context
                                  .read<GlobalAssignmentCubit>()
                                  .assignProductToMultipleMachines(
                                    _selectedMachineIds.toList(),
                                    _selectedProductId!,
                                  );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Đã gửi lệnh gán mã hàng loạt!",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // LAYOUTS
  // ==========================================

  Widget _buildMobileBody() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.grey.shade50,
            child: TabBar(
              labelColor: _primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: _primaryColor,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "1. Chọn Mã Hàng"),
                Tab(text: "2. Chọn Máy Dệt"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildProductSelection(isMobile: true),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildMachineSelection(isMobile: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopBody() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.all(24),
            child: _buildProductSelection(isMobile: false),
          ),
        ),
        Container(width: 1, color: Colors.grey.shade200), // Vách ngăn mỏng
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: _buildMachineSelection(isMobile: false),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // WIDGET TÌM KIẾM
  // ==========================================

  Widget _buildCompactSearchField({
    required String hintText,
    required Function(String) onChanged,
  }) {
    return TextField(
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primaryColor),
        ),
      ),
      onChanged: onChanged,
    );
  }

  // ==========================================
  // CỘT 1: CHỌN SẢN PHẨM (CARD STYLE)
  // ==========================================

  Widget _buildProductSelection({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMobile) ...[
          const Text(
            "BƯỚC 1: CHỌN MÃ HÀNG",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
        ],
        _buildCompactSearchField(
          hintText: 'Tìm kiếm mã SP, tên SP...',
          onChanged: (val) => context.read<ProductCubit>().searchProducts(val),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: BlocBuilder<ProductCubit, ProductState>(
            builder: (context, state) {
              if (state is ProductLoaded) {
                if (state.displayedProducts.isEmpty)
                  return Center(
                    child: Text(
                      "Không tìm thấy sản phẩm",
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  );

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: state.displayedProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(
                    height: 8,
                  ), // Dùng khoảng trắng thay cho đường kẻ
                  itemBuilder: (context, index) {
                    final p = state.displayedProducts[index];
                    final isSelected = _selectedProductId == p.id;

                    return InkWell(
                      onTap: () => setState(() => _selectedProductId = p.id),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _primaryColor.withOpacity(0.06)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? _primaryColor
                                : Colors.grey.shade200,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? _primaryColor
                                  : Colors.grey.shade400,
                              size: 22,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.itemCode,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isSelected
                                          ? _primaryColor
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    p.note,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CỘT 2: CHỌN MÁY (CARD STYLE)
  // ==========================================

  Widget _buildMachineSelection({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMobile) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "BƯỚC 2: CHỌN MÁY DỆT",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Đã chọn: ${_selectedMachineIds.length}",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        _buildCompactSearchField(
          hintText: 'Tìm theo tên máy, khu vực...',
          onChanged: (val) => context.read<MachineCubit>().searchMachines(val),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: BlocBuilder<MachineCubit, MachineState>(
            builder: (context, state) {
              if (state is MachineLoaded) {
                final weavingMachines = state.displayedMachines
                    .where((m) => m.polymorphicType == 'weaving_machine')
                    .toList();
                final isAllSelected =
                    _selectedMachineIds.length >= weavingMachines.length &&
                    weavingMachines.isNotEmpty;

                return Column(
                  children: [
                    // Nút chọn tất cả (Tạo hình giống một thẻ bấm được)
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isAllSelected) {
                            _selectedMachineIds.removeAll(
                              weavingMachines.map((m) => m.id),
                            );
                          } else {
                            _selectedMachineIds.addAll(
                              weavingMachines.map((m) => m.id),
                            );
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isAllSelected
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: isAllSelected
                                  ? Colors.blue
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Chọn tất cả máy trong danh sách",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: weavingMachines.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final m = weavingMachines[index];
                          final isSelected = _selectedMachineIds.contains(m.id);

                          return InkWell(
                            onTap: () {
                              setState(() {
                                isSelected
                                    ? _selectedMachineIds.remove(m.id)
                                    : _selectedMachineIds.add(m.id);
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue.withOpacity(0.06)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey.shade200,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.grey.shade400,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.machineName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: isSelected
                                                ? Colors.blue.shade800
                                                : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              m.area?.areaName ??
                                                  'Chưa phân khu',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ],
    );
  }
}
