import 'package:flutter_test/flutter_test.dart';
import 'package:kitty_circle/features/groups/domain/group_model.dart';
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
    });

    test('MemberRole parsing', () {
      expect(MemberModel.parseRole('Owner'), equals(MemberRole.owner));
      expect(MemberModel.parseRole('Admin'), equals(MemberRole.admin));
      expect(MemberModel.parseRole('Member'), equals(MemberRole.member));
      expect(MemberModel.parseRole('unknown'), equals(MemberRole.member));
    });
  });
}
