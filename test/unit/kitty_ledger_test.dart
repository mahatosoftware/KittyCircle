import 'package:flutter_test/flutter_test.dart';
import 'package:kitty_circle/features/groups/domain/group_model.dart';
import 'package:kitty_circle/features/members/domain/member_model.dart';
import 'package:kitty_circle/features/events/domain/event_model.dart';
import 'package:kitty_circle/features/contributions/domain/kitty_transaction_model.dart';
import 'package:kitty_circle/features/contributions/data/ledger_repository.dart';

void main() {
  group('Kitty Ledger & No Retroactive Obligation Tests', () {
    late LedgerRepository repository;

    setUp(() {
      repository = LedgerRepository();
    });

    test('Section 1, 6 & 8: No Retroactive Obligation & Settlement Calculation', () async {
      final group = GroupModel(
        groupId: 'group_sunshine',
        name: '🌸 Sunshine Ladies',
        description: 'Test Group',
        contributionAmount: 2000,
        ownerId: 'user_neha',
        memberIds: ['user_neha', 'user_pooja', 'user_ritu'],
        adminIds: ['user_neha'],
      );

      // Members joining in January 2026
      final neha = MemberModel(
        userId: 'user_neha',
        groupId: 'group_sunshine',
        displayName: 'Neha',
        joinedAt: DateTime(2026, 1, 1),
      );
      final pooja = MemberModel(
        userId: 'user_pooja',
        groupId: 'group_sunshine',
        displayName: 'Pooja',
        joinedAt: DateTime(2026, 1, 1),
      );
      final ritu = MemberModel(
        userId: 'user_ritu',
        groupId: 'group_sunshine',
        displayName: 'Ritu',
        joinedAt: DateTime(2026, 1, 1),
      );

      // January Kitty - Hosted by Neha
      final janEvent = EventModel(
        eventId: 'evt_jan_2026',
        groupId: 'group_sunshine',
        title: 'January Kitty',
        date: DateTime(2026, 1, 15),
        startTime: '4:00 PM',
        endTime: '7:00 PM',
        hostId: 'user_neha',
        hostName: 'Neha',
        venue: 'Neha\'s Residence',
        createdBy: 'user_neha',
      );

      final janTxns = await repository.generateKittySettlementTransactions(
        event: janEvent,
        group: group,
        groupMembers: [neha, pooja, ritu],
      );

      // Verify January: Host Neha does NOT owe herself. Pooja & Ritu owe Neha ₹2,000.
      expect(janTxns.length, equals(2));
      expect(janTxns.any((t) => t.fromUserId == 'user_pooja' && t.toUserId == 'user_neha'), isTrue);
      expect(janTxns.any((t) => t.fromUserId == 'user_ritu' && t.toUserId == 'user_neha'), isTrue);
      expect(janTxns.any((t) => t.fromUserId == 'user_neha'), isFalse); // Host exception

      // February Kitty - Hosted by Pooja
      final febEvent = EventModel(
        eventId: 'evt_feb_2026',
        groupId: 'group_sunshine',
        title: 'February Kitty',
        date: DateTime(2026, 2, 15),
        startTime: '4:00 PM',
        endTime: '7:00 PM',
        hostId: 'user_pooja',
        hostName: 'Pooja',
        venue: 'Pooja\'s Residence',
        createdBy: 'user_neha',
      );

      final febTxns = await repository.generateKittySettlementTransactions(
        event: febEvent,
        group: group,
        groupMembers: [neha, pooja, ritu],
      );

      expect(febTxns.length, equals(2));
      expect(febTxns.any((t) => t.fromUserId == 'user_neha' && t.toUserId == 'user_pooja'), isTrue);
      expect(febTxns.any((t) => t.fromUserId == 'user_ritu' && t.toUserId == 'user_pooja'), isTrue);

      // March - Sneha joins in March 2026
      final sneha = MemberModel(
        userId: 'user_sneha',
        groupId: 'group_sunshine',
        displayName: 'Sneha',
        joinedAt: DateTime(2026, 3, 1),
      );

      // March Kitty - Hosted by Sneha
      final marEvent = EventModel(
        eventId: 'evt_mar_2026',
        groupId: 'group_sunshine',
        title: 'March Kitty',
        date: DateTime(2026, 3, 15),
        startTime: '4:00 PM',
        endTime: '7:00 PM',
        hostId: 'user_sneha',
        hostName: 'Sneha',
        venue: 'Sneha\'s Residence',
        createdBy: 'user_neha',
      );

      final marTxns = await repository.generateKittySettlementTransactions(
        event: marEvent,
        group: group,
        groupMembers: [neha, pooja, ritu, sneha],
      );

      // March Kitty: Neha, Pooja, Ritu owe Sneha ₹2,000. Sneha does NOT owe herself.
      expect(marTxns.length, equals(3));
      expect(marTxns.any((t) => t.fromUserId == 'user_neha' && t.toUserId == 'user_sneha'), isTrue);
      expect(marTxns.any((t) => t.fromUserId == 'user_pooja' && t.toUserId == 'user_sneha'), isTrue);
      expect(marTxns.any((t) => t.fromUserId == 'user_ritu' && t.toUserId == 'user_sneha'), isTrue);

      // CRITICAL CHECK: Sneha does NOT owe any retroactive transactions for Jan or Feb!
      final snehaAllTxns = (await repository.watchGroupTransactions('group_sunshine').first)
          .where((t) => t.fromUserId == 'user_sneha')
          .toList();

      expect(snehaAllTxns, isEmpty, reason: 'Sneha must never owe retroactive payments for kitties before her join date!');
    });

    test('Section 12, 13 & 14: Payment Recording, Partial Payment & Audit Logs', () async {
      final txn = KittyTransactionModel(
        transactionId: 'txn_test_100',
        groupId: 'group_1',
        eventId: 'evt_1',
        eventTitle: 'March Kitty',
        eventDate: DateTime(2026, 3, 15),
        hostUserId: 'user_sneha',
        hostUserName: 'Sneha',
        fromUserId: 'user_pooja',
        fromUserName: 'Pooja',
        toUserId: 'user_sneha',
        toUserName: 'Sneha',
        amountExpected: 2000,
        amountPaid: 0,
        status: PaymentStatus.pending,
      );

      expect(txn.remainingAmount, equals(2000));
      expect(txn.isPending, isTrue);

      // Partial Payment Record
      final partialTxn = txn.copyWith(
        amountPaid: 1000,
        status: PaymentStatus.partiallyPaid,
      );
      expect(partialTxn.remainingAmount, equals(1000));
      expect(partialTxn.isPartiallyPaid, isTrue);

      // Full Payment Record
      final paidTxn = txn.copyWith(
        amountPaid: 2000,
        status: PaymentStatus.paid,
      );
      expect(paidTxn.remainingAmount, equals(0));
      expect(paidTxn.isPaid, isTrue);
      expect(paidTxn.statusDisplay, equals('Paid ✓'));
    });
  });
}
