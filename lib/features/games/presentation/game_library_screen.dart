import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../app/providers.dart';
import '../domain/game_models.dart';
import '../engine/game_engine.dart';

class GameLibraryScreen extends ConsumerWidget {
  const GameLibraryScreen({super.key});

  void _launchGame(BuildContext context, WidgetRef ref, GameDefinition game) async {
    final eventId = ref.read(selectedEventIdProvider) ?? '';
    final groupId = ref.read(selectedGroupIdProvider) ?? '';
    final user = ref.read(currentUserProvider).value;

    final session = await ref.read(gameRepositoryProvider).createGameSession(
          eventId: eventId,
          groupId: groupId,
          gameName: game.name,
          type: game.type,
          hostUserId: user?.uid ?? 'guest_host',
          totalRounds: game.defaultRounds,
        );

    if (context.mounted) {
      context.push('/live-game/${session.gameId}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final crossCount = width >= 900 ? 4 : (width >= 600 ? 3 : 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Party Games Library 🎮'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Party Games Engine',
                      style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Interactive multiplayer games for your kitty party gathering!',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('AVAILABLE GAMES', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2)),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.85,
                ),
                itemCount: GameEngine.availableGames.length,
                itemBuilder: (context, index) {
                  final game = GameEngine.availableGames[index];
                  return AppCard(
                    onTap: () => _launchGame(context, ref, game),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(game.iconEmoji, style: const TextStyle(fontSize: 42)),
                        const SizedBox(height: 10),
                        Text(
                          game.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          game.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Play Now →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
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
  }
}
