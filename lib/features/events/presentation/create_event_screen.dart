import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../app/providers.dart';
import '../domain/event_model.dart';
import '../../groups/domain/group_model.dart';
import '../../members/domain/member_model.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  final String? initialGroupId;

  const CreateEventScreen({super.key, this.initialGroupId});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  String? _selectedGroupId;
  bool _isGenerating = false;

  final List<String> _themes = [
    'Bollywood', 'Retro 90s', 'Black & Gold', 'Floral', 'Color Party',
    'Traditional', 'Casino', 'Beach', 'Festival', 'Pastel', 'Denim', 'Masquerade'
  ];

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.initialGroupId;
  }

  Future<void> _handleBulkGenerate({
    required GroupModel group,
    required List<MemberModel> members,
    required List<EventModel> existingEvents,
  }) async {
    setState(() => _isGenerating = true);
    final user = ref.read(currentUserProvider).value;

    final created = await ref.read(eventRepositoryProvider).generateEventsForGroup(
      group: group,
      members: members,
      existingEvents: existingEvents,
      currentUserId: user?.uid ?? 'system',
    );

    setState(() => _isGenerating = false);

    if (mounted) {
      ref.invalidate(groupEventsProvider(group.groupId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Generated ${created.length} Kitty event(s) for your members!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _showEditEventModal(EventModel event) {
    final titleCtrl = TextEditingController(text: event.title);
    final venueCtrl = TextEditingController(text: event.venue);
    final addressCtrl = TextEditingController(text: event.venueAddress);
    final dressCtrl = TextEditingController(text: event.dressCode);
    final foodCtrl = TextEditingController(text: event.foodNotes);
    final descCtrl = TextEditingController(text: event.description);
    DateTime selectedDate = event.date;
    String selectedTheme = _themes.contains(event.theme) ? event.theme : _themes.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit & Customize Event ✏️',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Text('👑 Host: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(event.hostName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Event Title',
                      prefixIcon: Icon(Icons.event),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                    title: const Text('Event Date'),
                    subtitle: Text(DateFormat('EEEE, dd MMMM yyyy').format(selectedDate)),
                    trailing: TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      child: const Text('Change Date'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedTheme,
                    decoration: const InputDecoration(
                      labelText: 'Party Theme 🎭',
                      prefixIcon: Icon(Icons.theater_comedy),
                    ),
                    items: _themes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedTheme = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: venueCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Venue Name',
                      hintText: "e.g., Host's Residence / Community Center",
                      prefixIcon: Icon(Icons.place),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Venue Address',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Dress Code',
                      hintText: 'e.g., Festive / Retro Saree',
                      prefixIcon: Icon(Icons.checkroom),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: foodCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Food & Snack Notes',
                      hintText: 'Chaat counter, starters & mocktails',
                      prefixIcon: Icon(Icons.restaurant),
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: 'Save Customizations 🎉',
                    onPressed: () async {
                      final updated = event.copyWith(
                        title: titleCtrl.text.trim(),
                        date: selectedDate,
                        theme: selectedTheme,
                        venue: venueCtrl.text.trim(),
                        venueAddress: addressCtrl.text.trim(),
                        dressCode: dressCtrl.text.trim(),
                        foodNotes: foodCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                      );
                      await ref.read(eventRepositoryProvider).updateEvent(updated);
                      ref.invalidate(groupEventsProvider(event.groupId));
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🎉 Event customized successfully!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userGroupsAsync = ref.watch(userGroupsProvider);
    final currentSelectedGroup = ref.watch(selectedGroupIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Kitty Events'),
      ),
      body: userGroupsAsync.when(
        loading: () => const LoadingState(),
        error: (e, s) => ErrorState(message: e.toString()),
        data: (groups) {
          if (groups.isEmpty) {
            return EmptyState(
              title: 'No Kitty Group Found',
              description: 'You need to create or join a Kitty Group before creating events.',
              icon: Icons.groups_outlined,
              actionText: 'Create Kitty Group 🎉',
              onAction: () => context.push('/create-group'),
            );
          }

          _selectedGroupId ??= (currentSelectedGroup != null && groups.any((g) => g.groupId == currentSelectedGroup))
              ? currentSelectedGroup
              : groups.first.groupId;

          final selectedGroup = groups.firstWhere((g) => g.groupId == _selectedGroupId, orElse: () => groups.first);

          final membersAsync = ref.watch(groupMembersProvider(_selectedGroupId!));
          final eventsAsync = ref.watch(groupEventsProvider(_selectedGroupId!));

          final members = membersAsync.value ?? [];
          final events = eventsAsync.value ?? [];

          final Set<String> existingHostIds = events.map((e) => e.hostId).where((id) => id.isNotEmpty).toSet();
          final unassignedMembers = members.where((m) => !existingHostIds.contains(m.userId)).toList();

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: 24 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group Selector Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGroupId,
                      decoration: const InputDecoration(
                        labelText: 'Select Kitty Group *',
                        prefixIcon: Icon(Icons.groups, color: AppColors.primary),
                      ),
                      items: groups.map((GroupModel g) {
                        return DropdownMenuItem<String>(
                          value: g.groupId,
                          child: Text(
                            '${g.name} (${g.memberIds.length} members)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedGroupId = val);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Bulk Event Generation Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.1),
                            AppColors.gold.withValues(alpha: 0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('🎉', style: TextStyle(fontSize: 24)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Create Events for All Members',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                    Text(
                                      '${members.length} members in group • Meeting frequency: ${selectedGroup.frequency}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            unassignedMembers.isNotEmpty
                                ? '⚡ ${unassignedMembers.length} member(s) do not have a scheduled event yet! Generate events so everyone can see and edit their Kitty turns.'
                                : '✅ All ${members.length} member(s) have a scheduled event in this cycle.',
                            style: TextStyle(
                              fontSize: 13,
                              color: unassignedMembers.isNotEmpty ? AppColors.primary : Colors.green.shade700,
                              fontWeight: unassignedMembers.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 14),
                          PrimaryButton(
                            text: unassignedMembers.isNotEmpty
                                ? 'Generate Events for Unassigned Members (${unassignedMembers.length}) 🚀'
                                : 'Re-Generate Events for All Members 🎉',
                            isLoading: _isGenerating,
                            onPressed: () => _handleBulkGenerate(
                              group: selectedGroup,
                              members: members,
                              existingEvents: events,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Events List Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Scheduled Events (${events.length})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Tap event to edit',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (events.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.event_note_outlined, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'No events created yet',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap "Generate Events for All Members" above to create events automatically!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final ev = events[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Text('🎉', style: TextStyle(fontSize: 22)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ev.title,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.gold.withValues(alpha: 0.3),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  '👑 Host: ${ev.hostName}',
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '📅 ${ev.dateString}',
                                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('📍 Venue: ${ev.venue}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                          Text('🎭 Theme: ${ev.theme}', style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () => _showEditEventModal(ev),
                                      icon: const Icon(Icons.edit_note, size: 16),
                                      label: const Text('Edit & Customize ✏️', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
