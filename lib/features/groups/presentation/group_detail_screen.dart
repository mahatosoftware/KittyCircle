import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../app/providers.dart';
import '../../members/presentation/members_screen.dart';
import '../../contributions/presentation/contribution_screen.dart';
import '../../expenses/presentation/expense_screen.dart';
import '../../memories/presentation/memories_gallery_screen.dart';

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
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(currentGroupProvider);

    return Scaffold(
      appBar: AppBar(
        title: groupAsync.when(
          data: (g) => Text(g?.name ?? 'Kitty Group'),
          loading: () => const Text('Loading...'),
          error: (_, _) => const Text('Kitty Group'),
        ),
        actions: [
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
            Tab(text: 'Memories'),
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
              MemoriesGalleryScreen(groupId: group.groupId),
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

    return SingleChildScrollView(
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
              const Text('18 October 2026', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('Hosted by Priya Sharma at Indiranagar', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(selectedEventIdProvider.notifier).state = 'event_oct_18';
                  context.push('/event/event_oct_18');
                },
                icon: const Icon(Icons.visibility),
                label: const Text('View Event Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
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

class _GroupGamesTab extends StatelessWidget {
  final String groupId;

  const _GroupGamesTab({required this.groupId});

  @override
  Widget build(BuildContext context) {
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
          AppCard(
            child: Column(
              children: const [
                ListTile(
                  leading: Text('🎬', style: TextStyle(fontSize: 28)),
                  title: Text('Bollywood Quiz'),
                  subtitle: Text('Winner: Priya Sharma (90 pts)'),
                  trailing: Text('18 Oct', style: TextStyle(color: AppColors.textMuted)),
                ),
                Divider(),
                ListTile(
                  leading: Text('🧠', style: TextStyle(fontSize: 28)),
                  title: Text('Memory Challenge'),
                  subtitle: Text('Winner: Neha Gupta (80 pts)'),
                  trailing: Text('18 Oct', style: TextStyle(color: AppColors.textMuted)),
                ),
                Divider(),
                ListTile(
                  leading: Text('🎁', style: TextStyle(fontSize: 28)),
                  title: Text('Lucky Draw'),
                  subtitle: Text('Winner: Kavita Verma'),
                  trailing: Text('18 Oct', style: TextStyle(color: AppColors.textMuted)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupMoneyTab extends StatelessWidget {
  final String groupId;

  const _GroupMoneyTab({required this.groupId});

  @override
  Widget build(BuildContext context) {
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
                const ExpenseScreen(eventId: 'event_oct_18'),
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
