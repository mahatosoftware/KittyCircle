import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../app/providers.dart';
import '../domain/contribution_model.dart';

class ContributionScreen extends ConsumerWidget {
  final String groupId;

  const ContributionScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(groupContributionsProvider(groupId));

    return Scaffold(
      body: listAsync.when(
        loading: () => const LoadingState(),
        error: (e, s) => ErrorState(message: e.toString()),
        data: (items) {
          final expectedTotal = items.fold<double>(0, (sum, i) => sum + i.amountExpected);
          final collectedTotal = items.fold<double>(0, (sum, i) => sum + i.amountPaid);
          final pendingTotal = expectedTotal - collectedTotal;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // SUMMARY HEADER CARD
              AppCard(
                gradient: AppColors.primaryGradient,
                child: Column(
                  children: [
                    const Text('OCTOBER CONTRIBUTION', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    Text('₹2,000 × ${items.length} members', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryItem(title: 'Expected', amount: '₹${expectedTotal.toInt()}'),
                        _SummaryItem(title: 'Collected', amount: '₹${collectedTotal.toInt()}', color: AppColors.gold),
                        _SummaryItem(title: 'Pending', amount: '₹${pendingTotal.toInt()}', color: AppColors.secondaryLight),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text('MEMBER PAYMENT STATUS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2)),
              const SizedBox(height: 12),

              ...items.map((item) {
                Color statusColor;
                switch (item.status) {
                  case ContributionStatus.paid:
                    statusColor = AppColors.success;
                    break;
                  case ContributionStatus.pending:
                    statusColor = AppColors.warning;
                    break;
                  case ContributionStatus.partial:
                    statusColor = AppColors.info;
                    break;
                  case ContributionStatus.exempt:
                    statusColor = AppColors.textMuted;
                    break;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: MemberAvatar(name: item.userName),
                    title: Text(item.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Paid: ₹${item.amountPaid.toInt()} / Expected: ₹${item.amountExpected.toInt()}'),
                    trailing: MenuAnchor(
                      menuChildren: ContributionStatus.values.map((st) {
                        return MenuItemButton(
                          child: Text(st.name.toUpperCase()),
                          onPressed: () {
                            double newAmount = item.amountExpected;
                            if (st == ContributionStatus.pending || st == ContributionStatus.exempt) newAmount = 0;
                            if (st == ContributionStatus.partial) newAmount = item.amountExpected / 2;

                            ref.read(contributionRepositoryProvider).updateContributionStatus(
                                  groupId: groupId,
                                  contributionId: item.contributionId,
                                  status: st,
                                  amountPaid: newAmount,
                                );
                          },
                        );
                      }).toList(),
                      builder: (ctx, controller, child) {
                        return InkWell(
                          onTap: () {
                            if (controller.isOpen) {
                              controller.close();
                            } else {
                              controller.open();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.statusString,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_drop_down, color: statusColor, size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String amount;
  final Color? color;

  const _SummaryItem({required this.title, required this.amount, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(amount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color ?? Colors.white)),
      ],
    );
  }
}
