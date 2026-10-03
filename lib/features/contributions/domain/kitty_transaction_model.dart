import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus { pending, paid, partiallyPaid, waived, cancelled }

class AuditLogItem {
  final String logId;
  final double previousAmount;
  final double newAmount;
  final PaymentStatus previousStatus;
  final PaymentStatus newStatus;
  final String reason;
  final String changedBy;
  final String changedByName;
  final DateTime timestamp;

  AuditLogItem({
    required this.logId,
    required this.previousAmount,
    required this.newAmount,
    required this.previousStatus,
    required this.newStatus,
    required this.reason,
    required this.changedBy,
    required this.changedByName,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'previousAmount': previousAmount,
      'newAmount': newAmount,
      'previousStatus': previousStatus.name,
      'newStatus': newStatus.name,
      'reason': reason,
      'changedBy': changedBy,
      'changedByName': changedByName,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory AuditLogItem.fromMap(Map<String, dynamic> map) {
    return AuditLogItem(
      logId: map['logId'] ?? '',
      previousAmount: (map['previousAmount'] as num?)?.toDouble() ?? 0.0,
      newAmount: (map['newAmount'] as num?)?.toDouble() ?? 0.0,
      previousStatus: _parseStatus(map['previousStatus']),
      newStatus: _parseStatus(map['newStatus']),
      reason: map['reason'] ?? '',
      changedBy: map['changedBy'] ?? '',
      changedByName: map['changedByName'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static PaymentStatus _parseStatus(String? statusStr) {
    switch (statusStr) {
      case 'paid':
        return PaymentStatus.paid;
      case 'partiallyPaid':
      case 'partial':
        return PaymentStatus.partiallyPaid;
      case 'waived':
        return PaymentStatus.waived;
      case 'cancelled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
  }
}

class KittyTransactionModel {
  final String transactionId;
  final String groupId;
  final String eventId;
  final String eventTitle;
  final DateTime eventDate;
  final String hostUserId;
  final String hostUserName;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final double amountExpected;
  final double amountPaid;
  final PaymentStatus status;
  final String paymentMethod; // 'Cash', 'UPI', 'Bank Transfer', 'Other'
  final DateTime? paymentDate;
  final String? paymentReference;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AuditLogItem> auditLogs;

  KittyTransactionModel({
    required this.transactionId,
    required this.groupId,
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.hostUserId,
    required this.hostUserName,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amountExpected,
    this.amountPaid = 0.0,
    this.status = PaymentStatus.pending,
    this.paymentMethod = 'UPI',
    this.paymentDate,
    this.paymentReference,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AuditLogItem>? auditLogs,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        auditLogs = auditLogs ?? [];

  double get remainingAmount => (amountExpected - amountPaid).clamp(0, double.infinity);
  bool get isPaid => status == PaymentStatus.paid;
  bool get isPending => status == PaymentStatus.pending;
  bool get isPartiallyPaid => status == PaymentStatus.partiallyPaid;
  bool get isWaived => status == PaymentStatus.waived;
  bool get isCancelled => status == PaymentStatus.cancelled;

  String get statusDisplay {
    switch (status) {
      case PaymentStatus.paid:
        return 'Paid ✓';
      case PaymentStatus.pending:
        return 'Pending ⏳';
      case PaymentStatus.partiallyPaid:
        return 'Partially Paid 🌗';
      case PaymentStatus.waived:
        return 'Waived 🤝';
      case PaymentStatus.cancelled:
        return 'Cancelled 🚫';
    }
  }

  static PaymentStatus parseStatus(String? statusStr) {
    switch (statusStr) {
      case 'paid':
      case 'Paid':
        return PaymentStatus.paid;
      case 'partiallyPaid':
      case 'Partially Paid':
      case 'partial':
        return PaymentStatus.partiallyPaid;
      case 'waived':
      case 'Waived':
        return PaymentStatus.waived;
      case 'cancelled':
      case 'Cancelled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'groupId': groupId,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'eventDate': Timestamp.fromDate(eventDate),
      'hostUserId': hostUserId,
      'hostUserName': hostUserName,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'amountExpected': amountExpected,
      'amountPaid': amountPaid,
      'status': status.name,
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate != null ? Timestamp.fromDate(paymentDate!) : null,
      'paymentReference': paymentReference,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'auditLogs': auditLogs.map((a) => a.toMap()).toList(),
    };
  }

  factory KittyTransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return KittyTransactionModel(
      transactionId: id,
      groupId: map['groupId'] ?? '',
      eventId: map['eventId'] ?? '',
      eventTitle: map['eventTitle'] ?? 'Kitty Gathering',
      eventDate: (map['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hostUserId: map['hostUserId'] ?? '',
      hostUserName: map['hostUserName'] ?? 'Host',
      fromUserId: map['fromUserId'] ?? '',
      fromUserName: map['fromUserName'] ?? 'Member',
      toUserId: map['toUserId'] ?? map['hostUserId'] ?? '',
      toUserName: map['toUserName'] ?? map['hostUserName'] ?? 'Host',
      amountExpected: (map['amountExpected'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      status: parseStatus(map['status']),
      paymentMethod: map['paymentMethod'] ?? 'UPI',
      paymentDate: (map['paymentDate'] as Timestamp?)?.toDate(),
      paymentReference: map['paymentReference'],
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      auditLogs: (map['auditLogs'] as List?)?.map((e) => AuditLogItem.fromMap(Map<String, dynamic>.from(e))).toList() ?? [],
    );
  }

  KittyTransactionModel copyWith({
    double? amountExpected,
    double? amountPaid,
    PaymentStatus? status,
    String? paymentMethod,
    DateTime? paymentDate,
    String? paymentReference,
    String? notes,
    List<AuditLogItem>? auditLogs,
  }) {
    return KittyTransactionModel(
      transactionId: transactionId,
      groupId: groupId,
      eventId: eventId,
      eventTitle: eventTitle,
      eventDate: eventDate,
      hostUserId: hostUserId,
      hostUserName: hostUserName,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      toUserId: toUserId,
      toUserName: toUserName,
      amountExpected: amountExpected ?? this.amountExpected,
      amountPaid: amountPaid ?? this.amountPaid,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentReference: paymentReference ?? this.paymentReference,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      auditLogs: auditLogs ?? this.auditLogs,
    );
  }
}
