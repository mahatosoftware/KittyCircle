import 'package:flutter_test/flutter_test.dart';
import 'package:kitty_circle/features/groups/domain/group_model.dart';
import 'package:kitty_circle/features/groups/data/group_repository.dart';
import 'package:kitty_circle/features/events/domain/host_schedule_model.dart';

void main() {
  group('Host Selection Tests', () {
    test('GroupModel host selection fields serialization & deserialization', () {
      final group = GroupModel(
        groupId: 'group_host_1',
        name: '🌸 Sunshine Kitty',
        description: 'Test kitty group',
        contributionAmount: 2000,
        ownerId: 'user_neha_1',
        memberIds: ['user_neha_1', 'user_pooja_2'],
        adminIds: ['user_neha_1'],
        hostSelectionMode: 'rotation',
        currentHostId: 'user_neha_1',
        currentHostName: 'Neha',
        volunteers: ['user_neha_1', 'user_pooja_2'],
      );

      expect(group.hostSelectionMode, equals('rotation'));
      expect(group.currentHostId, equals('user_neha_1'));
      expect(group.currentHostName, equals('Neha'));
      expect(group.volunteers, containsAll(['user_neha_1', 'user_pooja_2']));

      final map = group.toMap();
      expect(map['hostSelectionMode'], equals('rotation'));
      expect(map['currentHostName'], equals('Neha'));
      expect(map['volunteers'], equals(['user_neha_1', 'user_pooja_2']));

      final restored = GroupModel.fromMap(map, 'group_host_1');
      expect(restored.hostSelectionMode, equals('rotation'));
      expect(restored.currentHostName, equals('Neha'));
      expect(restored.volunteers.length, equals(2));
    });

    test('GroupRepository host selection operations', () async {
      final repo = GroupRepository();
      final group = await repo.createGroup(
        name: '🌸 Royal Queens',
        description: 'Host selection test group',
        contributionAmount: 3000,
        ownerId: 'user_neha_1',
      );

      // Set host selection mode
      await repo.updateHostSelectionMode(group.groupId, 'volunteer');
      var updated = await repo.getGroupById(group.groupId);
      expect(updated?.hostSelectionMode, equals('volunteer'));

      // Toggle volunteer
      await repo.toggleVolunteer(group.groupId, 'user_pooja_2');
      updated = await repo.getGroupById(group.groupId);
      expect(updated?.volunteers, contains('user_pooja_2'));

      // Toggle volunteer off
      await repo.toggleVolunteer(group.groupId, 'user_pooja_2');
      updated = await repo.getGroupById(group.groupId);
      expect(updated?.volunteers, isNot(contains('user_pooja_2')));

      // Set selected host
      await repo.setSelectedHost(group.groupId, 'user_pooja_2', 'Pooja', mode: 'random');
      updated = await repo.getGroupById(group.groupId);
      expect(updated?.currentHostId, equals('user_pooja_2'));
      expect(updated?.currentHostName, equals('Pooja'));
      expect(updated?.hostSelectionMode, equals('random'));
    });

    test('Rotation schedule ordering simulation (Neha -> Pooja -> Ritu -> Anjali -> Neha)', () {
      final members = ['Neha', 'Pooja', 'Ritu', 'Anjali'];
      final scheduleList = <String>[];

      for (int i = 0; i < 6; i++) {
        final hostName = members[i % members.length];
        scheduleList.add(hostName);
      }

      expect(scheduleList[0], equals('Neha'));
      expect(scheduleList[1], equals('Pooja'));
      expect(scheduleList[2], equals('Ritu'));
      expect(scheduleList[3], equals('Anjali'));
      expect(scheduleList[4], equals('Neha'));
      expect(scheduleList[5], equals('Pooja'));
    });
  });
}
