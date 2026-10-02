import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../domain/expense_model.dart';
import '../../../core/constants/app_constants.dart';

class ExpenseRepository {
  final FirebaseFirestore? _firestore;

  final Map<String, List<ExpenseModel>> _expenseStore = {};
  final Map<String, BudgetModel> _budgetStore = {};

  ExpenseRepository({this._firestore});

  Stream<List<ExpenseModel>> watchEventExpenses(String eventId) async* {
    yield _expenseStore[eventId] ?? [];

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        final snapStream = db
            .collection(AppConstants.expensesCollection)
            .where('eventId', isEqualTo: eventId)
            .snapshots();

        await for (final snap in snapStream) {
          final list = snap.docs.map((d) => ExpenseModel.fromMap(d.data(), d.id)).toList();
          _expenseStore[eventId] = list;
          yield list;
        }
      } catch (e) {
        debugPrint('Error streaming event expenses: $e');
        yield _expenseStore[eventId] ?? [];
      }
    }
  }

  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    _expenseStore.putIfAbsent(expense.eventId, () => []).add(expense);

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.expensesCollection)
            .doc(expense.expenseId)
            .set(expense.toMap());
      } catch (e) {
        debugPrint('Error adding expense to Firestore: $e');
      }
    }

    return expense;
  }

  Future<void> deleteExpense(String eventId, String expenseId) async {
    _expenseStore[eventId]?.removeWhere((e) => e.expenseId == expenseId);

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.expensesCollection)
            .doc(expenseId)
            .delete();
      } catch (e) {
        debugPrint('Error deleting expense from Firestore: $e');
      }
    }
  }

  Stream<BudgetModel?> watchEventBudget(String eventId) async* {
    yield _budgetStore[eventId] ?? BudgetModel(eventId: eventId);

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        final snapStream = db.collection('budgets').doc(eventId).snapshots();
        await for (final snap in snapStream) {
          if (snap.exists && snap.data() != null) {
            final model = BudgetModel.fromMap(snap.data()!, snap.id);
            _budgetStore[eventId] = model;
            yield model;
          } else {
            yield _budgetStore[eventId] ?? BudgetModel(eventId: eventId);
          }
        }
      } catch (e) {
        debugPrint('Error streaming budget: $e');
        yield _budgetStore[eventId] ?? BudgetModel(eventId: eventId);
      }
    }
  }

  Future<void> saveBudget(BudgetModel budget) async {
    _budgetStore[budget.eventId] = budget;

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db.collection('budgets').doc(budget.eventId).set(budget.toMap());
      } catch (e) {
        debugPrint('Error saving budget to Firestore: $e');
      }
    }
  }
}
