import 'package:flutter/material.dart';
import 'package:owvds/features/qc/loom_state_standard/domain/loom_state_standard_model.dart';

class StandardDataSource extends DataTableSource {
  final List<Standard> standards;
  final Function(Standard) onEdit;
  final Function(Standard) onDelete;

  StandardDataSource({
    required this.standards,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= standards.length) return null;
    final std = standards[index];

    return DataRow(
      cells: [
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.indigo.shade100),
            ),
            child: Text(
              std.product?.itemCode ?? "ID: ${std.productId}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade800,
              ),
            ),
          ),
        ),
        DataCell(Text(std.widthMm)),
        DataCell(Text(std.thicknessMm)),
        DataCell(Text(std.breakingStrengthDan)),
        DataCell(Text(std.elongationAtLoadPercent)),
        DataCell(Text(std.weftDensity)),
        DataCell(Text(std.weightGm)),
        DataCell(Text(std.curved ?? '-')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                tooltip: "Sửa",
                onPressed: () => onEdit(std),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                tooltip: "Xóa",
                onPressed: () => onDelete(std),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => standards.length;

  @override
  int get selectedRowCount => 0;
}
