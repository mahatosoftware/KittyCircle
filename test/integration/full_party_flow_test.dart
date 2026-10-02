import 'package:flutter_test/flutter_test.dart';
import 'package:kitty_circle/features/auth/domain/user_model.dart';
import 'package:kitty_circle/features/groups/data/group_repository.dart';
import 'package:kitty_circle/features/members/data/member_repository.dart';
import 'package:kitty_circle/features/members/domain/member_model.dart';
import 'package:kitty_circle/features/events/data/event_repository.dart';
import 'package:kitty_circle/features/events/domain/event_model.dart';
import 'package:kitty_circle/features/events/domain/rsvp_model.dart';
import 'package:kitty_circle/features/events/domain/attendance_model.dart';
import 'package:kitty_circle/features/games/data/game_repository.dart';
import 'package:kitty_circle/features/games/domain/game_models.dart';
import 'package:kitty_circle/features/games/engine/game_engine.dart';
import 'package:kitty_circle/features/expenses/data/expense_repository.dart';
import 'package:kitty_circle/features/expenses/domain/expense_model.dart';
import 'package:kitty_circle/features/memories/data/memory_repository.dart';
import 'package:kitty_circle/features/memories/domain/memory_model.dart';

void main() {
  group('KittyCircle Full Party Flow Integration Test (Section 69)', () {
    late GroupRepository groupRepo;
    late MemberRepository memberRepo;
    late EventRepository eventRepo;
    late GameRepository gameRepo;
    late ExpenseRepository expenseRepo;
    late MemoryRepository memoryRepo;

    setUp(() {
      groupRepo = GroupRepository();
      memberRepo = MemberRepository();
      eventRepo = EventRepository();
      gameRepo = GameRepository();
      expenseRepo = ExpenseRepository();
      memoryRepo = MemoryRepository();
    });

    test('Executes end-to-end Kitty party lifecycle successfully', () async {
      // 1. Create Account / User
      final user = UserModel(
        uid: 'user_priya_101',
        displayName: 'Priya Organizer',
        email: 'priya@kittycircle.app',
      );
      expect(user.displayName, equals('Priya Organizer'));

      // 2. Create Kitty Group
      final group = await groupRepo.createGroup(
        name: '🌺 Weekend Blossoms',
        description: 'Monthly fun kitty group',
        contributionAmount: 2500,
        ownerId: user.uid,
      );
      expect(group.name, equals('🌺 Weekend Blossoms'));

      // 3. Invite Member & Member Accepts
      await memberRepo.addMember(
        groupId: group.groupId,
        userId: 'user_neha_202',
        displayName: 'Neha Member',
        role: MemberRole.member,
      );
      final members = await memberRepo.watchGroupMembers(group.groupId).first;
      expect(members.length, greaterThanOrEqualTo(1));

      // 4. Create Event
      final event = EventModel(
        eventId: 'event_nov_10',
        groupId: group.groupId,
        title: 'November High Tea Kitty',
        date: DateTime(2026, 11, 10, 16, 0),
        startTime: '4:00 PM',
        endTime: '7:00 PM',
        hostId: user.uid,
        hostName: user.displayName,
        venue: 'Priya\'s Residence',
        theme: 'Floral Paradise',
        createdBy: user.uid,
      );
      await eventRepo.createEvent(event);

      // 5. Member RSVPs
      await eventRepo.setRsvp(
        eventId: event.eventId,
        userId: 'user_neha_202',
        userName: 'Neha Member',
        status: RsvpStatus.going,
      );
      final rsvps = await eventRepo.watchEventRsvps(event.eventId).first;
      expect(rsvps.any((r) => r.userId == 'user_neha_202' && r.status == RsvpStatus.going), isTrue);

      // 6. Mark Attendance
      await eventRepo.markAttendance(
        eventId: event.eventId,
        userId: 'user_neha_202',
        userName: 'Neha Member',
        status: AttendanceStatus.present,
      );
      final att = await eventRepo.watchEventAttendance(event.eventId).first;
      expect(att.any((a) => a.userId == 'user_neha_202' && a.status == AttendanceStatus.present), isTrue);

      // 7. Start Game & Join Session
      final session = await gameRepo.createGameSession(
        eventId: event.eventId,
        groupId: group.groupId,
        gameName: 'Bollywood Quiz',
        type: GameType.bollywoodQuiz,
        hostUserId: user.uid,
      );
      await gameRepo.joinGameSession(session.gameId, user.uid, user.displayName);
      await gameRepo.joinGameSession(session.gameId, 'user_neha_202', 'Neha Member');

      // 8. Calculate Scores & Declare Winners
      final scores = {user.uid: 90, 'user_neha_202': 80};
      final participantMap = {
        user.uid: GameParticipantModel(userId: user.uid, gameId: session.gameId, displayName: user.displayName),
        'user_neha_202': GameParticipantModel(userId: 'user_neha_202', gameId: session.gameId, displayName: 'Neha Member'),
      };
      final winners = GameEngine.computeWinners(
        eventId: event.eventId,
        gameId: session.gameId,
        gameName: 'Bollywood Quiz',
        scores: scores,
        participantMap: participantMap,
      );
      await gameRepo.saveWinners(event.eventId, winners);
      final savedWinners = await gameRepo.watchEventWinners(event.eventId).first;
      expect(savedWinners.length, equals(2));
      expect(savedWinners.first.playerName, equals('Priya Organizer'));

      // 9. Record Expenses
      await expenseRepo.addExpense(
        ExpenseModel(
          expenseId: 'exp_1',
          eventId: event.eventId,
          category: 'Food',
          description: 'High tea sandwiches & tarts',
          amount: 3500,
          paidBy: user.displayName,
        ),
      );
      final expenses = await expenseRepo.watchEventExpenses(event.eventId).first;
      expect(expenses.length, equals(1));

      // 10. Upload Photos / Memories
      await memoryRepo.addMemory(
        MemoryModel(
          memoryId: 'mem_1',
          groupId: group.groupId,
          eventId: event.eventId,
          eventTitle: event.title,
          imageUrl: 'https://picsum.photos/600/600',
          caption: 'Great party!',
          uploadedByUserId: user.uid,
          uploadedByUserName: user.displayName,
        ),
      );
      final memories = await memoryRepo.watchGroupMemories(group.groupId).first;
      expect(memories.length, equals(1));

      // 11. Complete Event & Create Next Kitty
      await eventRepo.updateEventStatus(group.groupId, event.eventId, EventStatus.completed);
      final nextEvent = EventModel(
        eventId: 'event_dec_10',
        groupId: group.groupId,
        title: 'December Festive Kitty',
        date: DateTime(2026, 12, 10, 16, 0),
        startTime: '4:00 PM',
        endTime: '7:00 PM',
        hostId: 'user_neha_202',
        hostName: 'Neha Member',
        venue: 'Neha\'s Residence',
        createdBy: user.uid,
      );
      await eventRepo.createEvent(nextEvent);

      final allEvents = await eventRepo.watchGroupEvents(group.groupId).first;
      expect(allEvents.length, equals(2));
    });
  });
}
