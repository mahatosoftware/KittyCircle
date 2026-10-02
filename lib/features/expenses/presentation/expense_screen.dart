import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../app/providers.dart';
import '../domain/expense_model.dart';

class ExpenseScreen extends ConsumerWidget {
  final String eventId;

  const ExpenseScreen({super.key, required this.eventId});

  void _showAddExpenseModal(BuildContext context, WidgetRef ref) {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = 'Food';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20 + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add Event Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['Food', 'Venue', 'Decoration', 'Games', 'Gifts', 'Transport', 'Other'].map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) {
                  if (val != null) category = val;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description', hintText: 'Snacks spread'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (₹)', prefixIcon: Icon(Icons.payments)),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Record Expense',
                onPressed: () async {
                  if (amountCtrl.text.isNotEmpty) {
                    final user = ref.read(currentUserProvider).value;
                    final exp = ExpenseModel(
                      expenseId: 'e_${DateTime.now().millisecondsSinceEpoch}',
                      eventId: eventId,
                      category: category,
                      description: descCtrl.text.trim(),
                      amount: double.parse(amountCtrl.text.trim()),
                      paidBy: (user != null && user.displayName.isNotEmpty) ? user.displayName : 'Host',
                    );
                    await ref.read(expenseRepositoryProvider).addExpense(exp);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (eventId.isEmpty) {
      return const EmptyState(
        title: 'No Event Selected',
        description: 'Create or select an event to manage party expenses.',
        icon: Icons.receipt_long_outlined,
      );
    }

    final expensesAsync = ref.watch(eventExpensesProvider(eventId));
    final budgetAsync = ref.watch(eventBudgetProvider(eventId));

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
                        const Text('PARTY BUDGET PROGRESS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.1)),
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
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('EVENT EXPENSES', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2)),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.primary),
                    onPressed: () => _showAddExpenseModal(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              ...expenses.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        child: Text(e.category.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                      title: Text(e.description.isNotEmpty ? e.description : e.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Category: ${e.category} • Paid by ${e.paidBy}'),
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
