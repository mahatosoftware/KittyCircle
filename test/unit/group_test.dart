import 'package:flutter_test/flutter_test.dart';
import 'package:kitty_circle/features/groups/domain/group_model.dart';
import 'package:kitty_circle/features/groups/data/group_repository.dart';
import 'package:kitty_circle/features/members/domain/member_model.dart';

void main() {
  group('GroupModel & MemberModel Tests', () {
    test('Group creation and map serialization', () {
      final group = GroupModel(
        groupId: 'group_test_1',
        name: '🌸 Sunshine Ladies',
        description: 'Test kitty group',
        contributionAmount: 2000,
        currency: '₹',
        frequency: 'Monthly',
        ownerId: 'user_priya_1',
        memberIds: ['user_priya_1', 'user_neha_2'],
        adminIds: ['user_priya_1'],
      );

      expect(group.groupId, equals('group_test_1'));
      expect(group.memberIds.length, equals(2));
      expect(group.contributionAmount, equals(2000));

      final map = group.toMap();
      expect(map['name'], equals('🌸 Sunshine Ladies'));
      expect(map['ownerId'], equals('user_priya_1'));
      expect(map['createdBy'], equals('user_priya_1'));
    });

    test('MemberRole parsing', () {
      expect(MemberModel.parseRole('Owner'), equals(MemberRole.owner));
      expect(MemberModel.parseRole('Admin'), equals(MemberRole.admin));
      expect(MemberModel.parseRole('Member'), equals(MemberRole.member));
      expect(MemberModel.parseRole('unknown'), equals(MemberRole.member));
    });

    test('MemberModel birthday and anniversary handling', () {
      final bday = DateTime(1992, 10, 15);
      final anniv = DateTime(2018, 11, 24);
      final member = MemberModel(
        userId: 'user_100',
        groupId: 'group_1',
        displayName: 'Anjali Sharma',
        role: MemberRole.admin,
        birthday: bday,
        anniversary: anniv,
      );

      expect(member.birthdayString, equals('15 October'));
      expect(member.anniversaryString, equals('24 November'));
      expect(member.roleString, equals('Admin'));

      final map = member.toMap();
      final restored = MemberModel.fromMap(map, 'user_100');
      expect(restored.displayName, equals('Anjali Sharma'));
      expect(restored.birthday?.year, equals(1992));
      expect(restored.anniversary?.month, equals(11));
    });

    test('GroupRepository createGroup emits newly created groups on stream', () async {
      final repo = GroupRepository();
      final futureList = repo.watchUserGroups('user_test_owner').take(2).toList();

      await repo.createGroup(
        name: '🌸 Royal Queens',
        description: 'Test Group',
        contributionAmount: 5000,
        ownerId: 'user_test_owner',
      );

      final results = await futureList;
      expect(results.first, isEmpty);
      expect(results.last.length, equals(1));
      expect(results.last.first.name, equals('🌸 Royal Queens'));
    });
  });
}
