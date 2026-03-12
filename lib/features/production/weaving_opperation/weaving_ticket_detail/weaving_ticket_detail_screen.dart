import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:owvds/features/production/loom_state/product/presentation/bloc/product_cubit.dart';
import 'package:owvds/features/production/weaving/domain/weaving_model.dart';
import 'package:owvds/features/production/weaving/presentation/bloc/weaving_cubit.dart';
import 'package:owvds/features/production/weaving_opperation/presentation/bloc/machine_operation_cubit.dart';
import 'package:owvds/features/production/weaving_opperation/weaving_ticket_detail/widgets/weaving_ticket_print_button.dart';
import 'package:owvds/features/production/weaving_record/domain/weaving_record_model.dart';
import 'package:owvds/features/production/weaving_record/presentation/bloc/weaving_record_cubit.dart';
import 'package:owvds/features/qc/loom_state_standard/presentation/bloc/loom_state_standard_cubit.dart';

class WeavingTicketDetailScreen extends StatefulWidget {
  final WeavingTicket ticket;

  const WeavingTicketDetailScreen({super.key, required this.ticket});

  @override
  State<WeavingTicketDetailScreen> createState() =>
      _WeavingTicketDetailScreenState();
}

class _WeavingTicketDetailScreenState extends State<WeavingTicketDetailScreen> {
  List<WeavingRecord> _weighingRecords = [];
  bool _isLoadingRecords = true;

  @override
  void initState() {
    super.initState();
    // 1. Load lịch sử kiểm tra (QC)
    context.read<WeavingCubit>().loadInspections(widget.ticket.id);

    // 2. Load lịch sử cân rổ
    _loadWeighingHistory();
  }

  Future<void> _loadWeighingHistory() async {
    try {
      final records = await context
          .read<WeavingRecordCubit>()
          .getRecordsByTicketId(widget.ticket.id);
      if (mounted) {
        setState(() {
          _weighingRecords = records;
          _isLoadingRecords = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRecords = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Chi tiết phiếu dệt", style: TextStyle(fontSize: 16)),
            Text(
              ticket.code,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        actions: [
          WeavingTicketPrintButton(ticket: ticket),
          const SizedBox(width: 8), // Thêm chút khoảng cách lề phải cho đẹp
        ],
      ),
      body: BlocBuilder<WeavingCubit, WeavingState>(
        builder: (context, state) {
          List<WeavingInspection> inspections = [];
          if (state is WeavingLoaded) {
            inspections = state.inspections;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Production Info
                _buildInfoCard("Phần Thông tin sản xuất", [
                  _rowInfo(
                    "Sản phẩm",
                    _ProductFullDetails(id: ticket.productId),
                  ),
                  const SizedBox(height: 8),

                  // [ĐÃ SỬA] Thêm .toString() cho machineLine
                  _rowInfo(
                    "Máy & Line",
                    _MachineInfo(
                      id: ticket.machineId,
                      line: ticket.machineLine.toString(),
                    ),
                  ),
                ]),

                // 2. Standard
                _buildInfoCard("Tiêu chuẩn kỹ thuật", [
                  _StandardFullDetails(standardId: ticket.standardId),
                ]),

                // 3. Materials (Lô sợi - Đã sửa lỗi hiển thị)
                _buildInfoCard("Nguyên liệu (Lô sợi đang dệt)", [
                  _rowInfo(
                    "Lô sợi",
                    _TicketBatchListSimple(yarns: ticket.yarns),
                  ),
                  _rowInfo("Ngày lên sợi", Text(ticket.yarnLoadDate)),
                  _rowInfo(
                    "Rổ chứa",
                    Text(
                      "${ticket.basketCode ?? 'N/A'} (Tare: ${ticket.tareWeight}kg)",
                    ),
                  ),
                ]),

                // 4. Time & Personnel
                _buildInfoCard("Thời gian & Nhân sự", [
                  _rowInfo("Bắt đầu", Text(_formatDateTimeFull(ticket.timeIn))),
                  _rowInfo(
                    "Người đứng máy",
                    Text(ticket.employeeInName ?? "-"),
                  ),
                  if (ticket.timeOut != null) ...[
                    const Divider(),
                    _rowInfo(
                      "Kết thúc",
                      Text(_formatDateTimeFull(ticket.timeOut!)),
                    ),
                    _rowInfo(
                      "Người kết thúc",
                      Text(ticket.employeeOutName ?? "-"),
                    ),
                  ],
                ]),

                // 5. Results
                _buildInfoCard("Kết quả sản xuất", [
                  _rowInfo(
                    "Tổng trọng lượng",
                    Text("${ticket.grossWeight} kg"),
                  ),
                  _rowInfo(
                    "Trọng lượng tịnh",
                    Text(
                      "${ticket.netWeight} kg",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  _rowInfo("Chiều dài", Text("${ticket.lengthMeters} m")),
                  _rowInfo("Số nối/lỗi", Text("${ticket.numberOfKnots}")),
                ]),

                // 6. Lịch sử cân rổ
                const SizedBox(height: 10),
                const Text(
                  "Lịch sử cân rổ",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildWeighingHistoryCard(),

                const SizedBox(height: 20),
                // 8. Inspection History
                const Text(
                  "Lịch sử kiểm tra (QC)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (inspections.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "Chưa có dữ liệu kiểm tra",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: inspections.length,
                    // [SỬA LỖI] Thay (_, __) thành (context, index)
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _buildInspectionItem(inspections[index]),
                  ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
              fontSize: 13,
            ),
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _rowInfo(String label, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: content),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionItem(WeavingInspection item) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      radius: 12,
                      child: Text(
                        "QC",
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.stageName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatDateTimeFull(item.inspectionTime),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            const Divider(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _specBadge("Width: ${item.widthMm}"),
                _specBadge("pick/10cm: ${item.weftDensity}"),
                _specBadge("Độ dầy: ${item.thicknessMm}"),
                _specBadge("Trọng lượng (g/m): ${item.weightGm}"),
                _specBadge("Cong: ${item.bowing}"),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "By: ${item.employeeName ?? '-'}",
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // LỊCH SỬ CÂN RỔ (KÈM NÚT SỬA VÀ XÓA)
  // ==================================================
  Widget _buildWeighingHistoryCard() {
    if (_isLoadingRecords) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_weighingRecords.isEmpty) {
      return const Text(
        "Chưa có lịch sử cân",
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    return Column(
      children: _weighingRecords
          .map(
            (record) => Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.indigo.shade50),
              ),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.monitor_weight, color: Colors.indigo),
                title: Text(
                  "Net: ${record.totalWeight}kg",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dòng 1: Chi tiết phế Run và phế Setup
                      Text(
                        "Phế Run: ${record.runWaste} kg | Phế Setup: ${record.setupWaste} kg",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      // Dòng hiển thị Lý do phế (chỉ hiện nếu có nhập)
                      if (record.runWasteReason != null &&
                          record.runWasteReason!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          "Lý do: ${record.runWasteReason}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.deepOrange,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],

                      const SizedBox(height: 2),

                      // Dòng 2: Tổng phế và Ca làm việc
                      Text(
                        "Tổng phế: ${record.runWaste + record.setupWaste} kg - ${record.shiftName ?? ''}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Dòng 3: Tên người thực hiện và Thời gian
                      Text(
                        "Thực hiện: ${record.updatedByName ?? 'Không xác định'}${record.updatedAt != null ? ' lúc ${_formatDateTimeFull(record.updatedAt!.toIso8601String())}' : ''}",
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onSelected: (val) {
                    if (val == 'EDIT') _showEditRecordDialog(record);
                    if (val == 'DELETE') _confirmDeleteRecord(record);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'EDIT',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text("Sửa"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'DELETE',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Xóa"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // --- XỬ LÝ XÓA BẢN GHI ---
  void _confirmDeleteRecord(WeavingRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa", style: TextStyle(color: Colors.red)),
        content: const Text("Bạn có chắc chắn muốn xóa bản ghi cân rổ này?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoadingRecords = true);

              await context.read<WeavingRecordCubit>().deleteRecord(record.id);
              await _loadWeighingHistory();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Đã xóa bản ghi thành công"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  // --- XỬ LÝ SỬA BẢN GHI ---
  void _showEditRecordDialog(WeavingRecord record) {
    final formKey = GlobalKey<FormState>();
    final netWeightCtrl = TextEditingController(
      text: record.totalWeight.toString(),
    );
    final runWasteCtrl = TextEditingController(
      text: record.runWaste.toString(),
    );
    final setupWasteCtrl = TextEditingController(
      text: record.setupWaste.toString(),
    );
    final reasonCtrl = TextEditingController(text: record.runWasteReason ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Sửa bản ghi cân rổ"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: netWeightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Khối lượng Tịnh (Net - kg)",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || double.tryParse(v) == null)
                    ? "Vui lòng nhập số hợp lệ"
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: runWasteCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Phế Run (kg)",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || double.tryParse(v) == null)
                    ? "Vui lòng nhập số hợp lệ"
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: setupWasteCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Phế Setup (kg)",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || double.tryParse(v) == null)
                    ? "Vui lòng nhập số hợp lệ"
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: "Lý do phế Run",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                setState(() => _isLoadingRecords = true);

                final updatedRecord = WeavingRecord(
                  id: record.id,
                  machineId: record.machineId,
                  line: record.line,
                  basketId: record.basketId,
                  shiftId: record.shiftId,
                  updatedById: record.updatedById,
                  totalWeight: double.parse(netWeightCtrl.text),
                  runWaste: double.parse(runWasteCtrl.text),
                  runWasteReason: reasonCtrl.text,
                  setupWaste: double.parse(setupWasteCtrl.text),
                  updatedAt: DateTime.now(),
                  shiftName: record.shiftName,
                );

                await context.read<WeavingRecordCubit>().saveRecord(
                  item: updatedRecord,
                  isEdit: true,
                );
                await _loadWeighingHistory();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Cập nhật thành công!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  Widget _specBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatDateTimeFull(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('dd/MM HH:mm').format(dt);
    } catch (e) {
      return isoString;
    }
  }
}

class _TicketBatchListSimple extends StatelessWidget {
  final List<WeavingTicketYarn> yarns;
  const _TicketBatchListSimple({required this.yarns});

  @override
  Widget build(BuildContext context) {
    if (yarns.isEmpty) {
      return const Text(
        "Không có dữ liệu sợi",
        style: TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: yarns.map((y) {
        String display =
            "${y.componentType}: ${y.internalBatchCode ?? 'Lô #${y.batchId}'}";
        if (y.supplierShortName != null && y.supplierShortName!.isNotEmpty) {
          display += " [${y.supplierShortName}]";
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            display,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003366),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ProductFullDetails extends StatelessWidget {
  final int id;
  const _ProductFullDetails({required this.id});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state is ProductLoaded) {
          // [SỬA LỖI] Lấy từ allProducts
          final product = state.allProducts
              .where((e) => e.id == id)
              .firstOrNull;
          return Text(
            product?.itemCode ?? "ID: $id",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          );
        }
        return const Text("...");
      },
    );
  }
}

// Sử dụng MachineOperationCubit thay vì MachineCubit
class _MachineInfo extends StatelessWidget {
  final int id;
  final String line;

  const _MachineInfo({required this.id, required this.line});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<MachineOperationCubit, MachineOpState>(
        builder: (c, s) {
          String t = "Line $line";
          if (s is MachineOpLoaded) {
            final m = s.machines.where((e) => e.id == id).firstOrNull;
            if (m != null) t = "${m.machineName} - Line $line";
          }
          return Text(t, style: const TextStyle(fontWeight: FontWeight.bold));
        },
      );
}

class _StandardFullDetails extends StatelessWidget {
  final int standardId;
  const _StandardFullDetails({required this.standardId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StandardCubit, StandardState>(
      builder: (context, state) {
        if (state is StandardLoaded) {
          // [SỬA LỖI] Lấy từ allStandards và so sánh bằng standardId
          final item = state.allStandards
              .where((s) => s.standardId == standardId)
              .firstOrNull;
          if (item == null) return const Text("Chưa có thông tin tiêu chuẩn");

          return Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _sItem("Rộng", "${item.widthMm}mm"),
              _sItem("Dày", "${item.thicknessMm}mm"),
              _sItem("Lực căng", "${item.breakingStrengthDan}dNA"),
              _sItem("pick/10cm", item.weftDensity),
              _sItem("Trọng lượng", "${item.weightGm}g/m"),
            ],
          );
        }
        return const Text("Loading standard...");
      },
    );
  }

  Widget _sItem(String l, String v) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      "$l: $v",
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    ),
  );
}
