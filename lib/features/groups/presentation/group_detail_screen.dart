import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../app/providers.dart';
import '../domain/group_model.dart';
import 'widgets/group_invite_modal.dart';
import '../../members/presentation/members_screen.dart';
import '../../contributions/presentation/contribution_screen.dart';
import '../../contributions/presentation/widgets/circle_ledger_tab.dart';
import '../../expenses/presentation/expense_screen.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showEditGroupDialog(BuildContext context, WidgetRef ref, GroupModel group) {
    final nameCtrl = TextEditingController(text: group.name);
    final descCtrl = TextEditingController(text: group.description);
    final amountCtrl = TextEditingController(text: group.contributionAmount.toInt().toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Kitty Group'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Kitty Group Name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monthly Contribution'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              if (newName.isEmpty) return;
              final newDesc = descCtrl.text.trim();
              final newAmount = double.tryParse(amountCtrl.text.trim()) ?? group.contributionAmount;

              final updatedGroup = group.copyWith(
                name: newName,
                description: newDesc,
                contributionAmount: newAmount,
              );

              await ref.read(groupRepositoryProvider).updateGroup(updatedGroup);
              ref.invalidate(currentGroupProvider);
              ref.invalidate(userGroupsProvider);

              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kitty Group details updated successfully! 🎉')),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(currentGroupProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home_outlined, color: AppColors.primary),
          tooltip: 'Go to Home',
          onPressed: () => context.go('/home'),
        ),
        title: groupAsync.when(
          data: (g) => Text(g?.name ?? 'Kitty Group'),
          loading: () => const Text('Loading...'),
          error: (_, _) => const Text('Kitty Group'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            tooltip: 'Edit Kitty Details',
            onPressed: () {
              final group = groupAsync.value;
              if (group != null) {
                _showEditGroupDialog(context, ref, group);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.how_to_reg_outlined, color: AppColors.primary),
            tooltip: 'Host Selection & Rotation',
            onPressed: () {
              final group = groupAsync.value;
              if (group != null) {
                context.push('/host-selection/${group.groupId}');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
            tooltip: 'Invite Members & QR Code',
            onPressed: () {
              final group = groupAsync.value;
              if (group != null) {
                GroupInviteModal.show(context, group: group);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Members'),
            Tab(text: 'Events'),
            Tab(text: 'Games'),
            Tab(text: 'Money'),
          ],
        ),
      ),
      body: groupAsync.when(
        loading: () => const LoadingState(),
        error: (e, s) => ErrorState(message: e.toString()),
        data: (group) {
          if (group == null) {
            return const EmptyState(title: 'Group Not Found', description: 'This kitty group might have been removed.');
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _GroupOverviewTab(group: group),
              MembersScreen(groupId: group.groupId),
              _GroupEventsTab(groupId: group.groupId),
              _GroupGamesTab(groupId: group.groupId),
              _GroupMoneyTab(groupId: group.groupId),
            ],
          );
        },
      ),
    );
  }
}

class _GroupOverviewTab extends ConsumerWidget {
  final dynamic group;

  const _GroupOverviewTab({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(group.groupId));
    final eventsAsync = ref.watch(groupEventsProvider(group.groupId));
    final joinRequestsAsync = ref.watch(groupJoinRequestsProvider(group.groupId));
    final events = eventsAsync.value ?? [];
    final joinRequests = joinRequestsAsync.value ?? [];
    final nextEvent = events.where((e) => e.statusString == 'UPCOMING').firstOrNull ?? events.firstOrNull;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PENDING JOIN REQUESTS BANNER FOR HOST / ADMIN
          if (joinRequests.isNotEmpty) ...[
            AppCard(
              backgroundColor: Colors.amber.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${joinRequests.length} JOIN REQUEST${joinRequests.length > 1 ? "S" : ""} PENDING',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber, letterSpacing: 1.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...joinRequests.map((req) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                            child: Text(
                              req.userName.isNotEmpty ? req.userName.substring(0, 1) : '👤',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req.userName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const Text(
                                  'Requested to join',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await ref.read(groupRepositoryProvider).acceptJoinRequest(group.groupId, req.userId, req.userName);
                              ref.invalidate(groupMembersProvider(group.groupId));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${req.userName} added to ${group.name}! 🎉'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () async {
                              await ref.read(groupRepositoryProvider).rejectJoinRequest(group.groupId, req.userId);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // HOST SELECTION BANNER
          AppCard(
            backgroundColor: AppColors.gold.withValues(alpha: 0.12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    const Text(
                      'HOST SELECTION',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1),
                    ),
                    const Spacer(),
                    if (group.currentHostName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '👑 Host: ${group.currentHostName}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  group.hostSelectionMode == 'random'
                      ? '🎲 Host Picked Randomly'
                      : group.hostSelectionMode == 'volunteer'
                          ? '👑 Host Selection: Volunteer Mode'
                          : group.hostSelectionMode == 'rotation'
                              ? '🔄 Host Selection: Rotation Schedule'
                              : '🎉 Who should host the first Kitty?',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  group.currentHostName != null
                      ? 'First Kitty Host: ${group.currentHostName}'
                      : 'Organizer options: Pick randomly 🎲, Volunteer 👑, or Rotation 🔄.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.push('/host-selection/${group.groupId}'),
                      icon: const Text('🎉', style: TextStyle(fontSize: 14)),
                      label: Text(group.currentHostName == null ? 'Set Up Host Selection' : 'Change Host Selection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/host-schedule/${group.groupId}'),
                      icon: const Icon(Icons.calendar_month, size: 14),
                      label: const Text('View Rotation Schedule'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // NEXT KITTY BANNER
          AppCard(
            gradient: AppColors.primaryGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_month, color: AppColors.gold, size: 20),
                    SizedBox(width: 8),
                    Text('NEXT KITTY', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  nextEvent != null ? nextEvent.dateString : 'No Upcoming Kitty',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  nextEvent != null ? 'Hosted by ${nextEvent.hostName} at ${nextEvent.venue}' : 'Schedule your next kitty gathering!',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    if (nextEvent != null) {
                      ref.read(selectedEventIdProvider.notifier).state = nextEvent.eventId;
                      context.push('/event/${nextEvent.eventId}');
                    } else {
                      context.push('/create-event');
                    }
                  },
                  icon: Icon(nextEvent != null ? Icons.visibility : Icons.add),
                  label: Text(nextEvent != null ? 'View Event Details' : 'Create Events'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // UPCOMING CELEBRATIONS CARD
          membersAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (err, stack) => const SizedBox.shrink(),
            data: (members) {
              final celebrationMembers = members.where((m) => m.birthdayString != null || m.anniversaryString != null).toList();
              if (celebrationMembers.isEmpty) return const SizedBox.shrink();

              return AppCard(
                backgroundColor: AppColors.gold.withValues(alpha: 0.12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('🎉', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Text(
                          'MEMBER CELEBRATIONS',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.goldDark, letterSpacing: 1.1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...celebrationMembers.map((m) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Text(m.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const Spacer(),
                            if (m.birthdayString != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('🎂 ${m.birthdayString}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (m.anniversaryString != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('💍 ${m.anniversaryString}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

        // QUICK ACTIONS
        const Text('QUICK ACTIONS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ActionTile(
              icon: Icons.person_add_alt,
              label: 'Invite Member',
              onTap: () => GroupInviteModal.show(context, group: group),
            ),
            _ActionTile(
              icon: Icons.confirmation_number_outlined,
              label: 'Invitations',
              onTap: () => context.push('/group/${group.groupId}/invitations'),
            ),
            _ActionTile(
              icon: Icons.event,
              label: 'Create Events',
              onTap: () => context.push('/create-event?groupId=${group.groupId}'),
            ),
            _ActionTile(
              icon: Icons.sports_esports,
              label: 'Start Game',
              onTap: () => context.push('/games'),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // STATS CARD
        AppCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(number: '${group.memberIds.length}', label: 'Members'),
              _StatItem(number: '${events.length}', label: 'Events'),
              _StatItem(
                number: '${events.where((e) => e.statusString == 'COMPLETED').length}',
                label: 'Games Played',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // MEMBERS SUMMARY ROSTER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('MEMBERS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2)),
            TextButton(
              onPressed: () {},
              child: Text('${group.memberIds.length} Total'),
            ),
          ],
        ),
        membersAsync.when(
          loading: () => const LoadingState(),
          error: (e, s) => ErrorState(message: e.toString()),
          data: (members) {
            return Column(
              children: members.take(5).map((m) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: MemberAvatar(name: m.displayName, role: m.roleString),
                  title: Text(m.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(m.phoneNumber ?? 'Active Member'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: m.roleString == 'Owner'
                          ? AppColors.gold.withValues(alpha: 0.2)
                          : (m.roleString == 'Admin' ? AppColors.secondary.withValues(alpha: 0.15) : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      m.roleString,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: m.roleString == 'Owner'
                            ? AppColors.goldDark
                            : (m.roleString == 'Admin' ? AppColors.secondary : AppColors.textSecondary),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    ),
  ),
),
);
}
}

class _GroupEventsTab extends ConsumerWidget {
  final String groupId;

  const _GroupEventsTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(groupEventsProvider(groupId));

    return eventsAsync.when(
      loading: () => const LoadingState(),
      error: (e, s) => ErrorState(message: e.toString()),
      data: (events) {
        if (events.isEmpty) {
          return EmptyState(
            title: 'No Kitty Events',
            description: 'Schedule Kitty events for all your group members!',
            icon: Icons.event_note_outlined,
            actionText: 'Create Events 🎉',
            onAction: () => context.push('/create-event?groupId=$groupId'),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${events.length} Kitty Event${events.length > 1 ? "s" : ""}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/create-event?groupId=$groupId'),
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('Create Events'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: events.length,
                itemBuilder: (context, index) {
            final ev = events[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AppCard(
                onTap: () {
                  ref.read(selectedEventIdProvider.notifier).state = ev.eventId;
                  context.push('/event/${ev.eventId}');
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ev.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ev.statusString == 'UPCOMING'
                                ? AppColors.primaryLight.withValues(alpha: 0.2)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            ev.statusString,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: ev.statusString == 'UPCOMING' ? AppColors.primary : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('👑 Host: ${ev.hostName} • 📍 ${ev.venue}', style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('🎭 Theme: ${ev.theme}', style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
},
);
  }
}

class _GroupGamesTab extends ConsumerWidget {
  final String groupId;

  const _GroupGamesTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(groupEventsProvider(groupId));
    final activeEventId = eventsAsync.value?.firstOrNull?.eventId;
    final winners = activeEventId != null ? (ref.watch(eventWinnersProvider(activeEventId)).value ?? []) : [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PrimaryButton(
            text: 'Explore Party Games Library 🎮',
            onPressed: () => context.push('/games'),
          ),
          const SizedBox(height: 20),
          const Text('GAMES PLAYED THIS SEASON', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          if (winners.isEmpty)
            const AppCard(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text('No games played yet this season. Launch a party game!', style: TextStyle(color: AppColors.textMuted)),
                ),
              ),
            )
          else
            AppCard(
              child: Column(
                children: winners.map((w) {
                  return ListTile(
                    leading: const Text('🏆', style: TextStyle(fontSize: 28)),
                    title: Text(w.prizeTitle),
                    subtitle: Text('Winner: ${w.winnerName} (${w.rank})'),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupMoneyTab extends ConsumerWidget {
  final String groupId;

  const _GroupMoneyTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(groupEventsProvider(groupId));
    final activeEventId = eventsAsync.value?.firstOrNull?.eventId ?? ref.watch(selectedEventIdProvider) ?? '';

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Circle Ledger 📖'),
              Tab(text: 'Monthly Contributions 💵'),
              Tab(text: 'Expenses & Budget 📊'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                CircleLedgerTab(groupId: groupId),
                ContributionScreen(groupId: groupId),
                ExpenseScreen(eventId: activeEventId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String number;
  final String label;

  const _StatItem({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(number, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
