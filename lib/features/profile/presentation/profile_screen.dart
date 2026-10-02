import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../features/auth/domain/user_model.dart';
import '../../../app/providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _cityController;
  String _selectedLanguage = 'en';
  DateTime? _birthday;
  DateTime? _anniversary;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _cityController = TextEditingController();
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(month - 1).clamp(0, 11)];
  }

  void _populateUserData(UserModel? user) {
    if (!_initialized && user != null) {
      _nameController.text = user.displayName;
      _cityController.text = user.city;
      _selectedLanguage = user.language;
      _birthday = user.birthday;
      _anniversary = user.anniversary;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      await ref.read(profileRepositoryProvider).updateUserProfile(
            userId: user.uid,
            displayName: _nameController.text.trim(),
            city: _cityController.text.trim(),
            language: _selectedLanguage,
            birthday: _birthday,
            anniversary: _anniversary,
          );
      ref.invalidate(currentUserProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully! 🎉')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.primary),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const LoadingState(),
        error: (e, s) => ErrorState(message: e.toString()),
        data: (user) {
          _populateUserData(user);
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                            child: Text(
                              (user != null && user.displayName.isNotEmpty) ? user.displayName.substring(0, 1).toUpperCase() : '🌸',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppCard(
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          prefixIcon: Icon(Icons.location_city),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedLanguage,
                        decoration: const InputDecoration(
                          labelText: 'Preferred Language',
                          prefixIcon: Icon(Icons.language),
                        ),
                        items: AppConstants.supportedLanguages.map((lang) {
                          return DropdownMenuItem(
                            value: lang['code']!,
                            child: Text(lang['name']!),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedLanguage = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.cake, color: AppColors.primary),
                        title: const Text('Birthday 🎂'),
                        subtitle: Text(
                          _birthday != null
                              ? '${_birthday!.day} ${_monthName(_birthday!.month)} ${_birthday!.year}'
                              : 'Not set (Select Date)',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _birthday ?? DateTime(1992, 10, 15),
                              firstDate: DateTime(1950),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setState(() => _birthday = picked);
                          },
                          child: const Text('Set Date'),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.favorite, color: AppColors.secondary),
                        title: const Text('Anniversary 💍'),
                        subtitle: Text(
                          _anniversary != null
                              ? '${_anniversary!.day} ${_monthName(_anniversary!.month)} ${_anniversary!.year}'
                              : 'Not set (Select Date)',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _anniversary ?? DateTime(2018, 11, 24),
                              firstDate: DateTime(1970),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setState(() => _anniversary = picked);
                          },
                          child: const Text('Set Date'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Settings & Preferences Card
                AppCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: true,
                        title: const Text('Event Reminders & RSVPs'),
                        subtitle: const Text('Receive push notifications for upcoming kitties'),
                        onChanged: (val) {},
                      ),
                      const Divider(),
                      SwitchListTile(
                        value: true,
                        title: const Text('Game & Winner Alerts'),
                        subtitle: const Text('Get notified when live game starts'),
                        onChanged: (val) {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Logout & Account Deletion
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: const Text('Logout', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Account?'),
                        content: const Text(
                            'This will permanently remove your profile and activity from KittyCircle. This action cannot be undone.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel')),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await ref.read(authRepositoryProvider).deleteAccount();
                              if (context.mounted) context.go('/login');
                            },
                            child: const Text('Delete',
                                style: TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Delete Account',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
                const SizedBox(height: 24),
                const AppLogo(size: 60, showShadow: true),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '${AppConstants.appTagline} • v1.0.0',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
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
