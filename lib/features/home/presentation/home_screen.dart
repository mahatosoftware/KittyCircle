import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../app/providers.dart';
import '../../groups/domain/group_model.dart';
import '../../events/domain/event_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final userGroupsAsync = ref.watch(userGroupsProvider);
    final selectedGroupId = ref.watch(selectedGroupIdProvider);

    final userName = userAsync.value?.displayName.isNotEmpty == true
        ? userAsync.value!.displayName
        : 'Kitty Member';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userGroupsProvider);
          },
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 950),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Greeting Header
                Row(
                  children: [
                    const AppLogo(size: 48, showShadow: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good day, $userName 👋',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            AppConstants.appTagline,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none_outlined, size: 28),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No new notifications')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // FEATURED CONTENT / UPCOMING KITTY CARD
                userGroupsAsync.when(
                  loading: () => const LoadingState(),
                  error: (e, s) => ErrorState(message: e.toString()),
                  data: (groups) {
                    if (groups.isEmpty) {
                      return _buildGettingStartedCard(context);
                    }

                    final activeGroup = groups.firstWhere(
                      (g) => g.groupId == selectedGroupId,
                      orElse: () => groups.first,
                    );

                    return _buildUpcomingKittySection(context, ref, activeGroup);
                  },
                ),
                const SizedBox(height: 28),

                // QUICK ACTIONS
                const Text(
                  'QUICK ACTIONS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _QuickActionButton(
                      icon: Icons.group_add_outlined,
                      label: 'Create Kitty',
                      color: const Color(0xFF8E24AA),
                      onTap: () => context.push('/create-group'),
                    ),
                    _QuickActionButton(
                      icon: Icons.event_available_outlined,
                      label: 'Create Events',
                      color: const Color(0xFFD81B60),
                      onTap: () {
                        final id = selectedGroupId ?? userGroupsAsync.value?.firstOrNull?.groupId;
                        context.push(id != null ? '/create-event?groupId=$id' : '/create-event');
                      },
                    ),
                    _QuickActionButton(
                      icon: Icons.sports_esports_outlined,
                      label: 'Start Game',
                      color: const Color(0xFFFF8F00),
                      onTap: () => context.push('/games'),
                    ),
                    _QuickActionButton(
                      icon: Icons.qr_code_scanner,
                      label: 'Join Kitty',
                      color: const Color(0xFF1E88E5),
                      onTap: () => context.push('/join-group?scan=true'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // MY KITTIES
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'MY KITTIES',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/kitties'),
                      child: const Text('View All', style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
                userGroupsAsync.when(
                  loading: () => const SizedBox(),
                  error: (e, s) => const SizedBox(),
                  data: (groups) {
                    if (groups.isEmpty) {
                      return EmptyState(
                        title: 'No Kitty Groups Yet',
                        description: 'Create your first kitty party group and invite your friends!',
                        icon: Icons.groups_outlined,
                        actionText: 'Create Kitty',
                        onAction: () => context.push('/create-group'),
                      );
                    }
                    return Column(
                      children: groups.map((g) {
                        final isSelected = g.groupId == (selectedGroupId ?? groups.first.groupId);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: AppCard(
                            backgroundColor: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                            onTap: () {
                              ref.read(selectedGroupIdProvider.notifier).state = g.groupId;
                              context.push('/group/${g.groupId}');
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                                  child: Text(
                                    g.name.isNotEmpty ? g.name.substring(0, 1) : '🌸',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        g.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${g.memberIds.length} members • ${g.currency}${g.contributionAmount.toInt()} ${g.frequency.toLowerCase()}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppColors.textMuted),
                              ],
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
      ),
    ),
  ),
);
}

  Widget _buildGettingStartedCard(BuildContext context) {
    return AppCard(
      gradient: AppColors.partyCardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars, color: AppColors.gold, size: 16),
                SizedBox(width: 4),
                Text(
                  'WELCOME TO KITTYCIRCLE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Organize Monthly Kitties ✨',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage contribution pools, host rotation schedules, themes, food planners and play multiplayer party games with your friends!',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: 'Create Kitty Group 🎉',
                  onPressed: () => context.push('/create-group'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingKittySection(BuildContext context, WidgetRef ref, GroupModel activeGroup) {
    final eventsAsync = ref.watch(groupEventsProvider(activeGroup.groupId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR NEXT KITTY',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        eventsAsync.when(
          loading: () => const LoadingState(),
          error: (e, s) => ErrorState(message: e.toString()),
          data: (events) {
            final upcomingEvent = events.where((e) => e.status == EventStatus.upcoming).firstOrNull;

            if (upcomingEvent == null) {
              return AppCard(
                gradient: AppColors.primaryGradient,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeGroup.name,
                      style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No Upcoming Events Scheduled',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Schedule the next kitty party gathering for your group!',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/create-event?groupId=${activeGroup.groupId}'),
                      icon: const Icon(Icons.event),
                      label: const Text('Schedule Event 🎉', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return AppCard(
              gradient: AppColors.partyCardGradient,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.celebration, color: AppColors.gold, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'UPCOMING',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        activeGroup.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    upcomingEvent.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: AppColors.gold, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('dd MMMM yyyy').format(upcomingEvent.date),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, color: AppColors.gold, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${upcomingEvent.startTime} – ${upcomingEvent.endTime}',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.gold, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          upcomingEvent.venue,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(selectedGroupIdProvider.notifier).state = activeGroup.groupId;
                            ref.read(selectedEventIdProvider.notifier).state = upcomingEvent.eventId;
                            context.push('/event/${upcomingEvent.eventId}');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('View Event', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            context.push('/games');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Party Games 🎮', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
