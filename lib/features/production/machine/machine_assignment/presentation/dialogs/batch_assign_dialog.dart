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

  // [MỚI]: Map lưu Máy ID -> Danh sách Line Number được chọn
  final Map<int, Set<int>> _selectedMachineLines = {};

  final Color _primaryColor = const Color(0xFF003366);

  int get _totalSelectedMachines => _selectedMachineLines.keys.length;
  int get _totalSelectedLines =>
      _selectedMachineLines.values.fold(0, (sum, lines) => sum + lines.length);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Dialog(
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
                        'Gán Mã Hàng Loạt (Theo Line)',
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
              child: isMobile ? _buildMobileBody() : _buildDesktopBody(),
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
                              "✓ Đã chọn $_totalSelectedLines Line (Của $_totalSelectedMachines Máy)",
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
                        'Gán vào $_totalSelectedLines Line',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed:
                          (_selectedProductId == null ||
                              _selectedMachineLines.isEmpty)
                          ? null
                          : () {
                              context
                                  .read<GlobalAssignmentCubit>()
                                  .assignProductToMultipleMachines(
                                    _selectedMachineLines,
                                    _selectedProductId!,
                                  );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Đã gửi lệnh gán mã hàng loạt tới các Line!",
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
                Tab(text: "2. Chọn Line Máy"),
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
        Container(width: 1, color: Colors.grey.shade200),
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
  // CỘT 1: CHỌN SẢN PHẨM
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
                if (state.displayedProducts.isEmpty) {
                  return Center(
                    child: Text(
                      "Không tìm thấy sản phẩm",
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: state.displayedProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                                    p.note.isNotEmpty
                                        ? p.note
                                        : (p.productType?.typeName ??
                                              'Không có ghi chú'),
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
  // CỘT 2: CHỌN MÁY VÀ CHỌN LINE
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
                "BƯỚC 2: CHỌN LINE THEO MÁY",
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
                  "Đã chọn: $_totalSelectedLines Line",
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

                // Tính tổng số line có thể chọn
                int totalAvailableLines = weavingMachines.fold(
                  0,
                  (sum, m) => sum + (m.totalLines ?? 1),
                );
                final bool isAllSelected =
                    _totalSelectedLines == totalAvailableLines &&
                    totalAvailableLines > 0;

                return Column(
                  children: [
                    // Nút chọn TẤT CẢ các Line của TẤT CẢ máy
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isAllSelected) {
                            _selectedMachineLines.clear();
                          } else {
                            for (var m in weavingMachines) {
                              _selectedMachineLines[m.id] = Set.from(
                                List.generate(m.totalLines ?? 1, (i) => i + 1),
                              );
                            }
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
                              "Chọn tất cả Line trong danh sách",
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

                    // Danh sách máy và Line
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: weavingMachines.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final m = weavingMachines[index];
                          final int totalLines = m.totalLines ?? 1;
                          final Set<int> selectedLines =
                              _selectedMachineLines[m.id] ?? {};

                          // Trạng thái Checkbox của riêng Máy này
                          final bool isMachineAllSelected =
                              selectedLines.length == totalLines;
                          final bool isMachinePartialSelected =
                              selectedLines.isNotEmpty &&
                              selectedLines.length < totalLines;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selectedLines.isNotEmpty
                                    ? Colors.blue.shade200
                                    : Colors.grey.shade200,
                                width: selectedLines.isNotEmpty ? 1.5 : 1,
                              ),
                              boxShadow: [
                                if (selectedLines.isNotEmpty)
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tên Máy + Checkbox chọn toàn bộ máy
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isMachineAllSelected) {
                                        _selectedMachineLines.remove(m.id);
                                      } else {
                                        _selectedMachineLines[m.id] = Set.from(
                                          List.generate(
                                            totalLines,
                                            (i) => i + 1,
                                          ),
                                        );
                                      }
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        isMachineAllSelected
                                            ? Icons.check_box
                                            : (isMachinePartialSelected
                                                  ? Icons
                                                        .indeterminate_check_box
                                                  : Icons
                                                        .check_box_outline_blank),
                                        color: selectedLines.isNotEmpty
                                            ? Colors.blue
                                            : Colors.grey.shade400,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          m.machineName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: selectedLines.isNotEmpty
                                                ? Colors.blue.shade800
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "${selectedLines.length}/$totalLines",
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (totalLines > 0) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Divider(height: 1),
                                  ),
                                  // Hiển thị các Checkbox (Chip) đại diện cho từng Line
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List.generate(totalLines, (i) {
                                      final line = i + 1;
                                      final isLineSelected = selectedLines
                                          .contains(line);

                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (isLineSelected) {
                                              _selectedMachineLines[m.id]
                                                  ?.remove(line);
                                              if (_selectedMachineLines[m.id]!
                                                  .isEmpty) {
                                                _selectedMachineLines.remove(
                                                  m.id,
                                                );
                                              }
                                            } else {
                                              _selectedMachineLines
                                                  .putIfAbsent(m.id, () => {})
                                                  .add(line);
                                            }
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 150,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isLineSelected
                                                ? Colors.blue.shade50
                                                : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: isLineSelected
                                                  ? Colors.blue.shade300
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isLineSelected
                                                    ? Icons.check_circle
                                                    : Icons.circle_outlined,
                                                size: 14,
                                                color: isLineSelected
                                                    ? Colors.blue
                                                    : Colors.grey.shade500,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "Line $line",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: isLineSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  color: isLineSelected
                                                      ? Colors.blue.shade800
                                                      : Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ],
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
