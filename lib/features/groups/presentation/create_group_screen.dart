import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../app/providers.dart';
import '../../members/domain/member_model.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _amountController = TextEditingController(text: '2000');
  String _selectedFrequency = 'Monthly';
  String _selectedCurrency = '₹';
  int _durationHours = 3;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _handleCreateGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authUser = ref.read(authRepositoryProvider).currentFirebaseUser;
    final user = ref.read(currentUserProvider).value;
    final ownerId = authUser?.uid ?? user?.uid ?? '';
    if (ownerId.isEmpty) {
      if (mounted) {
        context.go('/login');
      }
      return;
    }
    final ownerName = authUser?.displayName ?? (user != null && user.displayName.isNotEmpty ? user.displayName : 'Kitty Host');

    final group = await ref.read(groupRepositoryProvider).createGroup(
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          contributionAmount: double.parse(_amountController.text.trim()),
          currency: _selectedCurrency,
          frequency: _selectedFrequency,
          defaultDurationHours: _durationHours,
          ownerId: ownerId,
        );

    // Synchronize creator as group owner in member repository
    await ref.read(memberRepositoryProvider).addMember(
          groupId: group.groupId,
          userId: ownerId,
          displayName: ownerName,
          role: MemberRole.owner,
        );

    setState(() => _isLoading = false);

    if (mounted) {
      ref.invalidate(userGroupsProvider);
      ref.read(selectedGroupIdProvider.notifier).state = group.groupId;
      context.go('/group/${group.groupId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Kitty Group'),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Kitty Group Name *',
                  hintText: 'e.g., 🌸 Sunshine Ladies',
                  prefixIcon: Icon(Icons.groups),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter group name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Monthly gathering for food, games, chatter and prizes!',
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCurrency,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      items: ['₹', '\$', '€', '£', 'AED'].map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCurrency = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Monthly Contribution *',
                        prefixIcon: Icon(Icons.payments),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Enter amount';
                        if (double.tryParse(val) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedFrequency,
                decoration: const InputDecoration(
                  labelText: 'Meeting Frequency',
                  prefixIcon: Icon(Icons.repeat),
                ),
                items: ['Monthly', 'Every 2 weeks', 'Custom'].map((f) {
                  return DropdownMenuItem(value: f, child: Text(f));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedFrequency = val);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  const Text('Default Duration: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('$_durationHours Hours', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _durationHours > 1 ? () => setState(() => _durationHours--) : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() => _durationHours++),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Create Kitty Group 🎉',
                isLoading: _isLoading,
                onPressed: _handleCreateGroup,
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
