import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String expenseId;
  final String eventId;
  final String category; // 'Food', 'Venue', 'Decoration', 'Games', 'Gifts', 'Transport', 'Other'
  final String description;
  final double amount;
  final String paidBy;
  final String? receiptUrl;
  final DateTime createdAt;

  ExpenseModel({
    required this.expenseId,
    required this.eventId,
    required this.category,
    required this.description,
    required this.amount,
    required this.paidBy,
    this.receiptUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'expenseId': expenseId,
      'eventId': eventId,
      'category': category,
      'description': description,
      'amount': amount,
      'paidBy': paidBy,
      'receiptUrl': receiptUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseModel(
      expenseId: id,
      eventId: map['eventId'] ?? '',
      category: map['category'] ?? 'Other',
      description: map['description'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paidBy: map['paidBy'] ?? 'Host',
      receiptUrl: map['receiptUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class BudgetModel {
  final String eventId;
  final double foodBudget;
  final double decorationBudget;
  final double gamesPrizesBudget;
  final double venueBudget;
  final double otherBudget;

  BudgetModel({
    required this.eventId,
    this.foodBudget = 0.0,
    this.decorationBudget = 0.0,
    this.gamesPrizesBudget = 0.0,
    this.venueBudget = 0.0,
    this.otherBudget = 0.0,
  });

  double get totalBudget => foodBudget + decorationBudget + gamesPrizesBudget + venueBudget + otherBudget;

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'foodBudget': foodBudget,
      'decorationBudget': decorationBudget,
      'gamesPrizesBudget': gamesPrizesBudget,
      'venueBudget': venueBudget,
      'otherBudget': otherBudget,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map, String id) {
    return BudgetModel(
      eventId: id,
      foodBudget: (map['foodBudget'] as num?)?.toDouble() ?? 0.0,
      decorationBudget: (map['decorationBudget'] as num?)?.toDouble() ?? 0.0,
      gamesPrizesBudget: (map['gamesPrizesBudget'] as num?)?.toDouble() ?? 0.0,
      venueBudget: (map['venueBudget'] as num?)?.toDouble() ?? 0.0,
      otherBudget: (map['otherBudget'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
