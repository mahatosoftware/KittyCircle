import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../app/providers.dart';
import '../../domain/kitty_transaction_model.dart';
import 'record_payment_modal.dart';

class CircleLedgerTab extends ConsumerStatefulWidget {
  final String groupId;

  const CircleLedgerTab({super.key, required this.groupId});

  @override
  ConsumerState<CircleLedgerTab> createState() => _CircleLedgerTabState();
}

class _CircleLedgerTabState extends ConsumerState<CircleLedgerTab> {
  String _selectedMemberFilter = 'All';
  String _selectedKittyFilter = 'All';
  String _selectedStatusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(groupTransactionsProvider(widget.groupId));
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));

    final rawTransactions = transactionsAsync.value ?? [];
    final members = membersAsync.value ?? [];

    // Extract unique Kitty/Event titles for filter
    final kittyTitles = <String>{'All'};
    for (final t in rawTransactions) {
      if (t.eventTitle.isNotEmpty) kittyTitles.add(t.eventTitle);
    }

    // Filter transactions based on selection
    final filteredTransactions = rawTransactions.where((t) {
      if (_selectedMemberFilter != 'All') {
        if (t.fromUserName != _selectedMemberFilter && t.toUserName != _selectedMemberFilter) {
          return false;
        }
      }
      if (_selectedKittyFilter != 'All' && t.eventTitle != _selectedKittyFilter) {
        return false;
      }
      if (_selectedStatusFilter != 'All') {
        if (_selectedStatusFilter == 'Paid' && !t.isPaid) return false;
        if (_selectedStatusFilter == 'Pending' && !t.isPending) return false;
        if (_selectedStatusFilter == 'Partially Paid' && !t.isPartiallyPaid) return false;
      }
      return true;
    }).toList();

    final totalExpected = filteredTransactions.fold<double>(0, (s, t) => s + t.amountExpected);
    final totalCollected = filteredTransactions.fold<double>(0, (s, t) => s + t.amountPaid);
    final totalPending = (totalExpected - totalCollected).clamp(0, double.infinity);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 950),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Ledger Header Summary Card
            AppCard(
              gradient: AppColors.primaryGradient,
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_rounded, color: AppColors.gold, size: 20),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'CIRCLE-LEVEL LEDGER',
                          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Historical Transactions Across All Kitties',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatBox(title: 'Total Expected', amount: '₹${totalExpected.toInt()}'),
                      _StatBox(title: 'Total Collected', amount: '₹${totalCollected.toInt()}', color: AppColors.gold),
                      _StatBox(title: 'Pending', amount: '₹${totalPending.toInt()}', color: AppColors.secondaryLight),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Filters Section
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.filter_alt_outlined, color: AppColors.primary, size: 18),
                      SizedBox(width: 6),
                      Text('Filter Transactions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = constraints.maxWidth < 450 ? double.infinity : (constraints.maxWidth - 24) / 3;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          // Member Filter
                          SizedBox(
                            width: itemWidth < 140 ? double.infinity : itemWidth,
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedMemberFilter,
                              decoration: const InputDecoration(labelText: 'Member', isDense: true),
                              items: ['All', ...members.map((m) => m.displayName)].map((m) {
                                return DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedMemberFilter = val);
                              },
                            ),
                          ),

                          // Kitty Filter
                          SizedBox(
                            width: itemWidth < 140 ? double.infinity : itemWidth,
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedKittyFilter,
                              decoration: const InputDecoration(labelText: 'Kitty Party', isDense: true),
                              items: kittyTitles.map((k) {
                                return DropdownMenuItem(value: k, child: Text(k, overflow: TextOverflow.ellipsis));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedKittyFilter = val);
                              },
                            ),
                          ),

                          // Status Filter
                          SizedBox(
                            width: itemWidth < 140 ? double.infinity : itemWidth,
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedStatusFilter,
                              decoration: const InputDecoration(labelText: 'Status', isDense: true),
                              items: ['All', 'Paid', 'Pending', 'Partially Paid'].map((s) {
                                return DropdownMenuItem(value: s, child: Text(s));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedStatusFilter = val);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Transactions Table / List
            if (filteredTransactions.isEmpty)
              const EmptyState(
                title: 'No Matching Transactions',
                description: 'Try adjusting your filter options or select another member.',
                icon: Icons.receipt_long,
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  // If screen width is narrow (< 600px), use responsive Card view to avoid horizontal overflow
                  final isMobile = constraints.maxWidth < 600;

                  if (isMobile) {
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final t = filteredTransactions[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: InkWell(
                            onTap: () => RecordPaymentModal.show(context, transaction: t),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          t.eventTitle,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: t.isPaid
                                              ? AppColors.success.withValues(alpha: 0.12)
                                              : (t.isPending
                                                  ? AppColors.warning.withValues(alpha: 0.12)
                                                  : AppColors.info.withValues(alpha: 0.12)),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          t.statusDisplay,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color: t.isPaid ? AppColors.success : (t.isPending ? AppColors.warning : AppColors.info),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${t.fromUserName} → ${t.toUserName} (Host)',
                                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '₹${t.amountExpected.toInt()}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('dd MMM yyyy').format(t.eventDate),
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                      Row(
                                        children: const [
                                          Icon(Icons.edit_note, size: 14, color: AppColors.primary),
                                          SizedBox(width: 4),
                                          Text('Edit Payment', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  // Desktop / Wide Screen Table View with Horizontal Scrollbar fallback
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Table Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              child: Row(
                                children: const [
                                  SizedBox(width: 140, child: Text('Kitty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
                                  SizedBox(width: 130, child: Text('From', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
                                  SizedBox(width: 140, child: Text('To (Host)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
                                  SizedBox(width: 100, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
                                  SizedBox(width: 110, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
                                ],
                              ),
                            ),
                            const Divider(height: 1),

                            // Table Rows
                            ...filteredTransactions.map((t) {
                              return InkWell(
                                onTap: () => RecordPaymentModal.show(context, transaction: t),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: const BoxDecoration(
                                    border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 140,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(t.eventTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                                            Text(DateFormat('MMM yyyy').format(t.eventDate), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 130,
                                        child: Text(t.fromUserName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                                      ),
                                      SizedBox(
                                        width: 140,
                                        child: Text(t.toUserName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary), overflow: TextOverflow.ellipsis),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: Text('₹${t.amountExpected.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                      SizedBox(
                                        width: 110,
                                        child: Text(
                                          t.statusDisplay,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: t.isPaid ? AppColors.success : (t.isPending ? AppColors.warning : AppColors.info),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
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

class _StatBox extends StatelessWidget {
  final String title;
  final String amount;
  final Color? color;

  const _StatBox({required this.title, required this.amount, this.color});

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
