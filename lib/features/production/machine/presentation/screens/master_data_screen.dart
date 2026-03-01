import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/production/machine/machine_status/presentation/bloc/machine_status_cubit.dart';
import 'package:owvds/features/production/machine/machine_type/presentation/bloc/machine_type_cubit.dart';
import '../dialogs/machine_type_dialog.dart';
import '../dialogs/machine_status_dialog.dart';

class MasterDataScreen extends StatelessWidget {
  final int initialIndex; // 0: Loại máy, 1: Trạng thái

  const MasterDataScreen({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF003366),
          elevation: 0.5,
          title: const Text(
            "Quản lý Danh mục Cấu hình",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF003366),
            indicatorColor: Color(0xFF003366),
            tabs: [
              Tab(
                icon: Icon(Icons.precision_manufacturing),
                text: "Loại máy móc",
              ),
              Tab(icon: Icon(Icons.monitor_heart), text: "Trạng thái máy"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_MachineTypeTab(), _MachineStatusTab()],
        ),
      ),
    );
  }
}

// ==========================================
// TAB: LOẠI MÁY
// ==========================================
class _MachineTypeTab extends StatelessWidget {
  const _MachineTypeTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm loại máy...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) =>
                      context.read<MachineTypeCubit>().searchTypes(val),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text("Thêm Loại Mới"),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const MachineTypeDialog(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
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
              child: BlocBuilder<MachineTypeCubit, MachineTypeState>(
                builder: (context, state) {
                  if (state is MachineTypeLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is MachineTypeLoaded) {
                    if (state.types.isEmpty) {
                      return const Center(child: Text("Không có dữ liệu"));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: state.types.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final t = state.types[index];
                        return ListTile(
                          title: Text(
                            t.typeName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            t.description ?? 'Không có mô tả',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) => MachineTypeDialog(type: t),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () => context
                                    .read<MachineTypeCubit>()
                                    .deleteType(t.id),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB: TRẠNG THÁI
// ==========================================
class _MachineStatusTab extends StatelessWidget {
  const _MachineStatusTab();

  Color _hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.grey;
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm trạng thái...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) =>
                      context.read<MachineStatusCubit>().searchStatuses(val),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text("Thêm Trạng Thái"),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const MachineStatusDialog(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
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
              child: BlocBuilder<MachineStatusCubit, MachineStatusState>(
                builder: (context, state) {
                  if (state is MachineStatusLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is MachineStatusLoaded) {
                    if (state.statuses.isEmpty) {
                      return const Center(child: Text("Không có dữ liệu"));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: state.statuses.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final s = state.statuses[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _hexToColor(s.colorCode),
                            radius: 14,
                          ),
                          title: Text(
                            s.statusName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            s.description ?? 'Không có mô tả',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) =>
                                      MachineStatusDialog(status: s),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () => context
                                    .read<MachineStatusCubit>()
                                    .deleteStatus(s.id),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
