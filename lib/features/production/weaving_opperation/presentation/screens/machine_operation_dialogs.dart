import 'dart:io' as io;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:owvds/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:owvds/features/hr/work_schedule/shift/presentation/bloc/shift_cubit.dart';
import 'package:owvds/features/inventory/material_export/data/material_export_repository.dart';
import 'package:owvds/features/production/basket/doamain/basket_model.dart';
import 'package:owvds/features/production/basket/presentation/bloc/baket_cubit.dart';
import 'package:owvds/features/production/machine/machine/domain/machine_model.dart';
import 'package:owvds/features/production/machine/machine_assignment/domain/machine_assignment_model.dart';
import 'package:owvds/features/production/weaving/domain/weaving_model.dart';
import 'package:owvds/features/production/weaving/presentation/bloc/weaving_cubit.dart';
import 'package:owvds/features/production/weaving_opperation/presentation/bloc/machine_operation_cubit.dart';
import 'package:owvds/features/production/weaving_opperation/presentation/dialogs/weaving_inspection_dialog.dart';
import 'package:owvds/features/production/weaving_opperation/weaving_ticket_detail/weaving_ticket_detail_screen.dart';
import 'package:owvds/features/production/weaving_record/domain/weaving_record_model.dart';
import 'package:owvds/features/production/weaving_record/presentation/bloc/weaving_record_cubit.dart';
import 'package:owvds/features/qc/bom/presentation/bloc/bom_cubit.dart';
import 'package:owvds/features/qc/loom_state_standard/presentation/bloc/loom_state_standard_cubit.dart';
import 'package:owvds/l10n/app_localizations.dart';

import 'machine_operation_utils.dart';
import '../widgets/line_item_widget.dart';

// =============================================================================
// MENU 3 CHẤM -> DIALOG CHỌN TRẠNG THÁI CHO NHIỀU LINE
// =============================================================================

void showMultiLineStatusDialog(
  BuildContext context,
  Machine machine,
  String newStatus,
  int totalLines,
  AppLocalizations l10n,
) {
  final bool isIssue = newStatus == 'STOPPED' || newStatus == 'MAINTENANCE';
  final localizedNewStatus = getLocalizedStatus(newStatus, l10n);

  Map<int, bool> selectedLines = {
    for (var i = 1; i <= totalLines; i++) i: false,
  };
  Map<int, TextEditingController> reasonCtrls = {
    for (var i = 1; i <= totalLines; i++) i: TextEditingController(),
  };

  XFile? capturedImage;
  final ImagePicker picker = ImagePicker();
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          title: Text(
            l10n.changeStatusTitle(localizedNewStatus),
            style: TextStyle(
              color: getMachineStatusColor(newStatus),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: getMachineStatusColor(
                          newStatus,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: getMachineStatusColor(newStatus),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Đang thao tác trên: ${machine.machineName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '1. Chọn Line muốn chuyển trạng thái:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    ...List.generate(totalLines, (index) {
                      final lineIndex = index + 1;
                      final isSelected = selectedLines[lineIndex]!;
                      return Column(
                        children: [
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Line $lineIndex',
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey.shade700,
                              ),
                            ),
                            value: isSelected,
                            activeColor: getMachineStatusColor(newStatus),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (val) {
                              setStateDialog(
                                () => selectedLines[lineIndex] = val ?? false,
                              );
                            },
                          ),
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 48.0,
                                bottom: 8.0,
                                right: 8.0,
                              ),
                              child: TextFormField(
                                controller: reasonCtrls[lineIndex],
                                decoration: InputDecoration(
                                  labelText: isIssue
                                      ? 'Lý do Line $lineIndex (Bắt buộc)'
                                      : 'Ghi chú Line $lineIndex',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                validator: isIssue
                                    ? (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Vui lòng nhập lý do';
                                        }
                                        return null;
                                      }
                                    : null,
                              ),
                            ),
                        ],
                      );
                    }),

                    if (isIssue) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        '2. Hình ảnh sự cố (Tùy chọn)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (capturedImage != null) ...[
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Container(
                              height: 150,
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: kIsWeb
                                    ? Image.network(
                                        capturedImage!.path,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        io.File(capturedImage!.path),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  setStateDialog(() => capturedImage = null),
                              icon: const Icon(Icons.close, color: Colors.red),
                            ),
                          ],
                        ),
                      ],
                      ElevatedButton.icon(
                        onPressed: () async {
                          final XFile? photo = await picker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 50,
                          );
                          if (photo != null)
                            setStateDialog(() => capturedImage = photo);
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Chụp ảnh'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                bool hasSelected = selectedLines.values.any((v) => v);
                if (!hasSelected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng chọn ít nhất 1 line!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (formKey.currentState!.validate()) {
                  List<String> combinedNotes = [];
                  for (int i = 1; i <= totalLines; i++) {
                    final key = '${machine.id}_$i';
                    if (selectedLines[i]!) {
                      globalLineStatuses[key] = newStatus.toUpperCase();

                      final text = reasonCtrls[i]!.text.trim();
                      if (text.isNotEmpty) {
                        combinedNotes.add('[Line $i] $text');
                      } else {
                        combinedNotes.add('[Line $i]');
                      }
                    } else {
                      if (!globalLineStatuses.containsKey(key)) {
                        globalLineStatuses[key] = 'NORMAL';
                      }
                    }
                  }

                  final finalReason = combinedNotes.join(' | ');

                  context.read<MachineOperationCubit>().updateMachineStatus(
                    machineId: machine.id,
                    status: newStatus,
                    reason: finalReason,
                    imageFile: capturedImage,
                  );
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: getMachineStatusColor(newStatus),
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    ),
  );
}

// =============================================================================
// ĐIỀU PHỐI: Xử lý tap vào một Line
// =============================================================================

Future<void> handleLineTap(
  BuildContext context,
  Machine machine,
  String lineCode,
  WeavingTicket? ticket,
  List<Basket> readyBaskets,
  AppLocalizations l10n,
  MachineProductHistory? activeLoom,
) async {
  if (activeLoom == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Máy chưa được gán sản phẩm để chạy! Vui lòng phân công lệnh sản xuất.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final exportRepo = MaterialExportRepository();
    final activeBatches = await exportRepo.getActiveBatchesOnMachine(
      machine.id,
      activeLoom.productId,
    );

    if (!context.mounted) {
      return;
    }
    Navigator.pop(context);

    if (activeBatches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máy chưa có sợi, vui lòng xuất sợi từ kho trước.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    // Mở DIALOG (Giữa màn hình)
    showLineDetailDialog(
      context,
      machine,
      lineCode,
      ticket,
      l10n,
      activeLoom,
      activeBatches,
    );
  } on DioException catch (e) {
    if (!context.mounted) {
      return;
    }
    Navigator.pop(context);
    String errorDetail = e.message ?? 'Lỗi không xác định';
    if (e.response != null && e.response?.data != null) {
      errorDetail = e.response?.data.toString() ?? errorDetail;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('API Backend từ chối dữ liệu (Lỗi 422):\n$errorDetail'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 8),
      ),
    );
  } catch (e) {
    if (!context.mounted) {
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi ứng dụng: $e'), backgroundColor: Colors.red),
    );
  }
}

// =============================================================================
// DIALOG: Chi tiết Line — Căn giữa màn hình
// =============================================================================

void showLineDetailDialog(
  BuildContext context,
  Machine machine,
  String lineCode,
  WeavingTicket? ticket,
  AppLocalizations l10n,
  MachineProductHistory activeLoom,
  List<dynamic> activeBatches,
) {
  final localStatus = globalLineStatuses['${machine.id}_$lineCode'];
  final String ms = (machine.status?.statusName ?? '').toUpperCase();
  String lineStatus;

  // [ĐÃ SỬA LOGIC]: Tôn trọng tuyệt đối thao tác chọn trạng thái của người dùng
  if (localStatus != null && localStatus != 'NORMAL') {
    lineStatus = localStatus;
  } else {
    if (ms == 'STOPPED') {
      lineStatus = 'STOPPED';
    } else if (ms == 'MAINTENANCE') {
      lineStatus = 'MAINTENANCE';
    } else if (ms == 'SPINNING') {
      lineStatus = 'SPINNING';
    } else if (ms == 'YARNOUT') {
      lineStatus = 'YARNOUT';
    } else if (ms == 'SPLICING') {
      lineStatus = 'SPLICING';
    } else if (ticket != null) {
      lineStatus = 'RUNNING';
    } else {
      lineStatus = 'IDLE';
    }
  }

  final Color statusBg = LineItem.bgColor(lineStatus);
  final Color statusFg = LineItem.textColor(lineStatus);
  final String productCode = activeLoom.product?.itemCode ?? 'N/A';
  final bool isMachineBlocked =
      lineStatus == 'STOPPED' || lineStatus == 'MAINTENANCE';

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${machine.machineName}  •  Line $lineCode',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kMachineOpPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                LineItem.shortLabel(lineStatus),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: statusFg,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mã sản phẩm đang chạy',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              productCode,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.blueAccent,
              ),
              textAlign: TextAlign.center,
            ),
            if (ticket?.basketCode != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Rổ hiện tại',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_basket,
                    color: Colors.teal,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ticket!.basketCode!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),

            if (ticket == null && !isMachineBlocked)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_basket, size: 22),
                  label: const Text(
                    'VÀO RỔ / TẠO PHIẾU',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMachineOpPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    showAssignBasketAndCreateTicketDialog(
                      context,
                      machine,
                      lineCode,
                      l10n,
                      activeLoom,
                      activeBatches,
                    );
                  },
                ),
              )
            else if (ticket != null)
              Column(
                children: [
                  _dialogActionBtn(
                    icon: Icons.info_outline,
                    color: Colors.teal,
                    label: l10n.viewTicket,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              WeavingTicketDetailScreen(ticket: ticket),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _dialogActionBtn(
                    icon: Icons.fact_check,
                    color: Colors.blue,
                    label: 'Kiểm tra chất lượng',
                    onTap: () {
                      Navigator.pop(ctx);
                      final autoShift = calculateCurrentShiftName();
                      context.read<WeavingCubit>().loadInspections(ticket.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WeavingInspectionScreen(
                            ticket: ticket,
                            shiftName: autoShift,
                            onRelease: () {
                              Navigator.pop(context);
                              showReleaseDialog(context, ticket, l10n);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _dialogActionBtn(
                    icon: Icons.monitor_weight,
                    color: Colors.indigo,
                    label: 'Cân rổ cuối ca',
                    onTap: () {
                      Navigator.pop(ctx);
                      handleWeighingCheck(context, machine, lineCode, ticket);
                    },
                  ),
                  const SizedBox(height: 10),
                  _dialogActionBtn(
                    icon: Icons.stop_circle,
                    color: Colors.red,
                    label: 'Ra rổ',
                    isPrimary: true,
                    onTap: () {
                      Navigator.pop(ctx);
                      showReleaseDialog(context, ticket, l10n);
                    },
                  ),
                ],
              )
            else if (isMachineBlocked)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Line này đang bị khoá do sự cố.\nVui lòng chuyển trạng thái từ Menu 3 chấm trước.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _dialogActionBtn({
  required IconData icon,
  required Color color,
  required String label,
  required VoidCallback onTap,
  bool isPrimary = false,
}) {
  return SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      icon: Icon(icon, color: isPrimary ? Colors.white : color),
      label: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: isPrimary ? Colors.white : Colors.black87,
        backgroundColor: isPrimary ? color : Colors.transparent,
        side: BorderSide(color: isPrimary ? color : Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
    ),
  );
}

// =============================================================================
// DIALOG 1: Gán rổ & Tạo phiếu dệt
// =============================================================================

Future<void> showAssignBasketAndCreateTicketDialog(
  BuildContext context,
  Machine machine,
  String lineCode,
  AppLocalizations l10n,
  MachineProductHistory activeLoom,
  List<dynamic> activeBatches,
) async {
  final authState = context.read<AuthCubit>().state;
  final int currentEmployeeId = (authState is AuthAuthenticated)
      ? (authState.user.employeeId ?? 0)
      : 0;

  List<Basket> readyBaskets = [];
  final basketState = context.read<BasketCubit>().state;
  if (basketState is BasketLoaded) {
    readyBaskets = basketState.baskets
        .where((b) => b.status == 'READY')
        .toList();
  }

  int autoStandardId = 0;
  final standardState = context.read<StandardCubit>().state;
  if (standardState is StandardLoaded) {
    final std = standardState.allStandards
        .where((s) => s.productId == activeLoom.productId)
        .firstOrNull;
    autoStandardId = std?.standardId ?? 0;
  }

  Basket? selectedBasket;
  bool isSubmitting = false;
  final formKey = GlobalKey<FormState>();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text(
            'Vào rổ & Tạo phiếu dệt',
            style: TextStyle(
              color: kMachineOpPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.precision_manufacturing,
                          size: 16,
                          color: kMachineOpPrimaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${machine.machineName}  •  Line $lineCode',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: activeLoom.product?.itemCode ?? 'N/A',
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Sản phẩm đang chạy',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.black12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (autoStandardId == 0) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'CẢNH BÁO: Sản phẩm này chưa có Tiêu chuẩn (Standard)!',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownSearch<Basket>(
                          selectedItem: selectedBasket,
                          items: (f, p) => readyBaskets,
                          itemAsString: (b) => '${b.code} (${b.tareWeight}kg)',
                          compareFn: (item, selectedItem) =>
                              item.id == selectedItem.id,
                          onChanged: (val) =>
                              setStateDialog(() => selectedBasket = val),
                          validator: (v) =>
                              v == null ? 'Bắt buộc chọn rổ' : null,
                          decoratorProps: const DropDownDecoratorProps(
                            decoration: InputDecoration(
                              labelText: 'Chọn rổ (READY) *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 55,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.qr_code_scanner,
                            color: kMachineOpPrimaryColor,
                          ),
                          tooltip: 'Quét mã rổ',
                          onPressed: () async {
                            String? scannedCode;
                            await showDialog(
                              context: context,
                              builder: (scanCtx) => AlertDialog(
                                title: const Text('Quét mã rổ'),
                                content: SizedBox(
                                  width: 300,
                                  height: 300,
                                  child: MobileScanner(
                                    onDetect: (capture) {
                                      final barcodes = capture.barcodes;
                                      if (barcodes.isNotEmpty &&
                                          barcodes.first.rawValue != null) {
                                        scannedCode = barcodes.first.rawValue;
                                        Navigator.pop(scanCtx);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            );
                            if (scannedCode != null) {
                              final code = scannedCode!;
                              final found = readyBaskets
                                  .where((b) => b.code == code)
                                  .firstOrNull;
                              if (found != null) {
                                setStateDialog(() => selectedBasket = found);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Đã chọn rổ: $code'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Không tìm thấy rổ hoặc rổ không ở trạng thái READY',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (isSubmitting) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: CircularProgressIndicator(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setStateDialog(() => isSubmitting = true);

                        if (currentEmployeeId == 0) {
                          setStateDialog(() => isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Tài khoản của bạn chưa được liên kết với nhân viên nào! Không thể tạo phiếu.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (autoStandardId == 0) {
                          setStateDialog(() => isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Sản phẩm này chưa có Tiêu chuẩn dệt! Vui lòng tạo Tiêu chuẩn dệt trước.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        try {
                          final List<WeavingTicketYarn> mappedYarns = [];

                          for (var b in activeBatches) {
                            int bId = 0;
                            String role = '';
                            double qty = 0.0;

                            if (b is Map) {
                              bId =
                                  int.tryParse(
                                    b['batchId']?.toString() ??
                                        b['batch_id']?.toString() ??
                                        '0',
                                  ) ??
                                  0;
                              role =
                                  (b['componentType'] ??
                                          b['component_type'] ??
                                          b['yarnRole'] ??
                                          b['yarn_role'] ??
                                          '')
                                      .toString();
                              qty =
                                  double.tryParse(
                                    (b['quantityKg'] ??
                                            b['quantity_kg'] ??
                                            b['quantity'] ??
                                            '0')
                                        .toString(),
                                  ) ??
                                  0.0;
                            } else {
                              final dynamic obj = b;

                              try {
                                bId = int.parse(obj.batchId.toString());
                              } catch (_) {}
                              if (bId == 0) {
                                try {
                                  bId = int.parse(obj.batch_id.toString());
                                } catch (_) {}
                              }
                              if (bId == 0) {
                                try {
                                  bId = int.parse(obj.id.toString());
                                } catch (_) {}
                              }

                              try {
                                role = obj.componentType?.toString() ?? '';
                              } catch (_) {}
                              if (role.isEmpty || role == 'null') {
                                try {
                                  role = obj.component_type?.toString() ?? '';
                                } catch (_) {}
                              }
                              if (role.isEmpty || role == 'null') {
                                try {
                                  role = obj.yarnRole?.toString() ?? '';
                                } catch (_) {}
                              }
                              if (role.isEmpty || role == 'null') {
                                try {
                                  role = obj.yarn_role?.toString() ?? '';
                                } catch (_) {}
                              }
                              if (role == 'null') role = '';

                              try {
                                qty = double.parse(obj.quantityKg.toString());
                              } catch (_) {}
                              if (qty == 0.0) {
                                try {
                                  qty = double.parse(
                                    obj.quantity_kg.toString(),
                                  );
                                } catch (_) {}
                              }
                              if (qty == 0.0) {
                                try {
                                  qty = double.parse(obj.quantity.toString());
                                } catch (_) {}
                              }
                            }

                            if (bId > 0) {
                              mappedYarns.add(
                                WeavingTicketYarn(
                                  batchId: bId,
                                  componentType: role,
                                  quantity: qty,
                                ),
                              );
                            }
                          }

                          if (mappedYarns.isEmpty && activeBatches.isNotEmpty) {
                            setStateDialog(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Lỗi ánh xạ dữ liệu: Không trích xuất được ID của Lô sợi. Vui lòng liên hệ IT!',
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 5),
                                ),
                              );
                            }
                            return;
                          }

                          final newTicket = WeavingTicket(
                            id: 0,
                            code: 'AUTO',
                            productId: activeLoom.productId,
                            standardId: autoStandardId,
                            machineId: machine.id,
                            machineLine: lineCode,
                            yarnLoadDate: DateTime.now()
                                .toIso8601String()
                                .split('T')[0],
                            yarns: mappedYarns,
                            basketId: selectedBasket!.id,
                            employeeInId: currentEmployeeId,
                            timeIn: DateTime.now().toIso8601String(),
                            numberOfKnots: 0,
                            grossWeight: 0.0,
                            netWeight: 0.0,
                            lengthMeters: 0.0,
                          );

                          await context.read<WeavingCubit>().saveTicket(
                            ticket: newTicket,
                            isEdit: false,
                          );
                          await Future.delayed(
                            const Duration(milliseconds: 1000),
                          );

                          if (!context.mounted) {
                            return;
                          }
                          await context
                              .read<MachineOperationCubit>()
                              .loadDashboard();

                          if (!context.mounted) {
                            return;
                          }
                          await context.read<BasketCubit>().loadBaskets();

                          if (!ctx.mounted) {
                            return;
                          }
                          Navigator.pop(ctx);
                        } catch (e) {
                          setStateDialog(() => isSubmitting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
              child: const Text('TẠO PHIẾU & CHẠY'),
            ),
          ],
        );
      },
    ),
  );
}

// =============================================================================
// DIALOG 4: Cân rổ cuối ca
// =============================================================================

Future<void> handleWeighingCheck(
  BuildContext context,
  Machine machine,
  String lineCode,
  WeavingTicket ticket,
) async {
  final shiftState = context.read<ShiftCubit>().state;
  if (shiftState is! ShiftLoaded) {
    showWeighingDialog(context, machine, lineCode, ticket);
    return;
  }
  final currentShiftName = calculateCurrentShiftName();
  final currentShift = shiftState.shifts.firstWhere(
    (s) =>
        s.name.contains(currentShiftName) ||
        s.name.contains(currentShiftName.replaceAll('Ca ', '')),
    orElse: () => shiftState.shifts.first,
  );

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final records = await context
        .read<WeavingRecordCubit>()
        .getRecordsByTicketId(ticket.id);
    if (!context.mounted) {
      return;
    }
    Navigator.pop(context);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final hasWeighedToday = records.any((r) {
      if (r.shiftId != currentShift.id || r.updatedAt == null) {
        return false;
      }
      final recordTime = r.updatedAt!.toLocal();
      return DateTime(
        recordTime.year,
        recordTime.month,
        recordTime.day,
      ).isAtSameMomentAs(today);
    });

    if (hasWeighedToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'CẢNH BÁO: Ca ${currentShift.name} hôm nay đã thực hiện cân rồi!',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      showWeighingDialog(context, machine, lineCode, ticket);
    }
  } catch (e) {
    if (!context.mounted) {
      return;
    }
    Navigator.pop(context);
    showWeighingDialog(context, machine, lineCode, ticket);
  }
}

void showWeighingDialog(
  BuildContext context,
  Machine machine,
  String lineCode,
  WeavingTicket ticket,
) {
  final formKey = GlobalKey<FormState>();
  final grossWeightCtrl = TextEditingController();
  final runWasteCtrl = TextEditingController(text: '0');
  final setupWasteCtrl = TextEditingController(text: '0');
  final runWasteReasonCtrl = TextEditingController();

  double basketTare = 0.0;
  final basketState = context.read<BasketCubit>().state;
  if (basketState is BasketLoaded && ticket.basketId != null) {
    try {
      final foundBasket = basketState.baskets.firstWhere(
        (b) => b.id == ticket.basketId,
      );
      basketTare = foundBasket.tareWeight;
    } catch (_) {}
  }

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setStateDialog) {
        double gross = double.tryParse(grossWeightCtrl.text) ?? 0;
        double net = gross > basketTare ? gross - basketTare : 0;

        return AlertDialog(
          title: const Text('Cân rổ cuối ca'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${machine.machineName} - Line $lineCode',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Rổ: ${ticket.basketCode} (Bì: ${basketTare}kg)'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: grossWeightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Gross (kg)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => setStateDialog(() {}),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Nhập số' : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Net: ${net.toStringAsFixed(2)} kg',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: runWasteCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Phế Run',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: setupWasteCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Phế Setup',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: runWasteReasonCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Lý do phế Run (Nếu có)',
                      hintText: 'Nhập nguyên nhân sinh ra phế...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  saveWeighingData(
                    context,
                    machine.id,
                    int.parse(lineCode),
                    ticket,
                    gross,
                    net,
                    double.tryParse(runWasteCtrl.text) ?? 0.0,
                    double.tryParse(setupWasteCtrl.text) ?? 0.0,
                    runWasteReasonCtrl.text,
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> saveWeighingData(
  BuildContext context,
  int machineId,
  int line,
  WeavingTicket ticket,
  double grossWeight,
  double netWeight,
  double runWaste,
  double setupWaste,
  String? runWasteReason,
) async {
  final authState = context.read<AuthCubit>().state;
  int? currentEmployeeId = (authState is AuthAuthenticated)
      ? authState.user.employeeId
      : null;

  final shiftState = context.read<ShiftCubit>().state;
  int? currentShiftId;
  if (shiftState is ShiftLoaded) {
    final currentShiftName = calculateCurrentShiftName();
    try {
      currentShiftId = shiftState.shifts
          .firstWhere(
            (s) =>
                s.name.contains(currentShiftName) ||
                s.name.contains(currentShiftName.replaceAll('Ca ', '')),
            orElse: () => shiftState.shifts.first,
          )
          .id;
    } catch (_) {
      if (shiftState.shifts.isNotEmpty) {
        currentShiftId = shiftState.shifts.first.id;
      }
    }
  }

  final recordData = WeavingRecord(
    id: 0,
    machineId: machineId,
    line: line,
    basketId: ticket.basketId ?? 0,
    weavingTicketId: ticket.id,
    shiftId: currentShiftId,
    updatedById: currentEmployeeId,
    totalWeight: netWeight,
    runWaste: runWaste,
    runWasteReason: runWasteReason,
    setupWaste: setupWaste,
    updatedAt: DateTime.now(),
  );
  context.read<WeavingRecordCubit>().saveRecord(
    item: recordData,
    isEdit: false,
  );

  await Future.delayed(const Duration(milliseconds: 500));
  if (context.mounted) {
    context.read<MachineOperationCubit>().loadDashboard();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu dữ liệu cân và cập nhật Phiếu dệt!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// =============================================================================
// DIALOG 5: Ra rổ (hoàn thành phiếu dệt)
// =============================================================================

void showReleaseDialog(
  BuildContext context,
  WeavingTicket ticket,
  AppLocalizations l10n,
) {
  final grossCtrl = TextEditingController();
  final lengthCtrl = TextEditingController();
  final knotCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final authState = context.read<AuthCubit>().state;
  int? employeeOutId = (authState is AuthAuthenticated)
      ? authState.user.employeeId
      : null;

  double targetWeightGm = 0.0;
  final bomState = context.read<BOMCubit>().state;
  if (bomState is BOMListLoaded) {
    try {
      final bom = bomState.boms.firstWhere(
        (b) => b.productId == ticket.productId && b.isActive,
      );
      targetWeightGm = bom.targetWeightGm;
    } catch (_) {}
  }
  final double basketTare = ticket.tareWeight ?? 0.0;
  bool isProcessing = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          title: Text(l10n.finishTicket),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${l10n.ticketCode}: ${ticket.code}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: grossCtrl,
                  decoration: InputDecoration(
                    labelText: '${l10n.grossWeight} (Kg)',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) => v!.isEmpty ? l10n.required : null,
                  onChanged: (val) {
                    if (targetWeightGm > 0 && val.isNotEmpty) {
                      final grossKg = double.tryParse(val);
                      if (grossKg != null) {
                        final netKg = grossKg - basketTare;
                        lengthCtrl.text = netKg > 0
                            ? ((netKg * 1000) / targetWeightGm).toStringAsFixed(
                                2,
                              )
                            : '0';
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: knotCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.splice,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => v!.isEmpty ? l10n.required : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lengthCtrl,
                  decoration: InputDecoration(
                    labelText: '${l10n.length} (m)',
                    border: const OutlineInputBorder(),
                    fillColor: Colors.grey.shade200,
                    filled: true,
                  ),
                  keyboardType: TextInputType.number,
                  readOnly: targetWeightGm > 0,
                  validator: (v) => v!.isEmpty ? l10n.required : null,
                ),
                if (isProcessing) ...[
                  const SizedBox(height: 20),
                  const LinearProgressIndicator(),
                  const Text(
                    'Đang giải phóng rổ...',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isProcessing ? null : () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: isProcessing
                  ? null
                  : () async {
                      if (formKey.currentState!.validate() &&
                          employeeOutId != null) {
                        setStateDialog(() => isProcessing = true);
                        try {
                          await context
                              .read<MachineOperationCubit>()
                              .finishTicket(
                                ticket: ticket,
                                employeeOutId: employeeOutId,
                                grossWeight: double.parse(grossCtrl.text),
                                length: double.parse(lengthCtrl.text),
                                numberOfKnots: int.parse(knotCtrl.text),
                              );
                          await Future.delayed(
                            const Duration(milliseconds: 1000),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          await context
                              .read<MachineOperationCubit>()
                              .loadDashboard();
                          if (!context.mounted) {
                            return;
                          }
                          await context.read<BasketCubit>().loadBaskets();
                          if (!ctx.mounted) {
                            return;
                          }
                          Navigator.pop(ctx);
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Đã ra rổ thành công! Line máy hiện đã trống.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          setStateDialog(() => isProcessing = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lỗi: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
              child: Text(l10n.releaseBasket),
            ),
          ],
        );
      },
    ),
  );
}
