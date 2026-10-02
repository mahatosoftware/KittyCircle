import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/expense_model.dart';

class ExpenseRepository {
  final FirebaseFirestore? _firestore;

  final Map<String, List<ExpenseModel>> _expenseStore = {
    'event_oct_18': [
      ExpenseModel(expenseId: 'e1', eventId: 'event_oct_18', category: 'Food', description: 'Chat counter & Snacks spread', amount: 5000, paidBy: 'Priya'),
      ExpenseModel(expenseId: 'e2', eventId: 'event_oct_18', category: 'Decoration', description: 'Bollywood retro backdrop & props', amount: 2000, paidBy: 'Priya'),
      ExpenseModel(expenseId: 'e3', eventId: 'event_oct_18', category: 'Venue', description: 'Table & chair rentals', amount: 3000, paidBy: 'Priya'),
      ExpenseModel(expenseId: 'e4', eventId: 'event_oct_18', category: 'Games', description: 'Prizes & gift hampers', amount: 2500, paidBy: 'Neha'),
      ExpenseModel(expenseId: 'e5', eventId: 'event_oct_18', category: 'Other', description: 'Disposable cups & napkins', amount: 500, paidBy: 'Priya'),
    ],
  };

  final Map<String, BudgetModel> _budgetStore = {
    'event_oct_18': BudgetModel(
      eventId: 'event_oct_18',
      foodBudget: 5000,
      decorationBudget: 2000,
      gamesPrizesBudget: 3000,
      venueBudget: 4000,
      otherBudget: 1000,
    ),
  };

  ExpenseRepository({this._firestore});

  Stream<List<ExpenseModel>> watchEventExpenses(String eventId) async* {
    if (_firestore != null) {
      final snap = await _firestore.collection('expenses').where('eventId', isEqualTo: eventId).get();
      if (snap.docs.isNotEmpty) {
        yield snap.docs.map((d) => ExpenseModel.fromMap(d.data(), d.id)).toList();
        return;
      }
    }
    yield _expenseStore[eventId] ?? [];
  }

  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    _expenseStore.putIfAbsent(expense.eventId, () => []).add(expense);
    return expense;
  }

  Future<void> deleteExpense(String eventId, String expenseId) async {
    _expenseStore[eventId]?.removeWhere((e) => e.expenseId == expenseId);
  }

  Stream<BudgetModel?> watchEventBudget(String eventId) async* {
    yield _budgetStore[eventId] ?? BudgetModel(eventId: eventId);
  }

  Future<void> saveBudget(BudgetModel budget) async {
    _budgetStore[budget.eventId] = budget;
  }
}
