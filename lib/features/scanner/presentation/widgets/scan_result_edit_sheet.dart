import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/models/scanned_transaction_result.dart';
import '../screens/scan_review_screen.dart';

/// Bottom sheet untuk mengedit atau mengoreksi satu [ScanResultItem] sebelum
/// disimpan sebagai transaksi.
class ScanResultEditSheet extends ConsumerStatefulWidget {
  final ScanResultItem item;
  final ValueChanged<ScanResultItem> onSave;

  const ScanResultEditSheet({
    super.key,
    required this.item,
    required this.onSave,
  });

  @override
  ConsumerState<ScanResultEditSheet> createState() => _ScanResultEditSheetState();
}

class _ScanResultEditSheetState extends ConsumerState<ScanResultEditSheet> {
  late final TextEditingController _sourceCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;

  late ScannedDocumentType _docType;
  DateTime _selectedDate = DateTime.now();
  String? _sourceError;

  @override
  void initState() {
    super.initState();
    _sourceCtrl = TextEditingController(text: widget.item.result.source ?? '');
    _docType = widget.item.result.type;
    _noteCtrl = TextEditingController(text: widget.item.result.description);

    // Nominal: format tanpa simbol mata uang.
    final amt = widget.item.result.amount;
    if (amt != null) {
      final intVal = amt.toInt();
      _amountCtrl = TextEditingController(
        text: amt == intVal.toDouble()
            ? intVal.toString()
            : amt.toStringAsFixed(2),
      );
    } else {
      _amountCtrl = TextEditingController();
    }

    // Tanggal: pakai tanggal hasil scan atau hari ini bila null.
    _selectedDate = widget.item.result.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _sourceCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Date picker ────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Simpan ──────────────────────────────────────────────────────────────────

  void _onSave() {
    final source = _sourceCtrl.text.trim();
    if (source.isEmpty) {
      setState(() => _sourceError = 'source_or_merchant'.tr());
      return;
    }

    final rawAmount = _amountCtrl.text.trim();
    final amount = rawAmount.isEmpty
        ? null
        : double.tryParse(rawAmount.replaceAll(RegExp(r'[^0-9.]'), ''));

    final updatedResult = ScannedTransactionResult(
      source: source,
      type: _docType,
      amount: amount,
      date: _selectedDate,
      description: _noteCtrl.text.trim(),
      rawText: widget.item.result.rawText,
      success: true,
      errorMessage: null,
      imagePath: widget.item.result.imagePath,
    );

    widget.onSave(
      widget.item.copyWith(
        result: updatedResult,
        isSelected: true,
        isEdited: true,
      ),
    );
    Navigator.pop(context);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: 24,
          end: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ──────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'edit_scan_result'.tr(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Field 1 — Sumber / Merchant
              _FieldLabel('source_or_merchant'.tr()),
              const SizedBox(height: 8),
              TextField(
                controller: _sourceCtrl,
                decoration: InputDecoration(
                  hintText: 'merchant_hint'.tr(),
                  border: const OutlineInputBorder(),
                  errorText: _sourceError,
                  prefixIcon: const Icon(Icons.store_rounded, size: 20),
                ),
                onChanged: (_) {
                  if (_sourceError != null) {
                    setState(() => _sourceError = null);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Field 2 — Jenis Dokumen
              _FieldLabel('doc_type'.tr()),
              const SizedBox(height: 8),
              DropdownButtonFormField<ScannedDocumentType>(
                value: _docType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_rounded, size: 20),
                ),
                items: [
                  DropdownMenuItem(
                    value: ScannedDocumentType.receipt,
                    child: Text('receipt'.tr()),
                  ),
                  DropdownMenuItem(
                    value: ScannedDocumentType.salarySlip,
                    child: Text('salary_slip'.tr()),
                  ),
                  DropdownMenuItem(
                    value: ScannedDocumentType.unknown,
                    child: Text('unknown'.tr()),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _docType = v);
                },
              ),
              const SizedBox(height: 16),

              // Field 3 — Nominal
              _FieldLabel('transaction_amount'.tr()),
              const SizedBox(height: 8),
              TextField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                  prefixIcon: Icon(Icons.payments_rounded, size: 20),
                  hintText: '0',
                ),
              ),
              const SizedBox(height: 16),

              // Field 4 — Tanggal
              _FieldLabel('transaction_date'.tr()),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16,),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade500),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              // Field 5 — Catatan
              _FieldLabel('note'.tr()),
              const SizedBox(height: 8),
              TextField(
                controller: _noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                  hintText: 'add_note_hint'.tr(),
                ),
              ),
              const SizedBox(height: 24),

              // ── Tombol aksi ──────────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('cancel'.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _onSave,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('save_changes'.tr()),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}