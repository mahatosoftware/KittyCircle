import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../app/providers.dart';
import '../domain/event_model.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _venueController = TextEditingController();
  final _addressController = TextEditingController();
  final _dressCodeController = TextEditingController();
  final _foodNotesController = TextEditingController();
  final _descController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  final TimeOfDay _startTime = const TimeOfDay(hour: 16, minute: 0);
  final TimeOfDay _endTime = const TimeOfDay(hour: 19, minute: 0);
  String _selectedTheme = 'Bollywood';
  String _selectedHostId = 'user_priya_1';
  String _selectedHostName = 'Priya Sharma';
  bool _isLoading = false;

  final Map<String, String> _hostOptions = {
    'user_priya_1': 'Priya Sharma',
    'user_neha_2': 'Neha Gupta',
    'user_kavita_3': 'Kavita Verma',
    'user_ritu_4': 'Ritu Kapoor',
    'user_anjali_5': 'Anjali Singh',
  };

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).value;
    if (user != null && user.uid.isNotEmpty) {
      final name = user.displayName.isNotEmpty ? user.displayName : 'Host User';
      _hostOptions[user.uid] = name;
      _selectedHostId = user.uid;
      _selectedHostName = name;
    } else if (_hostOptions.isNotEmpty) {
      _selectedHostId = _hostOptions.keys.first;
      _selectedHostName = _hostOptions.values.first;
    }
  }

  final List<String> _themes = [
    'Bollywood', 'Retro 90s', 'Black & Gold', 'Floral', 'Color Party',
    'Traditional', 'Casino', 'Beach', 'Festival', 'Pastel', 'Denim', 'Masquerade'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    _addressController.dispose();
    _dressCodeController.dispose();
    _foodNotesController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _handleCreateEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final groupId = ref.read(selectedGroupIdProvider) ?? 'group_sunshine_1';
    final user = ref.read(currentUserProvider).value;

    final eventId = 'event_${DateTime.now().millisecondsSinceEpoch}';
    final event = EventModel(
      eventId: eventId,
      groupId: groupId,
      title: _titleController.text.trim(),
      date: _selectedDate,
      startTime: _startTime.format(context),
      endTime: _endTime.format(context),
      hostId: _selectedHostId,
      hostName: _selectedHostName,
      venue: _venueController.text.trim(),
      venueAddress: _addressController.text.trim(),
      theme: _selectedTheme,
      dressCode: _dressCodeController.text.trim(),
      foodNotes: _foodNotesController.text.trim(),
      description: _descController.text.trim(),
      createdBy: user?.uid ?? 'user_priya_1',
      status: EventStatus.upcoming,
    );

    await ref.read(eventRepositoryProvider).createEvent(event);
    ref.read(selectedEventIdProvider.notifier).state = eventId;

    setState(() => _isLoading = false);

    if (mounted) {
      context.go('/event/$eventId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveHostId = _hostOptions.containsKey(_selectedHostId)
        ? _selectedHostId
        : (_hostOptions.isNotEmpty ? _hostOptions.keys.first : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Kitty Event'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title *',
                  hintText: 'e.g., October Bollywood Kitty',
                  prefixIcon: Icon(Icons.event),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 16),

              // Date Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                title: const Text('Event Date'),
                subtitle: Text(DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate)),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: const Text('Change Date'),
                ),
              ),
              const Divider(),

              // Host Picker
              DropdownButtonFormField<String>(
                initialValue: effectiveHostId,
                decoration: const InputDecoration(
                  labelText: 'Event Host',
                  prefixIcon: Icon(Icons.king_bed),
                ),
                items: _hostOptions.entries.map((e) {
                  return DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedHostId = val;
                      _selectedHostName = _hostOptions[val] ?? 'Host';
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Theme Picker
              DropdownButtonFormField<String>(
                initialValue: _selectedTheme,
                decoration: const InputDecoration(
                  labelText: 'Party Theme 🎭',
                  prefixIcon: Icon(Icons.theater_comedy),
                ),
                items: _themes.map((t) {
                  return DropdownMenuItem(value: t, child: Text(t));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTheme = val);
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _venueController,
                decoration: const InputDecoration(
                  labelText: 'Venue Name *',
                  hintText: 'Priya\'s Residence',
                  prefixIcon: Icon(Icons.place),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter venue' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dressCodeController,
                decoration: const InputDecoration(
                  labelText: 'Dress Code',
                  hintText: 'Retro 90s Saree / Kurti',
                  prefixIcon: Icon(Icons.checkroom),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _foodNotesController,
                decoration: const InputDecoration(
                  labelText: 'Food & Snack Notes',
                  hintText: 'Chat counter, desserts & mocktails',
                  prefixIcon: Icon(Icons.restaurant),
                ),
              ),
              const SizedBox(height: 28),

              PrimaryButton(
                text: 'Publish Kitty Event 🎉',
                isLoading: _isLoading,
                onPressed: _handleCreateEvent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
