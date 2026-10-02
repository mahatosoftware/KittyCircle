import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/domain/user_model.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/groups/data/group_repository.dart';
import '../features/groups/domain/group_model.dart';
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
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) => ExpenseRepository());
final memoryRepositoryProvider = Provider<MemoryRepository>((ref) => MemoryRepository());

// Current User State
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getCurrentUserProfile();
});

// Selected Group State
final selectedGroupIdProvider = StateProvider<String?>((ref) => 'group_sunshine_1');

// Watch User's Groups
final userGroupsProvider = StreamProvider<List<GroupModel>>((ref) {
  final groupRepo = ref.watch(groupRepositoryProvider);
  final userAsync = ref.watch(currentUserProvider);
  final userId = userAsync.value?.uid ?? 'user_priya_1';
  return groupRepo.watchUserGroups(userId);
});

// Watch Active Group Details
final currentGroupProvider = FutureProvider<GroupModel?>((ref) async {
  final groupId = ref.watch(selectedGroupIdProvider);
  if (groupId == null) return null;
  return ref.watch(groupRepositoryProvider).getGroupById(groupId);
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
final selectedEventIdProvider = StateProvider<String?>((ref) => 'event_oct_18');

// Watch Event Details
final currentEventProvider = FutureProvider<EventModel?>((ref) async {
  final groupId = ref.watch(selectedGroupIdProvider);
  final eventId = ref.watch(selectedEventIdProvider);
  if (groupId == null || eventId == null) return null;
  return ref.watch(eventRepositoryProvider).getEventById(groupId, eventId);
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
final groupContributionsProvider = StreamProvider.family<List<ContributionModel>, String>((ref, groupId) {
  return ref.watch(contributionRepositoryProvider).watchGroupContributions(groupId, 'October 2026');
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
