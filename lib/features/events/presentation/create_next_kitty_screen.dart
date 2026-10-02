import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../app/providers.dart';
import '../domain/event_model.dart';

class CreateNextKittyScreen extends ConsumerStatefulWidget {
  final String groupId;

  const CreateNextKittyScreen({super.key, required this.groupId});

  @override
  ConsumerState<CreateNextKittyScreen> createState() => _CreateNextKittyScreenState();
}

class _CreateNextKittyScreenState extends ConsumerState<CreateNextKittyScreen> {
  final _titleController = TextEditingController();
  final _venueController = TextEditingController();
  DateTime _nextDate = DateTime.now().add(const Duration(days: 30));
  final String _nextHostName = 'Next Host Member';
  final String _nextHostId = 'user_next_host';
  final String _theme = 'Retro 90s';

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  void _handleCreateNextKitty() async {
    final newEventId = 'event_${DateTime.now().millisecondsSinceEpoch}';
    final user = ref.read(currentUserProvider).value;

    final titleText = _titleController.text.trim();
    final newEvent = EventModel(
      eventId: newEventId,
      groupId: widget.groupId,
      title: titleText.isNotEmpty ? titleText : 'Next Kitty Party',
      date: _nextDate,
      startTime: '4:00 PM',
      endTime: '7:00 PM',
      hostId: _nextHostId,
      hostName: _nextHostName,
      venue: _venueController.text.trim(),
      theme: _theme,
      createdBy: user?.uid ?? '',
      status: EventStatus.upcoming,
    );

    await ref.read(eventRepositoryProvider).createEvent(newEvent);
    ref.read(selectedEventIdProvider.notifier).state = newEventId;

    if (mounted) {
      ref.invalidate(groupEventsProvider(widget.groupId));
      context.go('/event/$newEventId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prepare Next Kitty'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
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
                Center(
                  child: Column(
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      const Text(
                        'Kitty Party Completed!',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Set up the details for your next gathering in seconds.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Event Title', prefixIcon: Icon(Icons.event)),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.king_bed, color: AppColors.gold),
                        title: const Text('Next Host (Rotated)'),
                        subtitle: Text('👑 $_nextHostName'),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                        title: const Text('Suggested Date'),
                        subtitle: Text(DateFormat('EEEE, dd MMMM yyyy').format(_nextDate)),
                        trailing: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _nextDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => _nextDate = picked);
                          },
                          child: const Text('Change'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _venueController,
                        decoration: const InputDecoration(labelText: 'Venue', prefixIcon: Icon(Icons.place)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  text: 'Create Next Kitty 🌸',
                  onPressed: _handleCreateNextKitty,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
