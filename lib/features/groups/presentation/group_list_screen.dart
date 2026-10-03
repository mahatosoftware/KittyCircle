import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../app/providers.dart';
import '../domain/group_model.dart';

class GroupListScreen extends ConsumerWidget {
  const GroupListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(userGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Kitty Groups'),
        actions: [
          IconButton(
            tooltip: 'Join Kitty',
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
            onPressed: () => context.push('/join-group'),
          ),
          IconButton(
            tooltip: 'Create Group',
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => context.push('/create-group'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userGroupsProvider);
        },
        child: groupsAsync.when(
          loading: () => const LoadingState(),
          error: (e, s) => ErrorState(message: e.toString()),
          data: (groups) {
          if (groups.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: EmptyState(
                  title: 'No Kitty Groups',
                  description: 'You have not joined any kitty party groups yet.',
                  icon: Icons.groups_outlined,
                ),
              ),
            );
          }

          final width = MediaQuery.sizeOf(context).width;
          final isTablet = width >= 600;

          final Widget listWidget = isTablet
              ? GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 480,
                    mainAxisExtent: 160,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return _buildGroupCard(context, ref, group);
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildGroupCard(context, ref, group),
                    );
                  },
                );

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: listWidget,
            ),
          );
        },
      ),
    ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'join_group_fab',
            onPressed: () => context.push('/join-group'),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('Join Kitty', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'create_group_fab',
            onPressed: () => context.push('/create-group'),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('New Kitty', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, WidgetRef ref, GroupModel group) {
    return AppCard(
      onTap: () {
        ref.read(selectedGroupIdProvider.notifier).state = group.groupId;
        context.push('/group/${group.groupId}');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.25),
                child: Text(
                  group.name.isNotEmpty ? group.name.substring(0, 1) : '🌸',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatChip(
                icon: Icons.people_outline,
                label: '${group.memberIds.length} Members',
              ),
              _StatChip(
                icon: Icons.payments_outlined,
                label: '${group.currency}${group.contributionAmount.toInt()} ${group.frequency.toLowerCase()}',
              ),
              const _StatChip(
                icon: Icons.event_outlined,
                label: 'Active Kitty',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
