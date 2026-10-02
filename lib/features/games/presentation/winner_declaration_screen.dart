import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../app/providers.dart';

class WinnerDeclarationScreen extends ConsumerStatefulWidget {
  final String eventId;

  const WinnerDeclarationScreen({super.key, required this.eventId});

  @override
  ConsumerState<WinnerDeclarationScreen> createState() => _WinnerDeclarationScreenState();
}

class _WinnerDeclarationScreenState extends ConsumerState<WinnerDeclarationScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final winnersAsync = ref.watch(eventWinnersProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Winner Announcement 🏆'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.primary),
            onPressed: () {
              final winners = winnersAsync.value ?? [];
              final winnerList = winners.map((w) {
                return {
                  'rank': w.rankEmoji,
                  'name': w.playerName,
                  'game': w.gameName,
                };
              }).toList();

              WhatsAppService.shareGameResult(
                eventTitle: 'October Kitty',
                winners: winnerList,
                groupName: 'Sunshine Ladies',
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.purple, Colors.pink, Colors.amber, Colors.blue],
            ),
          ),
          winnersAsync.when(
            loading: () => const LoadingState(),
            error: (e, s) => ErrorState(message: e.toString()),
            data: (winners) {
              if (winners.isEmpty) {
                return const EmptyState(title: 'No Winners Recorded', description: 'Play games to declare winners!');
              }

              final first = winners.firstWhere((w) => w.rank == 1, orElse: () => winners[0]);
              final second = winners.firstWhere((w) => w.rank == 2, orElse: () => winners.length > 1 ? winners[1] : winners[0]);
              final third = winners.firstWhere((w) => w.rank == 3, orElse: () => winners.length > 2 ? winners[2] : winners[0]);

              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 20 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  children: [
                    const Text(
                      'CONGRATULATIONS! 🎉',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    const Text('Official Game Winners for October Kitty', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 30),

                    // PODIUM VISUALIZER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // 2ND PLACE
                        if (winners.length > 1)
                          _PodiumPillar(
                            rank: '🥈',
                            name: second.playerName,
                            game: second.gameName,
                            height: 110,
                            color: Colors.grey.shade300,
                          ),
                        const SizedBox(width: 12),
                        // 1ST PLACE (TALL)
                        _PodiumPillar(
                          rank: '🥇',
                          name: first.playerName,
                          game: first.gameName,
                          height: 150,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 12),
                        // 3RD PLACE
                        if (winners.length > 2)
                          _PodiumPillar(
                            rank: '🥉',
                            name: third.playerName,
                            game: third.gameName,
                            height: 80,
                            color: Colors.amber.shade200,
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // WINNER DETAILS & PRIZE CARDS
                    const Text('WINNERS & PRIZES 🎁', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2)),
                    const SizedBox(height: 12),

                    ...winners.map((w) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          child: ListTile(
                            leading: Text(w.rankEmoji, style: const TextStyle(fontSize: 32)),
                            title: Text(w.playerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            subtitle: Text('${w.gameName} • Prize: ${w.prizeName} (₹${w.prizeValue.toInt()})'),
                            trailing: Text('${w.score} pts', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),

                    PrimaryButton(
                      text: 'Share Summary on WhatsApp 📲',
                      onPressed: () {
                        final winnerList = winners.map((w) {
                          return {'rank': w.rankEmoji, 'name': w.playerName, 'game': w.gameName};
                        }).toList();
                        WhatsAppService.shareGameResult(eventTitle: 'October Kitty', winners: winnerList, groupName: 'Sunshine Ladies');
                      },
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      text: 'Back to Event Details',
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PodiumPillar extends StatelessWidget {
  final String rank;
  final String name;
  final String game;
  final double height;
  final Color color;

  const _PodiumPillar({
    required this.rank,
    required this.name,
    required this.game,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(rank, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(name.split(' ').first, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          width: 85,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            rank == '🥇' ? '1ST' : (rank == '🥈' ? '2ND' : '3RD'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
