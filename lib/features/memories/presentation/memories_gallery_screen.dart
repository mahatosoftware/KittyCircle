import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../app/providers.dart';
import '../domain/memory_model.dart';

class MemoriesGalleryScreen extends ConsumerWidget {
  final String groupId;

  const MemoriesGalleryScreen({super.key, required this.groupId});

  void _showUploadModal(BuildContext context, WidgetRef ref) {
    final captionCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
              const Text('Upload Party Memory 📸', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 40, color: AppColors.primary),
                    SizedBox(height: 8),
                    Text('Tap to select photo from gallery', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: captionCtrl,
                decoration: const InputDecoration(labelText: 'Memory Caption', hintText: 'Fun party selfie! 🎉'),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Upload Photo',
                onPressed: () async {
                  final user = ref.read(currentUserProvider).value;
                  final memory = MemoryModel(
                    memoryId: 'm_${DateTime.now().millisecondsSinceEpoch}',
                    groupId: groupId,
                    eventTitle: 'Kitty Event',
                    imageUrl: 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/600/600',
                    caption: captionCtrl.text.trim().isNotEmpty ? captionCtrl.text.trim() : 'Party Memories 🎉',
                    uploadedByUserId: user?.uid ?? '',
                    uploadedByUserName: (user != null && user.displayName.isNotEmpty) ? user.displayName : 'Member',
                  );

                  await ref.read(memoryRepositoryProvider).addMemory(memory);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openLightbox(BuildContext context, MemoryModel memory) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(memory.imageUrl, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
              child: Text(
                memory.caption,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetGroupId = groupId.isNotEmpty ? groupId : (ref.watch(selectedGroupIdProvider) ?? '');
    if (targetGroupId.isEmpty) {
      return const Scaffold(
        body: EmptyState(
          title: 'No Kitty Selected',
          description: 'Select or create a Kitty Group to view party memories!',
          icon: Icons.photo_library_outlined,
        ),
      );
    }

    final memoriesAsync = ref.watch(groupMemoriesProvider(targetGroupId));

    return Scaffold(
      body: memoriesAsync.when(
        loading: () => const LoadingState(),
        error: (e, s) => ErrorState(message: e.toString()),
        data: (memories) {
          if (memories.isEmpty) {
            return EmptyState(
              title: 'No Party Memories Yet',
              description: 'Upload group photos and save memories from your kitty parties!',
              icon: Icons.photo_library_outlined,
              actionText: 'Upload Photo 📸',
              onAction: () => _showUploadModal(context, ref),
            );
          }

          final width = MediaQuery.sizeOf(context).width;
          final crossCount = width >= 900 ? 4 : (width >= 600 ? 3 : 2);

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.9,
                ),
                itemCount: memories.length,
                itemBuilder: (context, index) {
              final mem = memories[index];
              return InkWell(
                onTap: () => _openLightbox(context, mem),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(mem.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    padding: const EdgeInsets.all(10),
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mem.caption,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'by ${mem.uploadedByUserName}',
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadModal(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text('Add Memory', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
