import 'package:owvds/features/production/weaving/domain/weaving_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class WeavingPrintService {
  // Hàm chính để gọi in
  static Future<void> printTicket(WeavingTicket ticket) async {
    // 1. Load Font hỗ trợ Tiếng Việt (Roboto)
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    // 2. Tạo document
    final doc = pw.Document();

    // 3. Định dạng ngày tháng
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final nowStr = dateFormat.format(DateTime.now());

    // 4. Vẽ giao diện PDF
    doc.addPage(
      pw.Page(
        pageFormat:
            PdfPageFormat.a5, // Hoặc PdfPageFormat.roll80 cho máy in nhiệt
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "FACTORY NAME",
                        style: pw.TextStyle(font: fontBold, fontSize: 18),
                      ),
                      pw.Text(
                        "Weaving Department",
                        style: pw.TextStyle(font: font, fontSize: 10),
                      ),
                    ],
                  ),
                  // QR Code chứa Mã Phiếu
                  pw.BarcodeWidget(
                    data: ticket.code,
                    barcode: pw.Barcode.qrCode(),
                    width: 50,
                    height: 50,
                  ),
                ],
              ),
              pw.Divider(),

              // --- TITLE ---
              pw.Center(
                child: pw.Text(
                  "PHIẾU RỔ DỆT (WEAVING TICKET)",
                  style: pw.TextStyle(font: fontBold, fontSize: 16),
                ),
              ),
              pw.SizedBox(height: 10),

              // --- GENERAL INFO TABLE ---
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  _buildTableRow(
                    "Mã Phiếu / Code",
                    ticket.code,
                    font,
                    fontBold,
                  ),
                  _buildTableRow(
                    "Máy / Machine",
                    "Line ${ticket.machineLine}",
                    font,
                    fontBold,
                  ),
                  _buildTableRow(
                    "Sản phẩm / Product",
                    ticket.productItemCode ?? "${ticket.productId}",
                    font,
                    fontBold,
                  ),
                  _buildTableRow(
                    "Tiêu chuẩn / Std",
                    "STD-${ticket.standardId}",
                    font,
                    fontBold,
                  ),
                  _buildTableRow(
                    "Rổ / Basket",
                    "${ticket.basketCode} (${ticket.tareWeight}kg)",
                    font,
                    fontBold,
                  ),
                  _buildTableRow(
                    "Ngày lên trục",
                    ticket.yarnLoadDate,
                    font,
                    fontBold,
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // --- YARNS SECTION ---
              pw.Text(
                "CHI TIẾT SỢI (YARNS):",
                style: pw.TextStyle(font: fontBold, fontSize: 12),
              ),
              pw.SizedBox(height: 5),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2), // Loại
                  1: const pw.FlexColumnWidth(3), // Mã Lô
                  2: const pw.FlexColumnWidth(1), // SL
                },
                children: [
                  // Header Table
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _buildCell(
                        "Loại sợi",
                        fontBold,
                        align: pw.TextAlign.center,
                      ),
                      _buildCell(
                        "Mã Lô (Batch)",
                        fontBold,
                        align: pw.TextAlign.center,
                      ),
                      _buildCell("Kg", fontBold, align: pw.TextAlign.center),
                    ],
                  ),
                  // Data Rows
                  ...ticket.yarns.map((yarn) {
                    final batchInfo =
                        yarn.internalBatchCode ?? "ID:${yarn.batchId}";
                    final supInfo = yarn.supplierShortName != null
                        ? "\n(${yarn.supplierShortName})"
                        : "";
                    return pw.TableRow(
                      children: [
                        _buildCell(yarn.componentType, font),
                        _buildCell("$batchInfo$supInfo", font),
                        _buildCell(
                          "${yarn.quantity}",
                          font,
                          align: pw.TextAlign.right,
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 10),

              // --- PERSONNEL INFO ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: _buildInfoBox(
                      "Người Vào (Operator In)",
                      ticket.employeeInName ?? "-",
                      font,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: _buildInfoBox(
                      "Người Ra (Operator Out)",
                      ticket.employeeOutName ?? "-",
                      font,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              // --- RESULT ---
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text(
                      "Gross: ${ticket.grossWeight} kg",
                      style: pw.TextStyle(font: font),
                    ),
                    pw.Text(
                      "Net: ${ticket.netWeight} kg",
                      style: pw.TextStyle(font: fontBold),
                    ),
                    pw.Text(
                      "Length: ${ticket.lengthMeters} m",
                      style: pw.TextStyle(font: font),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // --- FOOTER ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "In lúc: $nowStr",
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 9,
                      color: PdfColors.grey,
                    ),
                  ),
                  pw.Text(
                    "Signature: ________________",
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // 5. Mở giao diện in của điện thoại
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Ticket-${ticket.code}', // Tên file khi lưu
    );
  }

  // Helper: Tạo dòng trong bảng thông tin chung
  static pw.TableRow _buildTableRow(
    String label,
    String value,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            value,
            style: pw.TextStyle(font: fontBold, fontSize: 11),
          ),
        ),
      ],
    );
  }

  // Helper: Tạo ô trong bảng chi tiết sợi
  static pw.Widget _buildCell(
    String text,
    pw.Font font, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 10),
        textAlign: align,
      ),
    );
  }

  // Helper: Box thông tin nhân viên
  static pw.Widget _buildInfoBox(String title, String value, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(font: font, fontSize: 11)),
        ],
      ),
    );
  }
}
