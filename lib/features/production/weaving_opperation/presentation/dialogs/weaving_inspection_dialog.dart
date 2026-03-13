import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:owvds/core/widgets/responsive_layout.dart';
import 'package:owvds/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:owvds/features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'package:owvds/features/hr/work_schedule/shift/domain/shift_model.dart';
import 'package:owvds/features/hr/work_schedule/shift/presentation/bloc/shift_cubit.dart';
import 'package:owvds/features/inventory/material_batch/domain/material_batch_model.dart';
import 'package:owvds/features/inventory/material_batch/presentation/bloc/material_batch_cubit.dart';
import 'package:owvds/features/production/loom_state/product/presentation/bloc/product_cubit.dart';
import 'package:owvds/features/production/weaving/domain/weaving_model.dart';
import 'package:owvds/features/production/weaving/presentation/bloc/weaving_cubit.dart';
import 'package:owvds/features/qc/loom_state_standard/presentation/bloc/loom_state_standard_cubit.dart';
import 'package:owvds/l10n/app_localizations.dart';
// ── Notification ──
import 'package:owvds/features/production/notifications/data/notification_service.dart';

class WeavingInspectionScreen extends StatefulWidget {
  final WeavingTicket ticket;
  final VoidCallback? onRelease;
  final String? shiftName;

  const WeavingInspectionScreen({
    super.key,
    required this.ticket,
    this.onRelease,
    this.shiftName,
  });

  @override
  State<WeavingInspectionScreen> createState() =>
      _WeavingInspectionScreenState();
}

class _WeavingInspectionScreenState extends State<WeavingInspectionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _widthCtrl = TextEditingController();
  final _densityCtrl = TextEditingController();
  final _tensionCtrl = TextEditingController();
  final _thickCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _bowingCtrl = TextEditingController();

  int? _selectedEmpId;
  int? _selectedShiftId;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load data
    context.read<WeavingCubit>().selectTicket(widget.ticket);
    context.read<EmployeeCubit>().loadEmployees();
    context.read<ShiftCubit>().loadShifts();
    context.read<ProductCubit>().loadProducts();
    context.read<StandardCubit>().loadStandards();
    context.read<MaterialBatchCubit>().loadBatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _widthCtrl.dispose();
    _densityCtrl.dispose();
    _tensionCtrl.dispose();
    _thickCtrl.dispose();
    _weightCtrl.dispose();
    _bowingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Kiểm tra chất lượng (QC)",
              style: TextStyle(fontSize: 16),
            ),
            Text(
              "Phiếu: ${widget.ticket.code} - Máy: ${widget.ticket.machineId} (Line ${widget.ticket.machineLine})",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          if (widget.onRelease != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.stop_circle_outlined, size: 18),
                label: Text(
                  l10n.releaseBasket,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: widget.onRelease,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // --- 1. TICKET INFO: Desktop = always open, Mobile = collapsible ---
          if (isDesktop)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.assignment,
                        size: 20,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Standard & Product",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: width * 0.5),
                        child: _TicketBatchList(yarns: widget.ticket.yarns),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _StandardFullDetails(standardId: widget.ticket.standardId),
                ],
              ),
            )
          else
            // Mobile: ExpansionTile thu gọn được — tránh chiếm không gian khi nhập
            Material(
              color: Colors.white,
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  initiallyExpanded: false,
                  leading: const Icon(
                    Icons.assignment,
                    size: 18,
                    color: Colors.blueGrey,
                  ),
                  title: Text(
                    widget.ticket.code,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: width * 0.45),
                    child: _TicketBatchList(yarns: widget.ticket.yarns),
                  ),
                  children: [
                    _StandardFullDetails(standardId: widget.ticket.standardId),
                  ],
                ),
              ),
            ),

          const Divider(height: 1),

          // --- 2. BODY (History & Form) ---
          Expanded(
            child: isDesktop ? _buildDesktopBody(l10n) : _buildMobileBody(l10n),
          ),
        ],
      ),
    );
  }

  // --- DESKTOP BODY ---
  Widget _buildDesktopBody(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: History
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.inspectionHistory,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildHistoryList(l10n)),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        // Right: Input Form
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(child: _buildInputForm(l10n)),
          ),
        ),
      ],
    );
  }

  // --- MOBILE BODY ---
  Widget _buildMobileBody(AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.blue.shade900,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue.shade900,
            tabs: [
              Tab(
                icon: const Icon(Icons.history, size: 20),
                text: l10n.inspectionHistory,
              ),
              Tab(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                text: l10n.newInspection,
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: _buildHistoryList(l10n),
              ),
              Builder(
                builder: (context) {
                  // Padding bottom = keyboard height để nút Save không bị che
                  final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 24),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: _buildInputForm(l10n),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- HISTORY LIST ---
  Widget _buildHistoryList(AppLocalizations l10n) {
    return BlocBuilder<WeavingCubit, WeavingState>(
      builder: (context, state) {
        if (state is WeavingLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<WeavingInspection> list = [];
        if (state is WeavingLoaded) list = state.inspections;

        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.noInspectionsRecorded,
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (ctx, index) {
            final item = list[index];
            return Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Text(
                    "${list.length - index}",
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  item.stageName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Time: ${DateFormat('HH:mm dd/MM').format(DateTime.parse(item.inspectionTime))}",
                    ),
                    Text(
                      "Emp: ${item.employeeName ?? 'ID:${item.employeeId}'}",
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.grey),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(item.stageName),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${l10n.width}: ${item.widthMm} mm"),
                            Text("${l10n.density}: ${item.weftDensity}"),
                            Text("${l10n.tension}: ${item.tensionDan} daN"),
                            Text("${l10n.thickness}: ${item.thicknessMm} mm"),
                            Text("${l10n.weight}: ${item.weightGm} g/m"),
                            Text("${l10n.bow}: ${item.bowing} %"),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("Close"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- INPUT FORM ---
  Widget _buildInputForm(AppLocalizations l10n) {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated && authState.user.employeeId != null) {
      _selectedEmpId = authState.user.employeeId;
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlocBuilder<WeavingCubit, WeavingState>(
            builder: (context, state) {
              int nextCount = 1;
              if (state is WeavingLoaded) {
                nextCount = state.inspections.length + 1;
              }
              return Text(
                "Lần $nextCount",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          if (widget.shiftName != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 20,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Ca làm việc: ${widget.shiftName} (Tự động)",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<int>(
              value: _selectedShiftId,
              decoration: _inputDeco(l10n.shiftTitle),
              isExpanded: true,
              items: (context.watch<ShiftCubit>().state is ShiftLoaded)
                  ? (context.watch<ShiftCubit>().state as ShiftLoaded).shifts
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        )
                        .toList()
                  : [],
              onChanged: (v) => setState(() => _selectedShiftId = v),
              validator: (v) => v == null ? l10n.required : null,
            ),
          const SizedBox(height: 16),
          Text(
            l10n.measurements,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _widthCtrl,
                  decoration: _inputDeco(l10n.width),
                  keyboardType: TextInputType.number,
                  scrollPadding: const EdgeInsets.only(bottom: 200),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _densityCtrl,
                  decoration: _inputDeco("pick/10cm"),
                  keyboardType: TextInputType.number,
                  scrollPadding: const EdgeInsets.only(bottom: 200),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _tensionCtrl,
                  decoration: _inputDeco(l10n.tension),
                  keyboardType: TextInputType.number,
                  scrollPadding: const EdgeInsets.only(bottom: 200),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _thickCtrl,
                  decoration: _inputDeco(l10n.thickness),
                  keyboardType: TextInputType.number,
                  scrollPadding: const EdgeInsets.only(bottom: 200),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _weightCtrl,
                  decoration: _inputDeco(l10n.weight),
                  keyboardType: TextInputType.number,
                  scrollPadding: const EdgeInsets.only(bottom: 200),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _bowingCtrl,
                  decoration: _inputDeco(l10n.bow),
                  keyboardType: TextInputType.number,
                  scrollPadding: const EdgeInsets.only(bottom: 200),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              label: Text(l10n.save),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _saveInspection(l10n),
            ),
          ),
        ],
      ),
    );
  }

  void _saveInspection(AppLocalizations l10n) {
    int? finalShiftId = _selectedShiftId;

    if (widget.shiftName != null) {
      final shiftState = context.read<ShiftCubit>().state;
      if (shiftState is ShiftLoaded) {
        final foundShift = shiftState.shifts.firstWhere(
          (s) => s.name.toUpperCase() == widget.shiftName!.toUpperCase(),
          orElse: () => Shift(id: 0, name: "", note: ""),
        );
        if (foundShift.id != 0) {
          finalShiftId = foundShift.id;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Lỗi: Không tìm thấy ID của ca làm việc tự động trong hệ thống.",
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    if (_formKey.currentState!.validate() &&
        _selectedEmpId != null &&
        finalShiftId != null) {
      final state = context.read<WeavingCubit>().state;
      int count = (state is WeavingLoaded) ? state.inspections.length : 0;
      String stageName = "Lần ${count + 1}";

      final newItem = WeavingInspection(
        id: 0,
        ticketId: widget.ticket.id,
        stageName: stageName,
        employeeId: _selectedEmpId!,
        shiftId: finalShiftId,
        widthMm: double.tryParse(_widthCtrl.text) ?? 0,
        weftDensity: double.tryParse(_densityCtrl.text) ?? 0,
        tensionDan: double.tryParse(_tensionCtrl.text) ?? 0,
        thicknessMm: double.tryParse(_thickCtrl.text) ?? 0,
        weightGm: double.tryParse(_weightCtrl.text) ?? 0,
        bowing: double.tryParse(_bowingCtrl.text) ?? 0,
        inspectionTime: DateTime.now().toIso8601String(),
      );

      context.read<WeavingCubit>().saveInspection(newItem);

      _widthCtrl.clear();
      _densityCtrl.clear();
      _tensionCtrl.clear();
      _thickCtrl.clear();
      _weightCtrl.clear();
      _bowingCtrl.clear();

      if (!ResponsiveLayout.isDesktop(context)) _tabController.animateTo(0);

      // ── Thông báo Dashboard: kiểm tra chất lượng ──
      NotificationService.instance.notifyInspection(
        machineName: 'Máy #${widget.ticket.machineId}',
        lineCode: widget.ticket.machineLine,
        ticketCode: widget.ticket.code,
        stageName: stageName,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.saveSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } else if (finalShiftId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng chọn Ca làm việc."),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (_selectedEmpId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tài khoản chưa được gắn vào Hồ sơ nhân viên."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.white,
    );
  }
}

// --- WIDGET HIỂN THỊ FULL TIÊU CHUẨN ---
class _StandardFullDetails extends StatelessWidget {
  final int standardId;
  const _StandardFullDetails({required this.standardId});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final imageSize = isDesktop ? 80.0 : 60.0;

    return BlocBuilder<StandardCubit, StandardState>(
      builder: (context, state) {
        if (state is StandardLoaded) {
          final item = state.allStandards
              .where((s) => s.standardId == standardId)
              .firstOrNull;
          if (item == null) {
            return const Text(
              "Standard info not loaded",
              style: TextStyle(color: Colors.grey),
            );
          }

          final imageUrl = item.product?.imageUrl;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: imageSize,
                height: imageSize,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (imageUrl != null && imageUrl.isNotEmpty)
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        )
                      : const Icon(Icons.image, color: Colors.grey),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product?.itemCode ?? "Unknown Code",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _specItem("W", "${item.widthMm}mm"),
                        _specItem("T", "${item.thicknessMm}mm"),
                        _specItem("G/m", "${item.weightGm}g/m"),
                        _specItem(
                          "Str",
                          "${item.breakingStrengthDan}daN",
                          color: Colors.red.shade700,
                        ),
                        _specItem(
                          "El",
                          "${item.elongationAtLoadPercent}%",
                          color: Colors.indigo,
                        ),
                        if (item.weftDensity.isNotEmpty)
                          _specItem("Density", item.weftDensity),
                        if (item.curved != null && item.curved!.isNotEmpty)
                          _specItem("Curved", item.curved!),
                      ],
                    ),
                    if (item.note != null && item.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.note!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }
        return const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      },
    );
  }

  Widget _specItem(String label, String value, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _TicketBatchList extends StatelessWidget {
  final List<WeavingTicketYarn> yarns;
  const _TicketBatchList({required this.yarns});

  @override
  Widget build(BuildContext context) {
    if (yarns.isEmpty) {
      return const Text("-", style: TextStyle(color: Colors.grey));
    }

    return BlocBuilder<MaterialBatchCubit, MaterialBatchState>(
      builder: (context, state) {
        final List<MaterialBatch> allBatches = (state is MaterialBatchLoaded)
            ? state.batches
            : [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: yarns.map((yarnItem) {
            final batch = allBatches
                .where((b) => b.id == yarnItem.batchId)
                .firstOrNull;
            final internalCode = batch?.batchCode ?? "ID:${yarnItem.batchId}";
            final supplierCode = batch?.supplierBatchNo ?? "";

            final displayCode = supplierCode.isNotEmpty
                ? "$internalCode (Sup:$supplierCode)"
                : internalCode;

            return Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: RichText(
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 11,
                    fontFamily: 'Roboto',
                  ),
                  children: [
                    TextSpan(
                      text: "${yarnItem.componentType}: ",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    TextSpan(
                      text: displayCode,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
