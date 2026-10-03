import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../app/providers.dart';
import '../../groups/domain/group_model.dart';

enum HostOptionMode { random, volunteer, rotation }

class HostSelectionScreen extends ConsumerStatefulWidget {
  final String groupId;

  const HostSelectionScreen({super.key, required this.groupId});

  @override
  ConsumerState<HostSelectionScreen> createState() => _HostSelectionScreenState();
}

class _HostSelectionScreenState extends ConsumerState<HostSelectionScreen> {
  HostOptionMode? _selectedMode;
  bool _isSaving = false;
  bool _initialized = false;

  void _initSelectedMode(GroupModel? group) {
    if (_initialized || group == null) return;
    _initialized = true;

    final existingMode = group.hostSelectionMode;
    if (existingMode != null) {
      if (existingMode == 'random') {
        _selectedMode = HostOptionMode.random;
      } else if (existingMode == 'volunteer') {
        _selectedMode = HostOptionMode.volunteer;
      } else if (existingMode == 'rotation') {
        _selectedMode = HostOptionMode.rotation;
      }
    }
  }

  Future<void> _saveHostSelectionMode() async {
    if (_selectedMode == null) return;

    setState(() => _isSaving = true);

    final modeStr = _selectedMode!.name; // 'random', 'volunteer', 'rotation'
    final groupRepo = ref.read(groupRepositoryProvider);

    await groupRepo.updateHostSelectionMode(widget.groupId, modeStr);

    setState(() => _isSaving = false);

    if (mounted) {
      ref.invalidate(currentGroupProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Host selection mode updated to ${_getModeTitle(_selectedMode!)}!'),
          backgroundColor: AppColors.primary,
        ),
      );
      context.go('/group/${widget.groupId}');
    }
  }

  String _getModeTitle(HostOptionMode mode) {
    switch (mode) {
      case HostOptionMode.random:
        return 'Pick Randomly';
      case HostOptionMode.volunteer:
        return 'Volunteer';
      case HostOptionMode.rotation:
        return 'Rotation';
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(currentGroupProvider);
    final group = groupAsync.value;

    _initSelectedMode(group);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Selection Mode'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/group/${widget.groupId}'),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.12),
                              AppColors.gold.withValues(alpha: 0.15),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                        ),
                        child: const Column(
                          children: [
                            Text('👑', style: TextStyle(fontSize: 52)),
                            SizedBox(height: 8),
                            Text(
                              'Select Host Selection Mode',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Choose how hosts are selected when creating events.\nEach member gets exactly 1 hosting turn per Kitty cycle.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Option 1: Pick randomly 🎲
                      _buildOptionCard(
                        mode: HostOptionMode.random,
                        iconEmoji: '🎲',
                        title: 'Pick randomly',
                        subtitle: 'App randomly assigns an unhosted member when an event is created.',
                        badgeText: 'Fair & Random',
                        badgeColor: Colors.purple.shade100,
                        description: 'When creating a new Kitty event, the app will automatically pick a random member who has not yet hosted in the current cycle.',
                      ),

                      const SizedBox(height: 16),

                      // Option 2: Volunteer 👑
                      _buildOptionCard(
                        mode: HostOptionMode.volunteer,
                        iconEmoji: '👑',
                        title: 'Volunteer',
                        subtitle: 'Eligible unhosted members can volunteer to host upcoming Kitty events.',
                        badgeText: 'Popular',
                        badgeColor: AppColors.gold.withValues(alpha: 0.3),
                        description: 'Members can volunteer to host. If multiple members volunteer or if nobody volunteers, the app picks from the unhosted members pool.',
                      ),

                      const SizedBox(height: 16),

                      // Option 3: Rotation 🔄
                      _buildOptionCard(
                        mode: HostOptionMode.rotation,
                        iconEmoji: '🔄',
                        title: 'Rotation',
                        subtitle: 'App creates an automatic sequential hosting order.',
                        badgeText: 'Automated',
                        badgeColor: Colors.blue.shade100,
                        description: 'Members host sequentially in order. Once all members have hosted once, a new Kitty cycle begins automatically.',
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Save Button
              Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: 16 + MediaQuery.paddingOf(context).bottom,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 750),
                    child: PrimaryButton(
                      text: 'Save Host Selection Mode 🎉',
                      isLoading: _isSaving,
                      onPressed: _selectedMode == null ? null : _saveHostSelectionMode,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required HostOptionMode mode,
    required String iconEmoji,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required String description,
  }) {
    final isSelected = _selectedMode == mode;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMode = mode;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Text(iconEmoji, style: const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                badgeText,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.primary : Colors.grey,
                  ),
                ],
              ),
              if (isSelected) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          description,
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
