import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:owvds/features/production/loom_state/product/presentation/bloc/product_cubit.dart';
import 'package:owvds/features/production/weaving/domain/weaving_model.dart';
import 'package:owvds/features/production/weaving/presentation/bloc/weaving_cubit.dart';
import 'package:owvds/features/production/weaving_opperation/presentation/bloc/machine_operation_cubit.dart';
import 'package:owvds/features/production/weaving_record/presentation/bloc/weaving_record_cubit.dart';
import 'package:owvds/features/qc/loom_state_standard/domain/loom_state_standard_model.dart';
import 'package:owvds/features/qc/loom_state_standard/presentation/bloc/loom_state_standard_cubit.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class WeavingTicketPrintButton extends StatelessWidget {
  final WeavingTicket ticket;

  const WeavingTicketPrintButton({super.key, required this.ticket});

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '-';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  Future<void> _handlePrint(BuildContext context) async {
    // Lấy toàn bộ dữ liệu từ context TRƯỚC khi có bất kỳ await nào
    // để tránh use_build_context_synchronously
    final recordCubit = context.read<WeavingRecordCubit>();
    final weavingState = context.read<WeavingCubit>().state;
    final productState = context.read<ProductCubit>().state;
    final machineOpState = context.read<MachineOperationCubit>().state;
    final standardState = context.read<StandardCubit>().state;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang tạo mẫu in PDF...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // 1. LẤY DỮ LIỆU CHI TIẾT
      final records = await recordCubit.getRecordsByTicketId(ticket.id);

      List<WeavingInspection> inspections = (weavingState is WeavingLoaded)
          ? weavingState.inspections
          : [];

      String productItemCode = 'ID: ${ticket.productId}';
      if (productState is ProductLoaded) {
        final product = productState.allProducts
            .where((p) => p.id == ticket.productId)
            .firstOrNull;
        if (product != null) productItemCode = product.itemCode;
      }

      // Lấy tên máy từ MachineOperationCubit
      String machineName = 'ID: ${ticket.machineId}';
      if (machineOpState is MachineOpLoaded) {
        final machine = machineOpState.machines
            .where((m) => m.id == ticket.machineId)
            .firstOrNull;
        if (machine != null) machineName = machine.machineName;
      }

      // Lấy Object Standard để đổ vào bảng
      Standard? standardObj;
      if (standardState is StandardLoaded) {
        standardObj = standardState.allStandards
            .where((s) => s.standardId == ticket.standardId)
            .firstOrNull;
      }

      // 2. TẢI FONT
      final fontRegular = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();
      final pdf = pw.Document();

      // 3. THIẾT KẾ PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
          header: (pw.Context context) => pw.Column(
            children: [
              pw.Text(
                'CÔNG TY TNHH OPPERMANN VIỆT NAM',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'PHIẾU THÔNG TIN RỔ DỆT',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Mã phiếu: ${ticket.code}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),
            ],
          ),
          build: (pw.Context context) {
            return [
              // --- PHẦN 1: THÔNG TIN CHUNG ---
              pw.Text(
                '1. THÔNG TIN SẢN XUẤT CHUNG',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              _buildInfoRow(
                'Mã sản phẩm:',
                productItemCode,
                'Máy dệt:',
                '$machineName (Line ${ticket.machineLine})',
              ),
              _buildInfoRow(
                'Mã rổ chứa:',
                ticket.basketCode ?? 'N/A',
                'Trọng lượng bì:',
                '${ticket.tareWeight} kg',
              ),
              _buildInfoRow(
                'Ngày lên sợi:',
                _formatDate(ticket.yarnLoadDate),
                'Trạng thái:',
                ticket.timeOut != null ? 'Đã ra rổ' : 'Đang dệt',
              ),

              pw.SizedBox(height: 12),

              // --- PHẦN 2: TIÊU CHUẨN KỸ THUẬT (DẠNG BẢNG) ---
              pw.Text(
                '2. TIÊU CHUẨN KỸ THUẬT CỦA MÃ HÀNG',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              if (standardObj == null)
                pw.Text(
                  'Không tìm thấy thông tin tiêu chuẩn kỹ thuật.',
                  style: const pw.TextStyle(color: PdfColors.red),
                )
              else
                pw.TableHelper.fromTextArray(
                  context: context,
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  headerStyle: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  data: <List<String>>[
                    [
                      'Chiều rộng (mm)',
                      'Độ dày (mm)',
                      'Mật độ (pick/10cm)',
                      'Trọng lượng (g/m)',
                    ],
                    [
                      standardObj.widthMm.toString(),
                      standardObj.thicknessMm.toString(),
                      standardObj.weftDensity.toString(),
                      standardObj.weightGm.toString(),
                    ],
                  ],
                ),

              pw.SizedBox(height: 18),

              // --- PHẦN 3: THỜI GIAN & NHÂN SỰ ---
              pw.Text(
                '3. THỜI GIAN & NHÂN SỰ',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              _buildInfoRow(
                'Giờ vào rổ:',
                _formatDate(ticket.timeIn),
                'Người đứng máy:',
                ticket.employeeInName ?? '-',
              ),
              _buildInfoRow(
                'Giờ ra rổ:',
                _formatDate(ticket.timeOut),
                'Người ra rổ:',
                ticket.employeeOutName ?? '-',
              ),

              pw.SizedBox(height: 18),

              // --- PHẦN 4: KẾT QUẢ CUỐI CÙNG ---
              pw.Text(
                '4. KẾT QUẢ SẢN XUẤT',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              _buildInfoRow(
                'Tổng trọng lượng (Gross):',
                '${ticket.grossWeight} kg',
                'Trọng lượng tịnh (Net):',
                '${ticket.netWeight} kg',
              ),
              _buildInfoRow(
                'Chiều dài (m):',
                '${ticket.lengthMeters} m',
                'Số mối nối/lỗi:',
                '${ticket.numberOfKnots}',
              ),

              pw.SizedBox(height: 18),

              // --- PHẦN 5: CHI TIẾT LÔ SỢI ---
              pw.Text(
                '5. DANH SÁCH LÔ SỢI SỬ DỤNG',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                context: context,
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                data: <List<String>>[
                  [
                    'Thành phần',
                    'Mã lô nội bộ',
                    'Nhà cung cấp',
                    'Số lượng (kg)',
                  ],
                  ...ticket.yarns.map(
                    (y) => [
                      y.componentType,
                      y.internalBatchCode ?? 'Lô #${y.batchId}',
                      y.supplierShortName ?? '-',
                      y.quantity.toString(),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 18),

              // --- PHẦN 6: LỊCH SỬ CÂN RỔ ---
              pw.Text(
                '6. LỊCH SỬ CÂN RỔ CUỐI CA',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                context: context,
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerStyle: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                data: <List<String>>[
                  [
                    'Thời gian',
                    'Ca',
                    'Net(kg)',
                    'Phế Run',
                    'Lý do phế',
                    'Phế Setup',
                    'Người thực hiện',
                  ],
                  ...records.map(
                    (r) => [
                      _formatDate(r.updatedAt?.toIso8601String()),
                      r.shiftName ?? '-',
                      r.totalWeight.toString(),
                      r.runWaste.toString(),
                      r.runWasteReason ?? '-',
                      r.setupWaste.toString(),
                      r.updatedByName ?? '-',
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 18),

              // --- PHẦN 7: LỊCH SỬ QC ---
              pw.Text(
                '7. LỊCH SỬ KIỂM TRA CHẤT LƯỢNG (QC)',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                context: context,
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerStyle: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                data: <List<String>>[
                  [
                    'Công đoạn',
                    'Thời gian',
                    'Rộng(mm)',
                    'Lực căng (dNA)',
                    'pick/10cm',
                    'Dày(mm)',
                    'TL(g/m)',
                    'QC',
                  ],
                  ...inspections.map(
                    (i) => [
                      i.stageName,
                      _formatDate(i.inspectionTime),
                      i.widthMm.toString(),
                      i.tensionDan.toString(),
                      i.weftDensity.toString(),
                      i.thicknessMm.toString(),
                      i.weightGm.toString(),
                      i.employeeName ?? '-',
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Phieu_Det_${ticket.code}',
      );
    } catch (e) {
      debugPrint("Lỗi tạo PDF: $e");
    }
  }

  pw.Widget _buildInfoRow(
    String label1,
    String value1,
    String label2,
    String value2,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 85,
                  child: pw.Text(
                    label1,
                    style: const pw.TextStyle(
                      color: PdfColors.grey700,
                      fontSize: 10,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    value1,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 85,
                  child: pw.Text(
                    label2,
                    style: const pw.TextStyle(
                      color: PdfColors.grey700,
                      fontSize: 10,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    value2,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.print),
      tooltip: 'In phiếu dệt',
      onPressed: () => _handlePrint(context),
    );
  }
}
