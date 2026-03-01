import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/production/machine/machine/domain/machine_model.dart';
import 'package:owvds/features/production/machine/machine/presentation/bloc/machine_cubit.dart';
import 'package:owvds/features/production/machine/machine_type/domain/machine_type_model.dart';
import 'package:owvds/features/production/machine/machine_type/presentation/bloc/machine_type_cubit.dart';
import '../dialogs/machine_dialog.dart';

class MachineListView extends StatefulWidget {
  final int? selectedAreaId;
  const MachineListView({super.key, this.selectedAreaId});

  @override
  State<MachineListView> createState() => _MachineListViewState();
}

class _MachineListViewState extends State<MachineListView> {
  final Color _primaryColor = const Color(0xFF003366);
  int? _filterTypeId;

  @override
  void initState() {
    super.initState();
    context.read<MachineTypeCubit>().loadTypes();
  }

  void _onTypeFilterChanged(int? typeId) {
    setState(() => _filterTypeId = typeId);
    context.read<MachineCubit>().loadMachines(
      filterAreaId: widget.selectedAreaId,
      filterStatusId: null,
    );
  }

  Color _hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.grey;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    // Xác định xem màn hình hiện tại có phải mobile không (width < 600)
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- THANH TÌM KIẾM VÀ BỘ LỌC TỐI ƯU RESPONSIVE ---
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTypeFilter()),
                        const SizedBox(width: 12),
                        _buildAddButton(isMobile),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 2, child: _buildSearchBar()),
                    const SizedBox(width: 12),
                    Expanded(flex: 1, child: _buildTypeFilter()),
                    const SizedBox(width: 12),
                    _buildAddButton(isMobile),
                  ],
                ),
        ),

        // --- BẢNG DỮ LIỆU / DANH SÁCH THẺ ---
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                // Chỉ hiển thị Header Row dạng bảng khi KHÔNG phải mobile
                if (!isMobile)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildHeaderCell("Trạng thái", flex: 2),
                        _buildHeaderCell("Tên Máy / Seri", flex: 3),
                        _buildHeaderCell("Phân loại", flex: 2),
                        _buildHeaderCell("Thông số kỹ thuật", flex: 3),
                        _buildHeaderCell(
                          "Thao tác",
                          flex: 2,
                          align: TextAlign.right,
                        ),
                      ],
                    ),
                  ),

                // Nội dung danh sách
                Expanded(
                  child: BlocBuilder<MachineCubit, MachineState>(
                    builder: (context, state) {
                      if (state is MachineLoading)
                        return const Center(child: CircularProgressIndicator());
                      if (state is MachineLoaded) {
                        var machines = state.displayedMachines;
                        if (_filterTypeId != null) {
                          machines = machines
                              .where((m) => m.machineTypeId == _filterTypeId)
                              .toList();
                        }

                        if (machines.isEmpty) {
                          return const Center(
                            child: Text(
                              "Không có máy móc nào",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: machines.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey.shade200),
                          itemBuilder: (context, index) {
                            // Render giao diện tuỳ thuộc vào kích thước màn hình
                            return isMobile
                                ? _buildMobileCard(context, machines[index])
                                : _buildDesktopRow(context, machines[index]);
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
        ),
      ],
    );
  }

  // ==========================================
  // WIDGETS THANH CÔNG CỤ
  // ==========================================
  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Tìm seri, tên máy...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (val) => context.read<MachineCubit>().searchMachines(val),
    );
  }

  Widget _buildTypeFilter() {
    return BlocBuilder<MachineTypeCubit, MachineTypeState>(
      builder: (context, state) {
        List<MachineType> types = [];
        if (state is MachineTypeLoaded) types = state.types;

        bool typeExists =
            _filterTypeId == null || types.any((t) => t.id == _filterTypeId);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              hint: const Text(
                "Tất cả loại máy",
                style: TextStyle(fontSize: 13),
              ),
              value: typeExists ? _filterTypeId : null,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text(
                    "Tất cả loại máy",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                ...types.map(
                  (t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(
                      t.typeName,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
              onChanged: _onTypeFilterChanged,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddButton(bool isMobile) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 24,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.add, size: 20),
      label: Text(
        isMobile ? 'Thêm' : 'Thêm máy',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      onPressed: () => showDialog(
        context: context,
        builder: (_) => MachineDialog(
          initialAreaId: widget.selectedAreaId,
          initialTypeId: _filterTypeId,
        ),
      ),
    );
  }

  Widget _buildHeaderCell(
    String text, {
    required int flex,
    TextAlign align = TextAlign.left,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF003366),
          fontSize: 13,
        ),
      ),
    );
  }

  // ==========================================
  // GIAO DIỆN DÀNH CHO DESKTOP (DẠNG BẢNG NGANG)
  // ==========================================
  Widget _buildDesktopRow(BuildContext context, Machine m) {
    Color statusColor = _hexToColor(m.status?.colorCode);

    return InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (_) => MachineDialog(machine: m),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    m.status?.statusName ?? "Unknown",
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.machineName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (m.serialNumber != null && m.serialNumber!.isNotEmpty)
                    Text(
                      "SN: ${m.serialNumber}",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(
                    m.polymorphicType == 'weaving_machine'
                        ? Icons.precision_manufacturing
                        : Icons.water_drop,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      m.machineType?.typeName ?? "Chưa phân loại",
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (m.polymorphicType == 'weaving_machine') ...[
                    Text(
                      "Số line: ${m.totalLines ?? '?'}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      "Tốc độ: ${m.speed ?? '?'} RPM",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ] else if (m.polymorphicType == 'dyeing_machine') ...[
                    Text(
                      "Công suất: ${m.capacityKg ?? '?'} Kg",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      "Nhiệt độ max: ${m.maxTemperature ?? '?'} °C",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 18,
                        color: Colors.blue,
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => MachineDialog(machine: m),
                      ),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      splashRadius: 24,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: () =>
                          context.read<MachineCubit>().deleteMachine(m.id),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      splashRadius: 24,
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
  // GIAO DIỆN DÀNH CHO MOBILE (DẠNG THẺ DỌC)
  // ==========================================
  Widget _buildMobileCard(BuildContext context, Machine m) {
    Color statusColor = _hexToColor(m.status?.colorCode);

    return InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (_) => MachineDialog(machine: m),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dòng 1: Status & Type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        m.status?.statusName ?? "Unknown",
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      m.polymorphicType == 'weaving_machine'
                          ? Icons.precision_manufacturing
                          : Icons.water_drop,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      m.machineType?.typeName ?? "Chưa phân loại",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Dòng 2: Tên & Seri
            Text(
              m.machineName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (m.serialNumber != null && m.serialNumber!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "SN: ${m.serialNumber}",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            const SizedBox(height: 12),

            // Dòng 3: Thông số kỹ thuật (Hiển thị kiểu block gọn gàng)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (m.polymorphicType == 'weaving_machine') ...[
                    Text(
                      "Số line: ${m.totalLines ?? '?'}",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Tốc độ: ${m.speed ?? '?'} RPM",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ] else if (m.polymorphicType == 'dyeing_machine') ...[
                    Text(
                      "Công suất: ${m.capacityKg ?? '?'} Kg",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Nhiệt độ max: ${m.maxTemperature ?? '?'} °C",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ] else ...[
                    Text(
                      "Hệ máy cơ bản",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Dòng 4: Thao tác
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Sửa'),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => MachineDialog(machine: m),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Colors.red,
                  ),
                  label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                  onPressed: () =>
                      context.read<MachineCubit>().deleteMachine(m.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
