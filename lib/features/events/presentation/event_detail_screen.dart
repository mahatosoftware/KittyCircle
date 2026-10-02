import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../app/providers.dart';
import '../domain/rsvp_model.dart';
import '../domain/attendance_model.dart';
import '../domain/event_model.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  void _showAttendanceModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return _AttendanceModalContent(eventId: eventId);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(currentEventProvider);
    final rsvpsAsync = ref.watch(eventRsvpsProvider(eventId));
    final timelineAsync = ref.watch(eventTimelineProvider(eventId));
    final foodAsync = ref.watch(eventFoodPlannerProvider(eventId));
    final winnersAsync = ref.watch(eventWinnersProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.primary),
            onPressed: () {
              final ev = eventAsync.value;
              if (ev != null) {
                final link = DeepLinkService.createEventLink(eventId);
                WhatsAppService.shareEventInvitation(
                  eventTitle: ev.title,
                  groupName: 'Sunshine Ladies',
                  date: DateFormat('dd MMMM yyyy').format(ev.date),
                  time: ev.startTime,
                  hostName: ev.hostName,
                  venue: ev.venue,
                  theme: ev.theme,
                  eventLink: link,
                );
              }
            },
          ),
        ],
      ),
      body: eventAsync.when(
        loading: () => const LoadingState(),
        error: (e, s) => ErrorState(message: e.toString()),
        data: (event) {
          if (event == null) return const EmptyState(title: 'Event Not Found', description: 'Event might be deleted.');

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 20 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // EVENT HERO BANNER
                AppCard(
                  gradient: AppColors.partyCardGradient,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '🎭 Theme: ${event.theme}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            event.statusString,
                            style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        event.title,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_month, color: AppColors.gold, size: 18),
                                const SizedBox(width: 6),
                                Text(DateFormat('dd MMMM yyyy').format(event.date), style: const TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.access_time, color: AppColors.gold, size: 18),
                                const SizedBox(width: 6),
                                Text('${event.startTime} - ${event.endTime}', style: const TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.place, color: AppColors.gold, size: 18),
                          const SizedBox(width: 6),
                          Expanded(child: Text(event.venueAddress.isNotEmpty ? event.venueAddress : event.venue, style: const TextStyle(color: Colors.white))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const CircleAvatar(radius: 12, backgroundColor: Colors.white24, child: Text('👑', style: TextStyle(fontSize: 12))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Host: ${event.hostName}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // RSVP SECTION
                const Text('YOUR RSVP', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2)),
                const SizedBox(height: 10),
                _RsvpSelectorWidget(eventId: eventId),
                const SizedBox(height: 12),

                rsvpsAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, _) => const SizedBox(),
                  data: (rsvps) {
                    final going = rsvps.where((r) => r.status == RsvpStatus.going).length;
                    final maybe = rsvps.where((r) => r.status == RsvpStatus.maybe).length;
                    final notGoing = rsvps.where((r) => r.status == RsvpStatus.notGoing).length;

                    return AppCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _RsvpCountItem(count: '$going', label: 'Going', color: AppColors.success),
                          _RsvpCountItem(count: '$maybe', label: 'Maybe', color: AppColors.warning),
                          _RsvpCountItem(count: '$notGoing', label: 'Not Going', color: AppColors.error),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ORGANIZER ACTIONS & ATTENDANCE
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        text: 'Mark Attendance 📋',
                        onPressed: () => _showAttendanceModal(context, ref),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        text: 'Start Games 🎮',
                        onPressed: () => context.push('/games'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // WINNERS & PRIZES SUMMARY (if available)
                winnersAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, _) => const SizedBox(),
                  data: (winners) {
                    if (winners.isEmpty) return const SizedBox();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PARTY WINNERS 🏆', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2)),
                        const SizedBox(height: 10),
                        AppCard(
                          child: Column(
                            children: winners.map((w) {
                              return ListTile(
                                leading: Text(w.rankEmoji, style: const TextStyle(fontSize: 28)),
                                title: Text(
                                  w.playerName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                subtitle: Text(
                                  '${w.gameName} • ${w.prizeName} (${w.score} pts)',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),

                // PARTY TIMELINE
                const Text('PARTY SCHEDULE & TIMELINE ⏰', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2)),
                const SizedBox(height: 10),
                timelineAsync.when(
                  loading: () => const LoadingState(),
                  error: (_, _) => const SizedBox(),
                  data: (items) {
                    return AppCard(
                      child: Column(
                        children: items.map((item) {
                          return ListTile(
                            leading: Icon(
                              item.isCompleted
                                  ? Icons.check_circle
                                  : (item.isCurrent ? Icons.play_circle_fill : Icons.radio_button_unchecked),
                              color: item.isCompleted
                                  ? AppColors.success
                                  : (item.isCurrent ? AppColors.primary : AppColors.textMuted),
                            ),
                            title: Text(
                              item.title,
                              style: TextStyle(fontWeight: item.isCurrent ? FontWeight.bold : FontWeight.normal),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            trailing: Text(
                              item.timeString,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // POTLUCK FOOD PLANNER
                const Text('FOOD & POTLUCK PLANNER 🍰', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2)),
                const SizedBox(height: 10),
                foodAsync.when(
                  loading: () => const LoadingState(),
                  error: (_, _) => const SizedBox(),
                  data: (items) {
                    return AppCard(
                      child: Column(
                        children: items.map((f) {
                          return ListTile(
                            leading: const Icon(Icons.fastfood, color: AppColors.secondary),
                            title: Text(
                              f.itemName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            subtitle: Text(
                              'Category: ${f.category}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            trailing: Container(
                              constraints: const BoxConstraints(maxWidth: 120),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                f.assignedUserName ?? 'Unassigned',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // COMPLETE EVENT & PREPARE NEXT KITTY
                PrimaryButton(
                  text: 'Complete Party & Plan Next Kitty 🎉',
                  onPressed: () {
                    ref.read(eventRepositoryProvider).updateEventStatus(event.groupId, eventId, EventStatus.completed);
                    context.push('/create-next-kitty/${event.groupId}');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RsvpSelectorWidget extends ConsumerWidget {
  final String eventId;

  const _RsvpSelectorWidget({required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final rsvps = ref.watch(eventRsvpsProvider(eventId)).value ?? [];
    final currentRsvp = rsvps.firstWhere((r) => r.userId == (user?.uid ?? 'user_priya_1'),
        orElse: () => RsvpModel(userId: user?.uid ?? 'user_priya_1', eventId: eventId, userName: user?.displayName ?? 'Priya', status: RsvpStatus.going));

    return Row(
      children: [
        _RsvpChip(
          label: 'Going 👍',
          isSelected: currentRsvp.status == RsvpStatus.going,
          color: AppColors.success,
          onTap: () {
            ref.read(eventRepositoryProvider).setRsvp(
                  eventId: eventId,
                  userId: user?.uid ?? 'user_priya_1',
                  userName: user?.displayName ?? 'Priya',
                  status: RsvpStatus.going,
                );
          },
        ),
        const SizedBox(width: 8),
        _RsvpChip(
          label: 'Maybe 🤔',
          isSelected: currentRsvp.status == RsvpStatus.maybe,
          color: AppColors.warning,
          onTap: () {
            ref.read(eventRepositoryProvider).setRsvp(
                  eventId: eventId,
                  userId: user?.uid ?? 'user_priya_1',
                  userName: user?.displayName ?? 'Priya',
                  status: RsvpStatus.maybe,
                );
          },
        ),
        const SizedBox(width: 8),
        _RsvpChip(
          label: 'Not Going 👎',
          isSelected: currentRsvp.status == RsvpStatus.notGoing,
          color: AppColors.error,
          onTap: () {
            ref.read(eventRepositoryProvider).setRsvp(
                  eventId: eventId,
                  userId: user?.uid ?? 'user_priya_1',
                  userName: user?.displayName ?? 'Priya',
                  status: RsvpStatus.notGoing,
                );
          },
        ),
      ],
    );
  }
}

class _RsvpChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _RsvpChip({required this.label, required this.isSelected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RsvpCountItem extends StatelessWidget {
  final String count;
  final String label;
  final Color color;

  const _RsvpCountItem({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _AttendanceModalContent extends ConsumerWidget {
  final String eventId;

  const _AttendanceModalContent({required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupId = ref.watch(selectedGroupIdProvider) ?? 'group_sunshine_1';
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final attList = ref.watch(eventAttendanceProvider(eventId)).value ?? [];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mark Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          membersAsync.when(
            loading: () => const LoadingState(),
            error: (e, s) => Text(e.toString()),
            data: (members) {
              return SizedBox(
                height: 350,
                child: ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (ctx, idx) {
                    final m = members[idx];
                    final currentAtt = attList.firstWhere((a) => a.userId == m.userId,
                        orElse: () => AttendanceModel(userId: m.userId, eventId: eventId, userName: m.displayName, status: AttendanceStatus.present));

                    return ListTile(
                      leading: MemberAvatar(name: m.displayName),
                      title: Text(
                        m.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      trailing: SegmentedButton<AttendanceStatus>(
                        segments: const [
                          ButtonSegment(value: AttendanceStatus.present, label: Text('P')),
                          ButtonSegment(value: AttendanceStatus.late, label: Text('L')),
                          ButtonSegment(value: AttendanceStatus.absent, label: Text('A')),
                        ],
                        selected: {currentAtt.status},
                        onSelectionChanged: (val) {
                          ref.read(eventRepositoryProvider).markAttendance(
                                eventId: eventId,
                                userId: m.userId,
                                userName: m.displayName,
                                status: val.first,
                              );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            text: 'Save Attendance',
            useNavigationPadding: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
