import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../app/providers.dart';
import '../domain/member_model.dart';

class MembersScreen extends ConsumerWidget {
  final String groupId;

  const MembersScreen({super.key, required this.groupId});

  void _showAddMemberModal(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20 + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add Member',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isNotEmpty) {
                    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
                    await ref.read(memberRepositoryProvider).addMember(
                          groupId: groupId,
                          userId: userId,
                          displayName: nameCtrl.text.trim(),
                          phoneNumber: phoneCtrl.text.trim(),
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('Add Member'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRoleDialog(BuildContext context, WidgetRef ref, MemberModel member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change Role: ${member.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Admin'),
              subtitle: const Text('Can manage events, games, and contributions'),
              trailing: member.role == MemberRole.admin ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () async {
                await ref.read(memberRepositoryProvider).updateRole(groupId, member.userId, MemberRole.admin);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Member'),
              subtitle: const Text('Can view events, RSVP, and play games'),
              trailing: member.role == MemberRole.member ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () async {
                await ref.read(memberRepositoryProvider).updateRole(groupId, member.userId, MemberRole.member);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final groupAsync = ref.watch(currentGroupProvider);

    return Scaffold(
      body: membersAsync.when(
        loading: () => const LoadingState(),
        error: (e, s) => ErrorState(message: e.toString()),
        data: (members) {
          return ListView(
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
                        final link = DeepLinkService.createGroupInviteLink(groupId);
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
                    onPressed: () => _showAddMemberModal(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...members.map((m) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: MemberAvatar(name: m.displayName, role: m.roleString),
                    title: Text(m.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(m.phoneNumber ?? 'Active Member'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: m.roleString == 'Owner'
                                ? AppColors.gold.withValues(alpha: 0.25)
                                : (m.roleString == 'Admin' ? AppColors.secondary.withValues(alpha: 0.15) : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            m.roleString,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: m.roleString == 'Owner'
                                  ? AppColors.goldDark
                                  : (m.roleString == 'Admin' ? AppColors.secondary : AppColors.textSecondary),
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'role') {
                              _showRoleDialog(context, ref, m);
                            } else if (val == 'remove') {
                              ref.read(memberRepositoryProvider).removeMember(groupId, m.userId);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'role', child: Text('Change Role')),
                            if (m.roleString != 'Owner')
                              const PopupMenuItem(value: 'remove', child: Text('Remove Member', style: TextStyle(color: AppColors.error))),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
