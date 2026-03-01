import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/area/presentation/bloc/area_cubit.dart';
import 'package:owvds/features/production/machine/machine/domain/machine_model.dart';
import 'package:owvds/features/production/machine/machine/presentation/bloc/machine_cubit.dart';
import 'package:owvds/features/production/machine/presentation/dialogs/area_dialog.dart';

class AreaSidebar extends StatelessWidget {
  final int? selectedAreaId;
  final Function(int?) onAreaSelected;

  const AreaSidebar({
    super.key,
    required this.selectedAreaId,
    required this.onAreaSelected,
  });

  final Color _primaryColor = const Color(0xFF003366);

  void _confirmDelete(BuildContext context, int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Xóa khu vực "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<AreaCubit>().deleteArea(id);
              if (selectedAreaId == id) onAreaSelected(null);
              Navigator.pop(ctx);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Khu vực",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor.withOpacity(0.1),
                    foregroundColor: _primaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 32),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Thêm',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const AreaDialog(),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm khu vực...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (val) => context.read<AreaCubit>().searchAreas(val),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: BlocBuilder<MachineCubit, MachineState>(
              builder: (context, machineState) {
                int totalMachines = 0;
                List<Machine> allMachines = [];
                if (machineState is MachineLoaded) {
                  allMachines = machineState.allMachines;
                  totalMachines = allMachines.length;
                }

                return BlocBuilder<AreaCubit, AreaState>(
                  builder: (context, areaState) {
                    if (areaState is AreaLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (areaState is AreaLoaded) {
                      return ListView(
                        children: [
                          _buildItem(
                            context,
                            id: null,
                            name: "Tất cả khu vực",
                            count: totalMachines,
                          ),
                          ...areaState.areas.map((a) {
                            int count = allMachines
                                .where((m) => m.areaId == a.id)
                                .length;
                            return _buildItem(
                              context,
                              id: a.id,
                              name: a.areaName,
                              count: count,
                              onEdit: () => showDialog(
                                context: context,
                                builder: (_) => AreaDialog(area: a),
                              ),
                              onDelete: () =>
                                  _confirmDelete(context, a.id, a.areaName),
                            );
                          }),
                        ],
                      );
                    }
                    return const SizedBox();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required int? id,
    required String name,
    required int count,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    final isSelected = selectedAreaId == id;
    return Container(
      color: isSelected ? _primaryColor.withOpacity(0.08) : Colors.transparent,
      child: ListTile(
        selected: isSelected,
        leading: Icon(
          id == null ? Icons.dashboard : Icons.location_on,
          color: isSelected ? _primaryColor : Colors.grey,
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          "$count máy",
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        trailing: id == null
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16),
                    onPressed: onEdit,
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    onPressed: onDelete,
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
        onTap: () => onAreaSelected(id),
      ),
    );
  }
}
