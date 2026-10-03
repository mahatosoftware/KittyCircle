import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../app/providers.dart';
import '../../domain/kitty_transaction_model.dart';
import 'record_payment_modal.dart';
import 'audit_history_modal.dart';

class WhoPaidWhomWidget extends ConsumerWidget {
  final String groupId;
  final String eventId;

  const WhoPaidWhomWidget({
    super.key,
    required this.groupId,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(eventTransactionsProvider((groupId: groupId, eventId: eventId)));
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final groupAsync = ref.watch(currentGroupProvider);
    final membersAsync = ref.watch(groupMembersProvider(groupId));

    final event = eventAsync.value;
    final group = groupAsync.value;
    final members = membersAsync.value ?? [];

    // Auto-generate transactions if empty
    if (transactionsAsync.value?.isEmpty == true && event != null && group != null && members.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(ledgerRepositoryProvider).generateKittySettlementTransactions(
              event: event,
              group: group,
              groupMembers: members,
            );
      });
    }

    return transactionsAsync.when(
      loading: () => const LoadingState(),
      error: (e, s) => ErrorState(message: e.toString()),
      data: (transactions) {
        if (transactions.isEmpty) {
          return AppCard(
            child: Column(
              children: [
                const Icon(Icons.account_balance_outlined, size: 40, color: AppColors.primary),
                const SizedBox(height: 8),
                const Text(
                  'No Transactions Generated Yet',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Click below to calculate expected settlement and generate transactions for this kitty.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                if (event != null && group != null && members.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(ledgerRepositoryProvider).generateKittySettlementTransactions(
                            event: event,
                            group: group,
                            groupMembers: members,
                          );
                    },
                    icon: const Icon(Icons.calculate),
                    label: const Text('Generate Kitty Settlement Ledger'),
                  ),
              ],
            ),
          );
        }

        final expectedTotal = transactions.fold<double>(0, (sum, t) => sum + t.amountExpected);
        final collectedTotal = transactions.fold<double>(0, (sum, t) => sum + t.amountPaid);
        final pendingTotal = (expectedTotal - collectedTotal).clamp(0, double.infinity);

        final hostName = transactions.first.hostUserName;
        final paidTxns = transactions.where((t) => t.isPaid || t.isPartiallyPaid).toList();
        final pendingTxns = transactions.where((t) => t.isPending).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 9. KITTY FINANCIAL SUMMARY CARD
            AppCard(
              gradient: AppColors.primaryGradient,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_outlined, color: AppColors.gold, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'FINANCIAL SUMMARY',
                        style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Host: $hostName',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryBox(title: 'Total Expected', amount: '₹${expectedTotal.toInt()}'),
                      _SummaryBox(title: 'Total Collected', amount: '₹${collectedTotal.toInt()}', color: AppColors.gold),
                      _SummaryBox(title: 'Pending', amount: '₹${pendingTotal.toInt()}', color: AppColors.secondaryLight),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),

                  // Paid & Pending summary lines
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Paid', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 4),
                            if (paidTxns.isEmpty)
                              const Text('No payments yet', style: TextStyle(color: Colors.white60, fontSize: 11))
                            else
                              ...paidTxns.map((t) => Text('✓ ${t.fromUserName} — ₹${t.amountPaid.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pending', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 4),
                            if (pendingTxns.isEmpty)
                              const Text('All payments settled! 🎉', style: TextStyle(color: Colors.white60, fontSize: 11))
                            else
                              ...pendingTxns.map((t) => Text('⏳ ${t.fromUserName} — ₹${t.remainingAmount.toInt()}', style: const TextStyle(color: Colors.white70, fontSize: 12))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. WHO PAID WHOM SECTION
            Row(
              children: [
                const Icon(Icons.sync_alt, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Who Paid Whom',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const Spacer(),
                Text(
                  '${paidTxns.length}/${transactions.length} Settled',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final txn = transactions[index];

                Color statusBg;
                Color statusColor;
                switch (txn.status) {
                  case PaymentStatus.paid:
                    statusBg = AppColors.success.withValues(alpha: 0.12);
                    statusColor = AppColors.success;
                    break;
                  case PaymentStatus.partiallyPaid:
                    statusBg = AppColors.info.withValues(alpha: 0.12);
                    statusColor = AppColors.info;
                    break;
                  case PaymentStatus.waived:
                    statusBg = Colors.purple.shade50;
                    statusColor = Colors.purple;
                    break;
                  case PaymentStatus.cancelled:
                    statusBg = Colors.grey.shade200;
                    statusColor = Colors.grey;
                    break;
                  case PaymentStatus.pending:
                  default:
                    statusBg = AppColors.warning.withValues(alpha: 0.12);
                    statusColor = AppColors.warning;
                    break;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // From Member
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                              child: Text(
                                txn.fromUserName.isNotEmpty ? txn.fromUserName[0] : 'M',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          txn.fromUserName,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          txn.toUserName,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Amount Expected: ₹${txn.amountExpected.toInt()}${txn.isPartiallyPaid ? " (Paid: ₹${txn.amountPaid.toInt()})" : ""}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Amount & Status Badge
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${txn.amountExpected.toInt()}',
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    txn.statusDisplay,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        if (txn.paymentDate != null || (txn.notes != null && txn.notes!.isNotEmpty)) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.payment, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 6),
                                Text(
                                  '${txn.paymentMethod}${txn.paymentDate != null ? " • ${DateFormat('dd MMM yyyy').format(txn.paymentDate!)}" : ""}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                if (txn.notes != null && txn.notes!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '(${txn.notes})',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (txn.auditLogs.isNotEmpty)
                              TextButton.icon(
                                onPressed: () => AuditHistoryModal.show(context, txn),
                                icon: const Icon(Icons.history, size: 14),
                                label: Text('Audit History (${txn.auditLogs.length})'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  textStyle: const TextStyle(fontSize: 11),
                                ),
                              ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => RecordPaymentModal.show(context, transaction: txn),
                              icon: const Icon(Icons.edit_note, size: 14),
                              label: Text(txn.isPaid ? 'Edit Payment' : 'Mark Payment'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final String amount;
  final Color? color;

  const _SummaryBox({required this.title, required this.amount, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(amount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color ?? Colors.white)),
          ),
        ],
      ),
    );
  }
}
