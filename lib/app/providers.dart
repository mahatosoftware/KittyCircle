import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/domain/user_model.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/groups/data/group_repository.dart';
import '../features/groups/domain/group_model.dart';
import '../features/groups/domain/join_request_model.dart';
import '../features/groups/domain/group_invite_model.dart';
import '../features/members/data/member_repository.dart';
import '../features/members/domain/member_model.dart';
import '../features/events/data/event_repository.dart';
import '../features/events/domain/event_model.dart';
import '../features/events/domain/rsvp_model.dart';
import '../features/events/domain/attendance_model.dart';
import '../features/events/domain/host_schedule_model.dart';
import '../features/games/data/game_repository.dart';
import '../features/games/domain/game_models.dart';
import '../features/contributions/data/contribution_repository.dart';
import '../features/contributions/domain/contribution_model.dart';
import '../features/contributions/data/ledger_repository.dart';
import '../features/contributions/domain/kitty_transaction_model.dart';
import '../features/expenses/data/expense_repository.dart';
import '../features/expenses/domain/expense_model.dart';
import '../features/memories/data/memory_repository.dart';
import '../features/memories/domain/memory_model.dart';

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());
final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ProfileRepository());
final groupRepositoryProvider = Provider<GroupRepository>((ref) => GroupRepository());
final memberRepositoryProvider = Provider<MemberRepository>((ref) => MemberRepository());
final eventRepositoryProvider = Provider<EventRepository>((ref) => EventRepository());
final gameRepositoryProvider = Provider<GameRepository>((ref) => GameRepository());
final contributionRepositoryProvider = Provider<ContributionRepository>((ref) => ContributionRepository());
final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) => LedgerRepository());
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) => ExpenseRepository());
final memoryRepositoryProvider = Provider<MemoryRepository>((ref) => MemoryRepository());

// Current User State
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getCurrentUserProfile();
});

// Selected Group State
final selectedGroupIdProvider = StateProvider<String?>((ref) => null);

// Watch User's Groups
final userGroupsProvider = StreamProvider<List<GroupModel>>((ref) {
  final groupRepo = ref.watch(groupRepositoryProvider);
  final userAsync = ref.watch(currentUserProvider);
  final userId = userAsync.value?.uid ?? '';
  if (userId.isEmpty) return Stream.value(<GroupModel>[]);
  return groupRepo.watchUserGroups(userId);
});

// Watch Active Group Details in Real-Time
final currentGroupProvider = StreamProvider<GroupModel?>((ref) async* {
  final userGroupsAsync = ref.watch(userGroupsProvider);
  final groups = userGroupsAsync.value ?? [];
  final selectedId = ref.watch(selectedGroupIdProvider);
  if (selectedId == null) {
    yield groups.isNotEmpty ? groups.first : null;
    return;
  }
  final found = groups.where((g) => g.groupId == selectedId).firstOrNull;
  if (found != null) {
    yield found;
  } else {
    final groupRepo = ref.watch(groupRepositoryProvider);
    final group = await groupRepo.getGroupById(selectedId);
    yield group ?? (groups.isNotEmpty ? groups.first : null);
  }
});

// Watch Group Members
final groupMembersProvider = StreamProvider.family<List<MemberModel>, String>((ref, groupId) {
  return ref.watch(memberRepositoryProvider).watchGroupMembers(groupId);
});

// Watch Group Events
final groupEventsProvider = StreamProvider.family<List<EventModel>, String>((ref, groupId) {
  return ref.watch(eventRepositoryProvider).watchGroupEvents(groupId);
});

// Selected Event State
final selectedEventIdProvider = StateProvider<String?>((ref) => null);

// Watch Event Details by Event ID
final eventDetailProvider = StreamProvider.family<EventModel?, String>((ref, eventId) async* {
  if (eventId.isEmpty) {
    yield null;
    return;
  }

  final selectedGroupId = ref.watch(selectedGroupIdProvider);
  if (selectedGroupId != null && selectedGroupId.isNotEmpty) {
    final events = ref.watch(groupEventsProvider(selectedGroupId)).value ?? [];
    final found = events.where((e) => e.eventId == eventId).firstOrNull;
    if (found != null) {
      yield found;
      return;
    }
  }

  final userGroups = ref.watch(userGroupsProvider).value ?? [];
  for (final group in userGroups) {
    final events = ref.watch(groupEventsProvider(group.groupId)).value ?? [];
    final found = events.where((e) => e.eventId == eventId).firstOrNull;
    if (found != null) {
      yield found;
      return;
    }
  }

  final eventRepo = ref.watch(eventRepositoryProvider);
  final event = await eventRepo.getEventById('', eventId);
  yield event;
});

// Watch Current Active Event Details in Real-Time
final currentEventProvider = StreamProvider<EventModel?>((ref) async* {
  final eventId = ref.watch(selectedEventIdProvider);
  if (eventId == null || eventId.isEmpty) {
    yield null;
    return;
  }
  final asyncVal = ref.watch(eventDetailProvider(eventId));
  yield asyncVal.value;
});

// Watch Event RSVPs
final eventRsvpsProvider = StreamProvider.family<List<RsvpModel>, String>((ref, eventId) {
  return ref.watch(eventRepositoryProvider).watchEventRsvps(eventId);
});

// Watch Event Attendance
final eventAttendanceProvider = StreamProvider.family<List<AttendanceModel>, String>((ref, eventId) {
  return ref.watch(eventRepositoryProvider).watchEventAttendance(eventId);
});

// Watch Host Schedule
final hostScheduleProvider = StreamProvider.family<List<HostScheduleModel>, String>((ref, groupId) {
  return ref.watch(eventRepositoryProvider).watchHostSchedule(groupId);
});

// Watch Timeline
final eventTimelineProvider = StreamProvider.family<List<TimelineItemModel>, String>((ref, eventId) {
  return ref.watch(eventRepositoryProvider).watchTimeline(eventId);
});

// Watch Potluck / Food Planner
final eventFoodPlannerProvider = StreamProvider.family<List<FoodItemModel>, String>((ref, eventId) {
  return ref.watch(eventRepositoryProvider).watchFoodPlanner(eventId);
});

// Watch Contributions
final groupContributionsProvider = StreamProvider.family<List<ContributionModel>, String>((ref, groupId) async* {
  final members = ref.watch(groupMembersProvider(groupId)).value ?? [];
  final contribRepo = ref.watch(contributionRepositoryProvider);

  await for (final storeList in contribRepo.watchGroupContributions(groupId, 'October 2026')) {
    if (members.isEmpty) {
      yield storeList;
      continue;
    }

    final Map<String, ContributionModel> existingMap = {
      for (var c in storeList) c.userId: c
    };

    final List<ContributionModel> merged = members.map((m) {
      if (existingMap.containsKey(m.userId)) {
        return existingMap[m.userId]!;
      }
      return ContributionModel(
        contributionId: 'contrib_${groupId}_${m.userId}',
        groupId: groupId,
        userId: m.userId,
        userName: m.displayName,
        monthYear: 'October 2026',
        amountExpected: 2000.0,
        amountPaid: 0.0,
        status: ContributionStatus.pending,
      );
    }).toList();

    yield merged;
  }
});

// Watch Event Expenses
final eventExpensesProvider = StreamProvider.family<List<ExpenseModel>, String>((ref, eventId) {
  return ref.watch(expenseRepositoryProvider).watchEventExpenses(eventId);
});

// Watch Event Budget
final eventBudgetProvider = StreamProvider.family<BudgetModel?, String>((ref, eventId) {
  return ref.watch(expenseRepositoryProvider).watchEventBudget(eventId);
});

// Watch Group Memories
final groupMemoriesProvider = StreamProvider.family<List<MemoryModel>, String>((ref, groupId) {
  return ref.watch(memoryRepositoryProvider).watchGroupMemories(groupId);
});

// Watch Event Winners
final eventWinnersProvider = StreamProvider.family<List<WinnerModel>, String>((ref, eventId) {
  return ref.watch(gameRepositoryProvider).watchEventWinners(eventId);
});

// Watch Event Prizes
final eventPrizesProvider = StreamProvider.family<List<PrizeModel>, String>((ref, eventId) {
  return ref.watch(gameRepositoryProvider).watchEventPrizes(eventId);
});

// Watch Group Pending Join Requests
final groupJoinRequestsProvider = StreamProvider.family<List<JoinRequestModel>, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).watchGroupJoinRequests(groupId);
});

// Watch Group One-Time Invitations
final groupInvitesProvider = StreamProvider.family<List<GroupInviteModel>, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).watchGroupInvites(groupId);
});

// Watch Event Ledger Transactions
final eventTransactionsProvider = StreamProvider.family<List<KittyTransactionModel>, ({String groupId, String eventId})>((ref, args) {
  return ref.watch(ledgerRepositoryProvider).watchEventTransactions(args.groupId, args.eventId);
});

// Watch Group Circle-Level Ledger Transactions
final groupTransactionsProvider = StreamProvider.family<List<KittyTransactionModel>, String>((ref, groupId) {
  return ref.watch(ledgerRepositoryProvider).watchGroupTransactions(groupId);
});

// Watch Member Financial Transactions
final memberTransactionsProvider = StreamProvider.family<List<KittyTransactionModel>, ({String groupId, String userId})>((ref, args) {
  return ref.watch(ledgerRepositoryProvider).watchMemberTransactions(args.groupId, args.userId);
});


