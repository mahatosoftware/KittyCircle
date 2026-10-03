import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../app/providers.dart';
import '../domain/expense_model.dart';
import '../../members/domain/member_model.dart';

class ExpenseScreen extends ConsumerStatefulWidget {
  final String eventId;

  const ExpenseScreen({super.key, required this.eventId});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  final Set<String> _settledMemberIds = {};

  void _showAddExpenseModal(BuildContext context, WidgetRef ref, List<MemberModel> members) {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = 'Food';
    String paidBy = members.isNotEmpty ? members.first.displayName : 'Host';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20 + MediaQuery.paddingOf(ctx).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Add Event Expense 💵', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category)),
                      items: ['Food', 'Venue', 'Decoration', 'Games', 'Gifts', 'Transport', 'Other'].map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => category = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Description', hintText: 'e.g. Snacks & mocktails spread', prefixIcon: Icon(Icons.description)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount (₹)', prefixIcon: Icon(Icons.payments)),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: paidBy,
                      decoration: const InputDecoration(labelText: 'Paid By Member', prefixIcon: Icon(Icons.person)),
                      items: (members.isNotEmpty
                              ? members.map((m) => DropdownMenuItem(value: m.displayName, child: Text(m.displayName))).toList()
                              : [const DropdownMenuItem(value: 'Host', child: Text('Host'))]),
                      onChanged: (val) {
                        if (val != null) setModalState(() => paidBy = val);
                      },
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      text: 'Record Expense 🎉',
                      onPressed: () async {
                        if (amountCtrl.text.isNotEmpty) {
                          final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                          final exp = ExpenseModel(
                            expenseId: 'e_${DateTime.now().millisecondsSinceEpoch}',
                            eventId: widget.eventId,
                            category: category,
                            description: descCtrl.text.trim(),
                            amount: amount,
                            paidBy: paidBy,
                          );
                          await ref.read(expenseRepositoryProvider).addExpense(exp);
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.eventId.isEmpty) {
      return const EmptyState(
        title: 'No Event Selected',
        description: 'Create or select an event to manage party expenses.',
        icon: Icons.receipt_long_outlined,
      );
    }

    final expensesAsync = ref.watch(eventExpensesProvider(widget.eventId));
    final budgetAsync = ref.watch(eventBudgetProvider(widget.eventId));
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final event = eventAsync.value;
    final groupId = event?.groupId ?? ref.watch(selectedGroupIdProvider) ?? '';
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final members = membersAsync.value ?? [];

    return Scaffold(
      body: expensesAsync.when(
        loading: () => const LoadingState(),
        error: (e, s) => ErrorState(message: e.toString()),
        data: (expenses) {
          final budget = budgetAsync.value;
          final totalSpent = expenses.fold<double>(0, (sum, e) => sum + e.amount);
          final totalBudget = budget?.totalBudget ?? 15000.0;
          final left = totalBudget - totalSpent;
          final progress = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

          // Split calculation: Equal share per member
          final memberCount = members.isNotEmpty ? members.length : 1;
          final perPersonShare = totalSpent / memberCount;

          // Paid amounts by member name
          final Map<String, double> paidByMemberMap = {};
          for (final e in expenses) {
            paidByMemberMap[e.paidBy] = (paidByMemberMap[e.paidBy] ?? 0.0) + e.amount;
          }

          // Build settlement balance list for all members
          final List<Map<String, dynamic>> memberBalances = members.map((m) {
            final paid = paidByMemberMap[m.displayName] ?? 0.0;
            final balance = paid - perPersonShare;
            final isSettled = _settledMemberIds.contains(m.userId) || balance.abs() < 1;
            return {
              'userId': m.userId,
              'name': m.displayName,
              'paid': paid,
              'share': perPersonShare,
              'balance': balance,
              'isSettled': isSettled,
            };
          }).toList();

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 950),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // BUDGET PROGRESS CARD
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'PARTY BUDGET PROGRESS',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.1),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('Budget: ₹${totalBudget.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 12,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(left >= 0 ? AppColors.primary : AppColors.error),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Spent: ₹${totalSpent.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Text('Left: ₹${left.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, color: left >= 0 ? AppColors.success : AppColors.error)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // EQUAL SPLIT & SETTLEMENT SUMMARY CARD
                  AppCard(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calculate, color: AppColors.primary, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'EQUAL SPLIT & SETTLEMENT',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.1),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                final groupAsync = ref.read(currentGroupProvider);
                                WhatsAppService.shareExpenseSettlement(
                                  eventTitle: event?.title ?? 'Kitty Party',
                                  groupName: groupAsync.value?.name ?? 'Sunshine Ladies',
                                  totalExpenses: totalSpent,
                                  perPersonShare: perPersonShare,
                                  memberBalances: memberBalances,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.share, size: 16, color: Colors.white),
                              label: const Text('Share Settlement', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    const Text('Total Expenses', style: TextStyle(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text('₹${totalSpent.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Share ($memberCount members)',
                                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 4),
                                    Text('₹${perPersonShare.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // MEMBER SETTLEMENT BREAKDOWN LIST
                  const Text('MEMBER SETTLEMENT BALANCES', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2)),
                  const SizedBox(height: 10),

                  if (members.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No members found for settlement calculation.', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  else
                    ...memberBalances.map((m) {
                      final double bal = m['balance'] as double;
                      final bool isSettled = m['isSettled'] as bool;
                      final String userId = m['userId'] as String;

                      Color statusColor;
                      String statusText;

                      if (isSettled) {
                        statusColor = AppColors.success;
                        statusText = 'SETTLED 🎉';
                      } else if (bal > 0) {
                        statusColor = AppColors.success;
                        statusText = 'RECEIVES ₹${bal.toInt()}';
                      } else if (bal < 0) {
                        statusColor = AppColors.warning;
                        statusText = 'OWES ₹${(-bal).toInt()}';
                      } else {
                        statusColor = AppColors.success;
                        statusText = 'SETTLED 🎉';
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: MemberAvatar(name: m['name'] as String),
                            title: Text(
                              m['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                    ),
                                  ),
                                  Text(
                                    'Paid: ₹${(m['paid'] as double).toInt()} • Share: ₹${(m['share'] as double).toInt()}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            trailing: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  if (_settledMemberIds.contains(userId)) {
                                    _settledMemberIds.remove(userId);
                                  } else {
                                    _settledMemberIds.add(userId);
                                  }
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isSettled ? Colors.grey : AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                side: BorderSide(color: isSettled ? Colors.grey.shade400 : AppColors.primary),
                              ),
                              child: Text(
                                isSettled ? 'Undo' : 'Settle Up',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 24),

                  // ITEMIZED EXPENSES LIST
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'ITEMIZED EXPENSES',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: AppColors.primary),
                        onPressed: () => _showAddExpenseModal(context, ref, members),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (expenses.isEmpty)
                    const EmptyState(
                      title: 'No Expenses Logged Yet',
                      description: 'Add catering, venue, decorations, or game expenses to calculate equal split.',
                      icon: Icons.receipt_long,
                    )
                  else
                    ...expenses.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                              child: Text(e.category.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ),
                            title: Text(
                              e.description.isNotEmpty ? e.description : e.category,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            subtitle: Text(
                              'Category: ${e.category} • Paid by ${e.paidBy}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            trailing: Text('₹${e.amount.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
