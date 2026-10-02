import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../app/providers.dart';
import '../domain/group_model.dart';
import '../../members/presentation/members_screen.dart';
import '../../contributions/presentation/contribution_screen.dart';
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
            icon: const Icon(Icons.share, color: AppColors.primary),
            onPressed: () {
              final link = DeepLinkService.createGroupInviteLink(widget.groupId);
              WhatsAppService.shareKittyInvitation(
                groupName: groupAsync.value?.name ?? 'Sunshine Ladies',
                inviteLink: link,
                contributionAmount: '₹2,000 monthly',
              );
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
    final events = eventsAsync.value ?? [];
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
                  label: Text(nextEvent != null ? 'View Event Details' : 'Create Event'),
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
              onTap: () {
                final link = DeepLinkService.createGroupInviteLink(group.groupId);
                WhatsAppService.shareKittyInvitation(
                  groupName: group.name,
                  inviteLink: link,
                );
              },
            ),
            _ActionTile(
              icon: Icons.event,
              label: 'Create Event',
              onTap: () => context.push('/create-event'),
            ),
            _ActionTile(
              icon: Icons.sports_esports,
              label: 'Start Game',
              onTap: () => context.push('/games'),
            ),
            _ActionTile(
              icon: Icons.swap_horiz,
              label: 'Host Schedule',
              onTap: () => context.push('/host-schedule/${group.groupId}'),
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
              _StatItem(number: '12', label: 'Events'),
              _StatItem(number: '68', label: 'Games Played'),
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
            description: 'Schedule your first event for this group!',
            icon: Icons.event_note_outlined,
            actionText: 'Create Event',
            onAction: () => context.push('/create-event'),
          );
        }

        return ListView.builder(
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
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Contributions'),
              Tab(text: 'Expenses & Budget'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
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
