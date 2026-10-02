import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../app/providers.dart';
import '../domain/member_model.dart';

class MembersScreen extends ConsumerStatefulWidget {
  final String groupId;

  const MembersScreen({super.key, required this.groupId});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  void _showAddMemberModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    MemberRole role = MemberRole.member;
    DateTime? birthday;
    DateTime? anniversary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20 + MediaQuery.paddingOf(ctx).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Add New Kitty Member 🌸',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Member Name *', prefixIcon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<MemberRole>(
                      initialValue: role,
                      decoration: const InputDecoration(labelText: 'Group Role', prefixIcon: Icon(Icons.admin_panel_settings)),
                      items: const [
                        DropdownMenuItem(value: MemberRole.member, child: Text('Member (Default)')),
                        DropdownMenuItem(value: MemberRole.admin, child: Text('Admin')),
                        DropdownMenuItem(value: MemberRole.owner, child: Text('Owner')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => role = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cake, color: AppColors.primary),
                      title: const Text('Birthday 🎂'),
                      subtitle: Text(birthday != null ? DateFormat('dd MMMM yyyy').format(birthday!) : 'Not set'),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime(1992, 10, 15),
                            firstDate: DateTime(1940),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setModalState(() => birthday = picked);
                        },
                        child: const Text('Set Date'),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.favorite, color: AppColors.secondary),
                      title: const Text('Anniversary 💍'),
                      subtitle: Text(anniversary != null ? DateFormat('dd MMMM yyyy').format(anniversary!) : 'Not set'),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2018, 11, 24),
                            firstDate: DateTime(1960),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setModalState(() => anniversary = picked);
                        },
                        child: const Text('Set Date'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isNotEmpty) {
                          final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
                          await ref.read(memberRepositoryProvider).addMember(
                                groupId: widget.groupId,
                                userId: userId,
                                displayName: nameCtrl.text.trim(),
                                phoneNumber: phoneCtrl.text.trim(),
                                role: role,
                                birthday: birthday,
                                anniversary: anniversary,
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Save Member 🎉'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditMemberModal(BuildContext context, MemberModel member) {
    final nameCtrl = TextEditingController(text: member.displayName);
    final phoneCtrl = TextEditingController(text: member.phoneNumber ?? '');
    MemberRole role = member.role;
    DateTime? birthday = member.birthday;
    DateTime? anniversary = member.anniversary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20 + MediaQuery.paddingOf(ctx).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Edit ${member.displayName}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Member Name', prefixIcon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<MemberRole>(
                      initialValue: role,
                      decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.admin_panel_settings)),
                      items: const [
                        DropdownMenuItem(value: MemberRole.member, child: Text('Member')),
                        DropdownMenuItem(value: MemberRole.admin, child: Text('Admin')),
                        DropdownMenuItem(value: MemberRole.owner, child: Text('Owner')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => role = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cake, color: AppColors.primary),
                      title: const Text('Birthday 🎂'),
                      subtitle: Text(birthday != null ? DateFormat('dd MMMM yyyy').format(birthday!) : 'Not set'),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: birthday ?? DateTime(1992, 10, 15),
                            firstDate: DateTime(1940),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setModalState(() => birthday = picked);
                        },
                        child: const Text('Change'),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.favorite, color: AppColors.secondary),
                      title: const Text('Anniversary 💍'),
                      subtitle: Text(anniversary != null ? DateFormat('dd MMMM yyyy').format(anniversary!) : 'Not set'),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: anniversary ?? DateTime(2018, 11, 24),
                            firstDate: DateTime(1960),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setModalState(() => anniversary = picked);
                        },
                        child: const Text('Change'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await ref.read(memberRepositoryProvider).updateMemberDetails(
                              groupId: widget.groupId,
                              userId: member.userId,
                              displayName: nameCtrl.text.trim(),
                              phoneNumber: phoneCtrl.text.trim(),
                              role: role,
                              birthday: birthday,
                              anniversary: anniversary,
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Update Profile ✨'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMemberDetailModal(BuildContext context, MemberModel member) {
    final groupAsync = ref.read(currentGroupProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: 24 + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MemberAvatar(name: member.displayName, role: member.roleString),
              const SizedBox(height: 12),
              Text(
                member.displayName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: member.role == MemberRole.owner
                      ? AppColors.gold.withValues(alpha: 0.25)
                      : (member.role == MemberRole.admin ? AppColors.secondary.withValues(alpha: 0.15) : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_roleEmoji(member.role)} ${member.roleString}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: member.role == MemberRole.owner
                        ? AppColors.goldDark
                        : (member.role == MemberRole.admin ? AppColors.secondary : AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.phone, color: AppColors.primary),
                title: const Text('Phone'),
                subtitle: Text(member.phoneNumber?.isNotEmpty == true ? member.phoneNumber! : 'Not provided'),
              ),
              ListTile(
                leading: const Icon(Icons.cake, color: AppColors.primary),
                title: const Text('Birthday 🎂'),
                subtitle: Text(member.birthdayString ?? 'Not recorded'),
                trailing: member.birthdayString != null
                    ? IconButton(
                        icon: const Icon(Icons.celebration, color: AppColors.primary),
                        tooltip: 'Send Birthday Wish',
                        onPressed: () {
                          final groupName = groupAsync.value?.name ?? 'Sunshine Ladies';
                          WhatsAppService.shareNextKitty(
                            groupName: groupName,
                            nextHost: member.displayName,
                            date: member.birthdayString!,
                            nextKittyLink: 'Wishing you a magical Birthday filled with joy & love! 🎂🎉✨',
                          );
                        },
                      )
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.favorite, color: AppColors.secondary),
                title: const Text('Anniversary 💍'),
                subtitle: Text(member.anniversaryString ?? 'Not recorded'),
                trailing: member.anniversaryString != null
                    ? IconButton(
                        icon: const Icon(Icons.card_giftcard, color: AppColors.secondary),
                        tooltip: 'Send Anniversary Wish',
                        onPressed: () {
                          final groupName = groupAsync.value?.name ?? 'Sunshine Ladies';
                          WhatsAppService.shareNextKitty(
                            groupName: groupName,
                            nextHost: member.displayName,
                            date: member.anniversaryString!,
                            nextKittyLink: 'Wishing you both togetherness, happiness & togetherness always! 💍🥂💖',
                          );
                        },
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Details'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditMemberModal(context, member);
                      },
                    ),
                  ),
                  if (member.role != MemberRole.owner) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      icon: const Icon(Icons.person_remove),
                      label: const Text('Remove'),
                      onPressed: () async {
                        await ref.read(memberRepositoryProvider).removeMember(widget.groupId, member.userId);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _roleEmoji(MemberRole role) {
    switch (role) {
      case MemberRole.owner:
        return '👑';
      case MemberRole.admin:
        return '🛡️';
      case MemberRole.member:
        return '🌸';
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));
    final groupAsync = ref.watch(currentGroupProvider);

    return Scaffold(
      body: membersAsync.when(
        loading: () => const LoadingState(),
        error: (e, s) => ErrorState(message: e.toString()),
        data: (members) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 950),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // INVITE MEMBER BANNER
                  AppCard(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    child: Row(
                      children: [
                        const Icon(Icons.share, color: AppColors.primary, size: 28),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Invite Friends via WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              SizedBox(height: 2),
                              Text('Share deep link invitation to your group', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final link = DeepLinkService.createGroupInviteLink(widget.groupId);
                            WhatsAppService.shareKittyInvitation(
                              groupName: groupAsync.value?.name ?? 'Sunshine Ladies',
                              inviteLink: link,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          child: const Text('Invite'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${members.length} MEMBERS', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2)),
                      IconButton(
                        icon: const Icon(Icons.person_add_alt_1, color: AppColors.primary),
                        onPressed: () => _showAddMemberModal(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ...members.map((m) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () => _showMemberDetailModal(context, m),
                        leading: MemberAvatar(name: m.displayName, role: m.roleString),
                        title: Row(
                          children: [
                            Text(m.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            Text(_roleEmoji(m.role), style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.phoneNumber ?? 'Active Member'),
                            if (m.birthdayString != null || m.anniversaryString != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (m.birthdayString != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '🎂 ${m.birthdayString}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  if (m.anniversaryString != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '💍 ${m.anniversaryString}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: m.role == MemberRole.owner
                                ? AppColors.gold.withValues(alpha: 0.25)
                                : (m.role == MemberRole.admin ? AppColors.secondary.withValues(alpha: 0.15) : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            m.roleString,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: m.role == MemberRole.owner
                                  ? AppColors.goldDark
                                  : (m.role == MemberRole.admin ? AppColors.secondary : AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
