import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../app/providers.dart';
import '../../../contributions/domain/kitty_transaction_model.dart';
import '../../../contributions/presentation/widgets/record_payment_modal.dart';
import '../../domain/member_model.dart';

class MemberFinancialProfileModal {
  static void show(BuildContext context, {required MemberModel member}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _MemberFinancialContent(member: member),
    );
  }
}

class _MemberFinancialContent extends ConsumerWidget {
  final MemberModel member;

  const _MemberFinancialContent({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(
      memberTransactionsProvider((groupId: member.groupId, userId: member.userId)),
    );
    final eventsAsync = ref.watch(groupEventsProvider(member.groupId));

    final rawTxns = transactionsAsync.value ?? [];
    final events = eventsAsync.value ?? [];

    // Filter transactions to ONLY those occurring on or after member joined date
    // AND involving this member as participant or host!
    final memberTxns = rawTxns.where((t) {
      final isParticipantOrHost = t.fromUserId == member.userId || t.toUserId == member.userId;
      final isAfterJoined = t.eventDate.isAfter(member.joinedAt) ||
          (t.eventDate.year == member.joinedAt.year && t.eventDate.month == member.joinedAt.month);
      return isParticipantOrHost && isAfterJoined;
    }).toList();

    // Financial calculations
    final kittiesHostedCount = events.where((e) => e.hostId == member.userId).length;

    // Paid: Total amount paid as participant to hosts
    final totalPaid = memberTxns
        .where((t) => t.fromUserId == member.userId && t.isPaid)
        .fold<double>(0, (sum, t) => sum + t.amountPaid);

    // Received: Total amount received as host from members
    final totalReceived = memberTxns
        .where((t) => t.toUserId == member.userId && t.isPaid)
        .fold<double>(0, (sum, t) => sum + t.amountPaid);

    // Pending to Receive: Amount expected as host from members that is still pending
    final pendingToReceive = memberTxns
        .where((t) => t.toUserId == member.userId && t.isPending)
        .fold<double>(0, (sum, t) => sum + t.remainingAmount);

    // Outgoing pending payments (Whom to Pay)
    final outgoingPendingTxns = memberTxns
        .where((t) => t.fromUserId == member.userId && (t.isPending || t.status == PaymentStatus.partiallyPaid))
        .toList();

    // Incoming pending payments (Who Owes You as Host)
    final incomingPendingTxns = memberTxns
        .where((t) => t.toUserId == member.userId && (t.isPending || t.status == PaymentStatus.partiallyPaid))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: 20 + MediaQuery.paddingOf(context).bottom,
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

            // Header profile card
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    member.displayName.isNotEmpty ? member.displayName[0] : 'M',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.displayName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Joined: ${DateFormat('MMMM yyyy').format(member.joinedAt)} • ${member.roleString}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 11. FINANCIAL SUMMARY METRICS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MetricItem(title: 'Hosted', value: '$kittiesHostedCount ${kittiesHostedCount == 1 ? "kitty" : "kitties"}'),
                      _MetricItem(title: 'Paid', value: '₹${totalPaid.toInt()}', color: Colors.white),
                      _MetricItem(title: 'Received', value: '₹${totalReceived.toInt()}', color: AppColors.gold),
                    ],
                  ),
                  if (pendingToReceive > 0) ...[
                    const Divider(color: Colors.white24, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.pending_actions, color: AppColors.secondaryLight, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Pending to receive as Host: ₹${pendingToReceive.toInt()}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondaryLight),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // WHOM TO PAY SECTION (PENDING PAYMENTS TO MAKE)
            if (outgoingPendingTxns.isNotEmpty) ...[
              Row(
                children: const [
                  Icon(Icons.payment_outlined, color: AppColors.primary, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Whom to Pay (Pending Payments)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'List of hosts you need to pay for active kitty cycles:',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              ...outgoingPendingTxns.map((t) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.outbox_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pay ₹${t.remainingAmount.toInt()} to ${t.toUserName}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Host for ${t.eventTitle} • Date: ${DateFormat('dd MMM yyyy').format(t.eventDate)}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              t.statusDisplay,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => RecordPaymentModal.show(context, transaction: t),
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('Pay / Mark Paid'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            // WHO OWES YOU SECTION (FOR HOSTS)
            if (incomingPendingTxns.isNotEmpty) ...[
              Row(
                children: const [
                  Icon(Icons.inbox_rounded, color: AppColors.success, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Who Owes You (As Host)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Members who owe you for kitties you hosted:',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              ...incomingPendingTxns.map((t) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.success,
                        child: Icon(Icons.person, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${t.fromUserName} owes ₹${t.remainingAmount.toInt()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '${t.eventTitle} • ${t.statusDisplay}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => RecordPaymentModal.show(context, transaction: t),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        child: const Text('Mark Paid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            // ALL TRANSACTION HISTORY SECTION
            const Text(
              'All Transaction History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Only showing kitties occurring on or after member joining date.',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),

            if (memberTxns.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'No transactions recorded for this member yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: memberTxns.length,
                itemBuilder: (context, index) {
                  final t = memberTxns[index];
                  final isHost = t.toUserId == member.userId;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isHost ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          color: isHost ? AppColors.success : AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.eventTitle,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                isHost ? '${t.fromUserName} → ${t.toUserName} (You)' : '${t.fromUserName} (You) → ${t.toUserName} (Host)',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${t.amountExpected.toInt()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              t.statusDisplay,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: t.isPaid ? AppColors.success : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;

  const _MetricItem({required this.title, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? Colors.white)),
      ],
    );
  }
}
