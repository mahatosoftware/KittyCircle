import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../app/providers.dart';

class HostScheduleScreen extends ConsumerWidget {
  final String groupId;

  const HostScheduleScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(hostScheduleProvider(groupId));
    final groupAsync = ref.watch(currentGroupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Rotation Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.how_to_reg_outlined, color: AppColors.primary),
            tooltip: 'Configure Host Selection',
            onPressed: () => context.push('/host-selection/$groupId'),
          ),
        ],
      ),
      body: scheduleAsync.when(
        loading: () => const LoadingState(),
        error: (e, s) => ErrorState(message: e.toString()),
        data: (schedule) {
          if (schedule.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    const Text(
                      'No Host Schedule Yet',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Set up host selection options: Pick randomly, Volunteer, or Rotation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/host-selection/$groupId'),
                      icon: const Text('🎉', style: TextStyle(fontSize: 16)),
                      label: const Text('Set Up Host Selection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: schedule.length,
                itemBuilder: (context, index) {
                  final item = schedule[index];
                  final isCurrent = index == 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: AppCard(
                      backgroundColor: isCurrent ? AppColors.primary.withValues(alpha: 0.08) : null,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isCurrent ? AppColors.gold : AppColors.primaryLight.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              isCurrent ? '👑' : '📅',
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.monthYear,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.hostName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('EEEE, dd MMMM').format(item.scheduledDate),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          if (isCurrent)
                            ElevatedButton.icon(
                              onPressed: () {
                                final link = DeepLinkService.createGroupInviteLink(groupId);
                                WhatsAppService.shareNextKitty(
                                  groupName: groupAsync.value?.name ?? 'Sunshine Ladies',
                                  nextHost: item.hostName,
                                  date: DateFormat('dd MMMM yyyy').format(item.scheduledDate),
                                  nextKittyLink: link,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Host reminder sent for ${item.hostName}! 🎉')),
                                );
                              },
                              icon: const Icon(Icons.send, size: 16),
                              label: const Text('Notify Host'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
