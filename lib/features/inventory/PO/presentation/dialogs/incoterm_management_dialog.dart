import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/inventory/PO/incoterm/domain/incoterm_model.dart';
import 'package:owvds/features/inventory/PO/incoterm/presentation/bloc/incoterm_cubit.dart';

class IncotermManagementDialog extends StatefulWidget {
  const IncotermManagementDialog({super.key});

  @override
  State<IncotermManagementDialog> createState() =>
      _IncotermManagementDialogState();
}

class _IncotermManagementDialogState extends State<IncotermManagementDialog> {
  final _codeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  Incoterm? _editingItem;

  void _saveItem() {
    if (_codeCtrl.text.isEmpty) return;
    final item = Incoterm(
      incotermId: _editingItem?.incotermId ?? 0,
      incotermCode: _codeCtrl.text.trim().toUpperCase(),
      description: _descCtrl.text.trim(),
    );

    if (_editingItem != null) {
      context.read<IncotermCubit>().updateIncoterm(item);
    } else {
      context.read<IncotermCubit>().addIncoterm(item);
    }

    _codeCtrl.clear();
    _descCtrl.clear();
    setState(() => _editingItem = null);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 600,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: Colors.grey.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Danh mục Incoterms",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Form Add/Edit
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _codeCtrl,
                      decoration: const InputDecoration(
                        labelText: "Mã (FOB, CIF)",
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: "Mô tả",
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                    onPressed: _saveItem,
                    child: Text(_editingItem != null ? "Cập nhật" : "Thêm"),
                  ),
                  if (_editingItem != null)
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _editingItem = null;
                          _codeCtrl.clear();
                          _descCtrl.clear();
                        });
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),

            // List
            Expanded(
              child: BlocBuilder<IncotermCubit, IncotermState>(
                builder: (context, state) {
                  if (state is IncotermLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is IncotermLoaded) {
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.incoterms.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = state.incoterms[index];
                        return ListTile(
                          title: Text(
                            item.incotermCode,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(item.description ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _editingItem = item;
                                    _codeCtrl.text = item.incotermCode;
                                    _descCtrl.text = item.description ?? '';
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                onPressed: () => context
                                    .read<IncotermCubit>()
                                    .deleteIncoterm(item.incotermId),
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
          ],
        ),
      ),
    );
  }
}
