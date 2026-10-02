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
import '../domain/host_schedule_model.dart';

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

  void _showAddTimelineDialog(BuildContext context, WidgetRef ref, String eventId) {
    final titleCtrl = TextEditingController();

    const Map<String, List<String>> activityCategories = {
      '🍹 Food & Social': [
        'Welcome Drinks',
        'High Tea',
        'Snacks & Chit-Chat',
        'Tea/Coffee Break',
        'Mocktail Session',
        'Lunch',
        'Buffet Dinner',
        'Potluck',
        'Dessert Time',
        'Open Social Time',
      ],
      '🎲 Icebreakers & Party Games': [
        'Icebreaker Game',
        'Two Truths & a Lie',
        'Never Have I Ever',
        'Would You Rather?',
        'Most Likely To',
        'What\'s in My Bag?',
        'Rapid Fire',
        'Guess the Member',
        'Pass the Parcel',
        'Musical Chairs',
        'Don\'t Say Yes or No',
        'Memory Challenge',
        '60-Second Challenge',
        'Minute-to-Win-It',
        'Spin the Wheel',
      ],
      '🎟️ Tambola / Housie': [
        'Tambola / Housie',
        'Tambola Round 1',
        'Tambola Round 2',
        'Theme Tambola',
        'Quick Tambola',
        'Full House Special',
        'Tambola Finale',
      ],
      '🎵 Music & Dance': [
        'Antakshari',
        'Karaoke',
        'Guess the Song',
        'Finish the Lyrics',
        'Musical Bingo',
        'Dance Challenge',
        'Dance Freeze',
        'Group Dance',
        'DJ & Dance Floor',
        'Singing Competition',
      ],
      '🎬 Bollywood & Movie Games': [
        'Dumb Charades',
        'Guess the Movie',
        'Guess the Celebrity',
        'Guess the Dialogue',
        'Bollywood Quiz',
        'Emoji Movie Challenge',
        'Movie Dialogue Challenge',
        'Guess the Actor/Actress',
        'Movie Scene Recreation',
      ],
      '🧠 Quiz & Trivia': [
        'General Knowledge Quiz',
        'Bollywood Quiz',
        'Music Quiz',
        'Food Quiz',
        'Travel Quiz',
        'Festival Quiz',
        'Team Quiz',
        'Picture Quiz',
        'Trivia Challenge',
        'Rapid-Fire Quiz',
      ],
      '🎨 Creative Activities': [
        'Painting',
        'Paint & Sip',
        'Rangoli Competition',
        'Mehndi Competition',
        'Flower Arrangement',
        'DIY Craft',
        'Cupcake Decoration',
        'Mocktail Making',
        'Best Plating',
        'Gift-Wrapping Challenge',
      ],
      '👑 Fashion & Fun Awards': [
        'Best Dressed',
        'Best Theme Outfit',
        'Kitty Queen',
        'Best Smile',
        'Best Hairstyle',
        'Best Accessories',
        'Ramp Walk',
        'Fashion Show',
        'Fun Awards',
        'Member of the Month',
      ],
      '🎁 Gifts, Draws & Prizes': [
        'Lucky Draw',
        'Secret Santa',
        'Gift Exchange',
        'Surprise Gift',
        'Mystery Gift',
        'Prize Distribution',
        'Tambola Prize Distribution',
        'Game Prize Distribution',
      ],
      '🎂 Celebrations': [
        'Cake Cutting',
        'Birthday Celebration',
        'Anniversary Celebration',
        'Member Celebration',
        'Festival Celebration',
        'Group Anniversary',
      ],
      '📸 Photos & Memories': [
        'Group Photo',
        'Photo Session',
        'Selfie Challenge',
        'Photo Booth',
        'Best Photo Contest',
        'Recreate an Old Photo',
        'Memory Sharing',
        'Video/Memory Time',
      ],
      '🎬 Reels & Shorts': [
        'Make a Group Reel',
        'Dance Reel Challenge',
        'Trending Song Reel',
        'Best Friends Reel',
        'Funny Reel Challenge',
        'Acting/Dialogue Reel',
        'Lip-Sync Challenge',
        'Outfit Transition Reel',
        'Before → After Transition',
        'Dance Freeze Reel',
        'Antakshari Reel',
        'Movie Scene Recreation',
        'Get Ready With Us',
        'Kitty Party Vlog',
        'Photo-to-Reel',
        'Best Reel Competition',
        'Group Choreography',
        'Expectation vs Reality',
        'Kitty Queen Reel',
        'Party Highlights Reel',
      ],
    };

    String selectedCategory = '🍹 Food & Social';
    String? selectedItem = 'Welcome Drinks';
    titleCtrl.text = 'Welcome Drinks';

    int hour = 4;
    int minute = 0;
    String period = 'PM';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final isCustomCategory = selectedCategory == '✍️ Custom Activity';
          final currentItems = activityCategories[selectedCategory] ?? [];

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Add Schedule Activity ⏰', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.1)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: [
                        ...activityCategories.keys.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, overflow: TextOverflow.ellipsis))),
                        const DropdownMenuItem(value: '✍️ Custom Activity', child: Text('✍️ Custom Activity')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedCategory = val;
                            if (val == '✍️ Custom Activity') {
                              selectedItem = null;
                              titleCtrl.clear();
                            } else {
                              final items = activityCategories[val] ?? [];
                              selectedItem = items.isNotEmpty ? items.first : null;
                              titleCtrl.text = selectedItem ?? '';
                            }
                          });
                        }
                      },
                    ),
                    if (!isCustomCategory && currentItems.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('PREDEFINED SUGGESTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.1)),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: currentItems.map((item) {
                              final isSel = selectedItem == item;
                              return ChoiceChip(
                                label: Text(
                                  item,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    color: isSel ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                                selected: isSel,
                                selectedColor: AppColors.primary,
                                backgroundColor: Colors.grey.shade100,
                                showCheckmark: false,
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() {
                                      selectedItem = item;
                                      titleCtrl.text = item;
                                    });
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Activity Name',
                        hintText: isCustomCategory ? 'Type your custom activity name...' : 'Selected or custom activity title',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        if (selectedItem != null && val != selectedItem) {
                          setState(() {
                            selectedItem = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('SCHEDULED TIME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.1)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // HOUR BOX
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 26),
                              tooltip: 'Increase Hour',
                              onPressed: () => setState(() => hour = (hour % 12) + 1),
                            ),
                            Container(
                              width: 54,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                hour.toString().padLeft(2, '0'),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary, size: 26),
                              tooltip: 'Decrease Hour',
                              onPressed: () => setState(() => hour = hour == 1 ? 12 : hour - 1),
                            ),
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        ),

                        // MINUTE BOX
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 26),
                              tooltip: 'Increase Minute',
                              onPressed: () => setState(() => minute = (minute + 5) % 60),
                            ),
                            Container(
                              width: 54,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                minute.toString().padLeft(2, '0'),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary, size: 26),
                              tooltip: 'Decrease Minute',
                              onPressed: () => setState(() => minute = (minute - 5 + 60) % 60),
                            ),
                          ],
                        ),

                        const SizedBox(width: 16),

                        // AM / PM TOGGLE
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => setState(() => period = 'AM'),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 48,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: period == 'AM' ? AppColors.primary : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'AM',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: period == 'AM' ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => setState(() => period = 'PM'),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 48,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: period == 'PM' ? AppColors.primary : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'PM',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: period == 'PM' ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final formattedTime = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
                  if (title.isNotEmpty) {
                    final item = TimelineItemModel(
                      itemId: 'item_${DateTime.now().millisecondsSinceEpoch}',
                      eventId: eventId,
                      timeString: formattedTime,
                      title: title,
                      order: DateTime.now().millisecondsSinceEpoch,
                    );
                    await ref.read(eventRepositoryProvider).updateTimelineItem(eventId, item);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('Add Activity'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddFoodDialog(BuildContext context, WidgetRef ref, String eventId, String groupId) {
    final nameCtrl = TextEditingController();
    String category = 'Starters';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Potluck Dish 🍰'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dish / Item Name',
                    hintText: 'e.g. Paneer Tikka / Mocktails',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'Starters', child: Text('Starters 🍢')),
                    DropdownMenuItem(value: 'Main Course', child: Text('Main Course 🍲')),
                    DropdownMenuItem(value: 'Dessert', child: Text('Dessert 🍦')),
                    DropdownMenuItem(value: 'Drinks', child: Text('Drinks 🍹')),
                    DropdownMenuItem(value: 'Snacks', child: Text('Snacks 🥨')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => category = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final itemName = nameCtrl.text.trim();
                  if (itemName.isNotEmpty) {
                    final item = FoodItemModel(
                      itemId: 'food_${DateTime.now().millisecondsSinceEpoch}',
                      eventId: eventId,
                      category: category,
                      itemName: itemName,
                    );
                    await ref.read(eventRepositoryProvider).addFoodItem(item);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('Add Dish'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAssignFoodModal(BuildContext context, WidgetRef ref, FoodItemModel foodItem, String groupId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final membersAsync = ref.watch(groupMembersProvider(groupId));
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assign "${foodItem.itemName}"', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              membersAsync.when(
                loading: () => const LoadingState(),
                error: (e, s) => Text(e.toString()),
                data: (members) {
                  return SizedBox(
                    height: 250,
                    child: ListView(
                      children: [
                        ListTile(
                          leading: const CircleAvatar(child: Text('❌')),
                          title: const Text('Unassigned'),
                          onTap: () async {
                            await ref.read(eventRepositoryProvider).assignFoodItem(
                              foodItem.eventId,
                              foodItem.itemId,
                              '',
                              'Unassigned',
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                        ),
                        ...members.map((m) => ListTile(
                              leading: MemberAvatar(name: m.displayName),
                              title: Text(m.displayName),
                              onTap: () async {
                                await ref.read(eventRepositoryProvider).assignFoodItem(
                                  foodItem.eventId,
                                  foodItem.itemId,
                                  m.userId,
                                  m.displayName,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                            )),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  int _parseTimeToMinutes(String timeStr) {
    try {
      final clean = timeStr.trim().toUpperCase();
      final isPm = clean.contains('PM');
      final isAm = clean.contains('AM');
      final digits = clean.replaceAll(RegExp(r'[^0-9:]'), '');
      final parts = digits.split(':');
      if (parts.length >= 2) {
        int h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        if (isPm && h < 12) h += 12;
        if (isAm && h == 12) h = 0;
        return h * 60 + m;
      }
    } catch (_) {}
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final event = eventAsync.value;
    if (event != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(selectedEventIdProvider) != event.eventId) {
          ref.read(selectedEventIdProvider.notifier).state = event.eventId;
        }
        if (ref.read(selectedGroupIdProvider) != event.groupId) {
          ref.read(selectedGroupIdProvider.notifier).state = event.groupId;
        }
      });
    }

    final rsvpsAsync = ref.watch(eventRsvpsProvider(eventId));
    final timelineAsync = ref.watch(eventTimelineProvider(eventId));
    final foodAsync = ref.watch(eventFoodPlannerProvider(eventId));
    final winnersAsync = ref.watch(eventWinnersProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home_outlined, color: AppColors.primary),
          tooltip: 'Go to Home',
          onPressed: () => context.go('/home'),
        ),
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

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: SingleChildScrollView(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text('PARTY SCHEDULE & TIMELINE ⏰', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2), overflow: TextOverflow.ellipsis),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddTimelineDialog(context, ref, eventId),
                      icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                      label: const Text('Add Activity', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                timelineAsync.when(
                  loading: () => const LoadingState(),
                  error: (_, _) => const SizedBox(),
                  data: (items) {
                    if (items.isEmpty) {
                      return AppCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: TextButton.icon(
                              onPressed: () => _showAddTimelineDialog(context, ref, eventId),
                              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                              label: const Text('Add First Schedule Activity', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      );
                    }
                    final sortedItems = List<TimelineItemModel>.from(items)
                      ..sort((a, b) {
                        final timeA = _parseTimeToMinutes(a.timeString);
                        final timeB = _parseTimeToMinutes(b.timeString);
                        if (timeA != timeB) return timeA.compareTo(timeB);
                        return a.order.compareTo(b.order);
                      });

                    return AppCard(
                      child: Column(
                        children: sortedItems.map((item) {
                          return ListTile(
                            leading: IconButton(
                              icon: Icon(
                                item.isCompleted
                                    ? Icons.check_circle
                                    : (item.isCurrent ? Icons.play_circle_fill : Icons.radio_button_unchecked),
                                color: item.isCompleted
                                    ? AppColors.success
                                    : (item.isCurrent ? AppColors.primary : AppColors.textMuted),
                              ),
                              onPressed: () {
                                final updated = TimelineItemModel(
                                  itemId: item.itemId,
                                  eventId: item.eventId,
                                  timeString: item.timeString,
                                  title: item.title,
                                  isCompleted: !item.isCompleted,
                                  isCurrent: false,
                                  order: item.order,
                                );
                                ref.read(eventRepositoryProvider).updateTimelineItem(eventId, updated);
                              },
                            ),
                            title: Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: item.isCurrent ? FontWeight.bold : FontWeight.normal,
                                decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                              ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text('FOOD & POTLUCK PLANNER 🍰', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2), overflow: TextOverflow.ellipsis),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddFoodDialog(context, ref, eventId, event.groupId),
                      icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                      label: const Text('Add Dish', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                foodAsync.when(
                  loading: () => const LoadingState(),
                  error: (_, _) => const SizedBox(),
                  data: (items) {
                    if (items.isEmpty) {
                      return AppCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: TextButton.icon(
                              onPressed: () => _showAddFoodDialog(context, ref, eventId, event.groupId),
                              icon: const Icon(Icons.add_circle_outline, color: AppColors.secondary),
                              label: const Text('Add First Potluck Dish', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      );
                    }
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
                            trailing: InkWell(
                              onTap: () => _showAssignFoodModal(context, ref, f, event.groupId),
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 120),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        f.assignedUserName ?? 'Unassigned',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.primary),
                                  ],
                                ),
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
          ),
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
    final firebaseUser = ref.watch(authRepositoryProvider).currentFirebaseUser;
    final currentUserId = user?.uid ?? firebaseUser?.uid ?? 'guest';
    final currentUserName = (user != null && user.displayName.isNotEmpty)
        ? user.displayName
        : (firebaseUser?.displayName ?? 'Member');
    final rsvps = ref.watch(eventRsvpsProvider(eventId)).value ?? [];
    final currentRsvp = rsvps.firstWhere(
      (r) => r.userId == currentUserId,
      orElse: () => RsvpModel(
        userId: currentUserId,
        eventId: eventId,
        userName: currentUserName,
        status: RsvpStatus.pending,
      ),
    );

    return Row(
      children: [
        _RsvpChip(
          label: 'Going 👍',
          isSelected: currentRsvp.status == RsvpStatus.going,
          color: AppColors.success,
          onTap: () {
            ref.read(eventRepositoryProvider).setRsvp(
                  eventId: eventId,
                  userId: currentUserId,
                  userName: currentUserName,
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
                  userId: currentUserId,
                  userName: currentUserName,
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
                  userId: currentUserId,
                  userName: currentUserName,
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
    final groupId = ref.watch(selectedGroupIdProvider) ?? '';
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
