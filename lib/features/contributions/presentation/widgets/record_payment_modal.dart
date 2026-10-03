import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../app/providers.dart';
import '../../domain/kitty_transaction_model.dart';

class RecordPaymentModal {
  static void show(
    BuildContext context, {
    required KittyTransactionModel transaction,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RecordPaymentContent(transaction: transaction),
    );
  }
}

class _RecordPaymentContent extends ConsumerStatefulWidget {
  final KittyTransactionModel transaction;

  const _RecordPaymentContent({required this.transaction});

  @override
  ConsumerState<_RecordPaymentContent> createState() => _RecordPaymentContentState();
}

class _RecordPaymentContentState extends ConsumerState<_RecordPaymentContent> {
  late TextEditingController _amountPaidCtrl;
  late TextEditingController _refCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _reasonCtrl;

  late PaymentStatus _selectedStatus;
  late String _selectedMethod;
  late DateTime _paymentDate;
  bool _isSaving = false;

  final List<String> _paymentMethods = ['UPI', 'Cash', 'Bank Transfer', 'Other'];

  @override
  void initState() {
    super.initState();
    _amountPaidCtrl = TextEditingController(
      text: (widget.transaction.amountPaid > 0
              ? widget.transaction.amountPaid
              : widget.transaction.amountExpected)
          .toInt()
          .toString(),
    );
    _refCtrl = TextEditingController(text: widget.transaction.paymentReference ?? '');
    _notesCtrl = TextEditingController(text: widget.transaction.notes ?? '');
    _reasonCtrl = TextEditingController();

    _selectedStatus = widget.transaction.status == PaymentStatus.pending
        ? PaymentStatus.paid
        : widget.transaction.status;
    _selectedMethod = widget.transaction.paymentMethod.isNotEmpty ? widget.transaction.paymentMethod : 'UPI';
    _paymentDate = widget.transaction.paymentDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountPaidCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _handleSavePayment() async {
    setState(() => _isSaving = true);

    final user = ref.read(currentUserProvider).value;
    final userId = user?.uid ?? 'user_organizer';
    final userName = user?.displayName ?? 'Organizer';

    final paidAmount = double.tryParse(_amountPaidCtrl.text.trim()) ?? widget.transaction.amountExpected;

    // Auto-adjust status for partial payment if paid < expected
    PaymentStatus finalStatus = _selectedStatus;
    if (paidAmount < widget.transaction.amountExpected && paidAmount > 0 && _selectedStatus == PaymentStatus.paid) {
      finalStatus = PaymentStatus.partiallyPaid;
    }

    await ref.read(ledgerRepositoryProvider).recordPayment(
      groupId: widget.transaction.groupId,
      transactionId: widget.transaction.transactionId,
      amountPaid: paidAmount,
      status: finalStatus,
      paymentMethod: _selectedMethod,
      paymentReference: _refCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      paymentDate: _paymentDate,
      recordedByUserId: userId,
      recordedByUserName: userName,
      changeReason: _reasonCtrl.text.trim().isNotEmpty ? _reasonCtrl.text.trim() : null,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment recorded: ${widget.transaction.fromUserName} → ${widget.transaction.toUserName} 🎉'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20 + MediaQuery.paddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.payments_outlined, color: AppColors.primary, size: 24),
                SizedBox(width: 8),
                Text(
                  'Mark Payment',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Who Paid Whom Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('From', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        Text(t.fromUserName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: AppColors.primary),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('To (Host)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        Text(t.toUserName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amountPaidCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount Paid (₹) *',
                      prefixIcon: const Icon(Icons.currency_rupee),
                      helperText: 'Expected: ₹${t.amountExpected.toInt()}',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<PaymentStatus>(
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: PaymentStatus.values.map((st) {
                      return DropdownMenuItem(
                        value: st,
                        child: Text(st.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: _selectedMethod,
              decoration: const InputDecoration(labelText: 'Payment Method', prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
              items: _paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedMethod = val);
              },
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _refCtrl,
              decoration: const InputDecoration(
                labelText: 'Payment Reference / Transaction ID (Optional)',
                hintText: 'e.g., UPI Ref 98234710',
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 14),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month, color: AppColors.primary),
              title: const Text('Payment Date'),
              subtitle: Text(DateFormat('dd MMMM yyyy, hh:mm a').format(_paymentDate)),
              trailing: TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _paymentDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _paymentDate = DateTime(picked.year, picked.month, picked.day, _paymentDate.hour, _paymentDate.minute));
                  }
                },
                child: const Text('Change'),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes / Remarks (Optional)',
                hintText: 'e.g., Paid via GPay directly to Sneha',
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason for Edit / Audit Log (Optional)',
                hintText: 'e.g., Corrected payment amount',
                prefixIcon: Icon(Icons.history),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSaving ? null : _handleSavePayment,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Payment Record 🎉'),
            ),
          ],
        ),
      ),
    );
  }
}
