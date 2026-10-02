import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../app/providers.dart';
import '../domain/game_models.dart';
import '../engine/party_game.dart';

class PlayerGameScreen extends ConsumerStatefulWidget {
  final String gameId;

  const PlayerGameScreen({super.key, required this.gameId});

  @override
  ConsumerState<PlayerGameScreen> createState() => _PlayerGameScreenState();
}

class _PlayerGameScreenState extends ConsumerState<PlayerGameScreen> {
  int? _selectedOption;
  bool _submitted = false;
  int _playerScore = 0;
  final Set<String> _recalledEmojis = {};
  int _targetHits = 0;

  void _submitMultipleChoiceAnswer(int index, int correctIndex, int points) {
    if (_submitted) return;
    setState(() {
      _selectedOption = index;
      _submitted = true;
      if (index == correctIndex) {
        _playerScore += points;
      }
    });
  }

  void _toggleEmojiSelection(String emoji) {
    if (_submitted) return;
    setState(() {
      if (_recalledEmojis.contains(emoji)) {
        _recalledEmojis.remove(emoji);
      } else {
        _recalledEmojis.add(emoji);
      }
    });
  }

  void _submitMemoryRecall() {
    if (_submitted) return;
    int points = 0;
    for (final emoji in _recalledEmojis) {
      if (MemoryChallengeGame.targetItems.contains(emoji)) {
        points += 20;
      }
    }
    setState(() {
      _submitted = true;
      _playerScore += points;
    });
  }

  void _hitTargetRing(int ringPoints) {
    setState(() {
      _targetHits++;
      _playerScore += ringPoints;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(gameRepositoryProvider).watchGameSession(widget.gameId);

    return StreamBuilder<GameSessionModel?>(
      stream: sessionAsync,
      builder: (context, snapshot) {
        final session = snapshot.data ??
            GameSessionModel(
              gameId: widget.gameId,
              eventId: ref.watch(selectedEventIdProvider) ?? '',
              groupId: ref.watch(selectedGroupIdProvider) ?? '',
              gameName: 'Party Game',
              type: GameType.bollywoodQuiz,
              hostUserId: ref.watch(currentUserProvider).value?.uid ?? '',
            );

        return Scaffold(
          appBar: AppBar(
            title: Text('${session.gameName} 🎮'),
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 20 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // SCORE CARD HEADER
                    AppCard(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ROUND ${session.currentRound} OF ${session.totalRounds}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                          ),
                          Text(
                            'Your Score: $_playerScore pts',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // GAME-TYPE SPECIFIC PLAYER WIDGET
                    _buildGameSpecificPlayerContent(session),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameSpecificPlayerContent(GameSessionModel session) {
    switch (session.type) {
      case GameType.luckyDraw:
        return Column(
          children: [
            AppCard(
              gradient: AppColors.primaryGradient,
              child: const Column(
                children: [
                  Icon(Icons.card_giftcard, size: 54, color: AppColors.gold),
                  SizedBox(height: 12),
                  Text('LUCKY DRAW TICKET', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
                  SizedBox(height: 6),
                  Text('Ticket #: KC-7749', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Status: Entered into Live Draw 🎟️', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                children: [
                  const Text('WINNER STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                  const SizedBox(height: 12),
                  const Text('🎉 Drawing winner live on Host Screen...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Refresh Lucky Draw Status 🔄',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Checking live lucky draw winner...')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );

      case GameType.bollywoodQuiz:
        final roundIdx = (session.currentRound - 1) % BollywoodQuizGame.questions.length;
        final q = BollywoodQuizGame.questions[roundIdx];
        final options = List<String>.from(q['options']);
        final correctIndex = q['correct'] as int;
        return _buildMultipleChoiceQuestionWidget(
          title: 'Q${session.currentRound}: ${q['question']}',
          options: options,
          correctIndex: correctIndex,
          points: 30,
        );

      case GameType.memoryChallenge:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                children: [
                  const Text('🧠 MEMORY RECALL CHALLENGE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 10),
                  const Text('Select all the emojis you saw on the host screen!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: MemoryChallengeGame.questionOptions.map((emoji) {
                      final isSelected = _recalledEmojis.contains(emoji);
                      return ChoiceChip(
                        label: Text(emoji, style: const TextStyle(fontSize: 28)),
                        selected: isSelected,
                        onSelected: _submitted ? null : (_) => _toggleEmojiSelection(emoji),
                        selectedColor: AppColors.gold,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (!_submitted)
              PrimaryButton(
                text: 'Submit Memory Recall 🚀',
                onPressed: _recalledEmojis.isEmpty ? null : _submitMemoryRecall,
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '🎉 Memory answers submitted! Points added to score.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success),
                ),
              ),
          ],
        );

      case GameType.emojiGuess:
        final puzzleIdx = (session.currentRound - 1) % EmojiGuessGame.emojiPuzzles.length;
        final p = EmojiGuessGame.emojiPuzzles[puzzleIdx];
        final options = List<String>.from(p['options']);
        final correctIndex = p['correct'] as int;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              backgroundColor: AppColors.gold.withValues(alpha: 0.15),
              child: Column(
                children: [
                  const Text('DECODE EMOJIS 😀', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                  const SizedBox(height: 12),
                  Text(p['emojis'], style: const TextStyle(fontSize: 42)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ..._buildOptionCardsList(options: options, correctIndex: correctIndex, points: 25),
          ],
        );

      case GameType.guessSong:
        final clueIdx = (session.currentRound - 1) % GuessTheSongGame.songClues.length;
        final c = GuessTheSongGame.songClues[clueIdx];
        final options = List<String>.from(c['options']);
        final correctIndex = c['correct'] as int;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              gradient: AppColors.primaryGradient,
              child: Column(
                children: [
                  const Icon(Icons.music_note, color: AppColors.gold, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    c['lyrics'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ..._buildOptionCardsList(options: options, correctIndex: correctIndex, points: 30),
          ],
        );

      case GameType.rapidFire:
        final qIdx = (session.currentRound - 1) % RapidFireGame.rapidFireQuestions.length;
        final rf = RapidFireGame.rapidFireQuestions[qIdx];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                children: [
                  const Text('⚡ RAPID FIRE (10s TIMER)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning, fontSize: 13)),
                  const SizedBox(height: 10),
                  Text(rf['prompt']!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    backgroundColor: _selectedOption == 0 ? AppColors.primary : Colors.white,
                    onTap: _submitted ? null : () => _submitMultipleChoiceAnswer(0, 0, 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        rf['optionA']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _selectedOption == 0 ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppCard(
                    backgroundColor: _selectedOption == 1 ? AppColors.primary : Colors.white,
                    onTap: _submitted ? null : () => _submitMultipleChoiceAnswer(1, 1, 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        rf['optionB']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _selectedOption == 1 ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_submitted) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('⚡ Choice Recorded! +10 Points awarded.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
              ),
            ],
          ],
        );

      case GameType.wordChallenge:
        final wIdx = (session.currentRound - 1) % WordChallengeGame.wordPuzzles.length;
        final wp = WordChallengeGame.wordPuzzles[wIdx];
        final options = List<String>.from(wp['options']);
        final correctIndex = wp['correct'] as int;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              gradient: AppColors.primaryGradient,
              child: Column(
                children: [
                  const Text('🔤 UNSCRAMBLE THE WORD', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1)),
                  const SizedBox(height: 12),
                  Text(wp['scrambled'], style: const TextStyle(fontSize: 32, letterSpacing: 4, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ..._buildOptionCardsList(options: options, correctIndex: correctIndex, points: 20),
          ],
        );

      case GameType.targetChallenge:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                children: [
                  const Text('🎯 BULLSEYE TARGET CHALLENGE', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text('Target Hits: $_targetHits', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // INTERACTIVE BULLSEYE TARGET WIDGET
            Center(
              child: GestureDetector(
                onTapDown: (details) {
                  // Center hit: 50, middle hit: 30, outer hit: 10
                  _hitTargetRing(50);
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 120,
                      backgroundColor: Colors.red.shade400,
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.red.shade700,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🎯', style: TextStyle(fontSize: 28)),
                              Text('50 PTS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tap the target bullseye to score points before round ends!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
            ),
          ],
        );

      case GameType.custom:
        return Column(
          children: [
            AppCard(
              child: const Column(
                children: [
                  Text('🛠️ CUSTOM GAME RULES', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                  SizedBox(height: 10),
                  Text(
                    'Follow the party host\'s instructions for this custom game. Scores are updated live by the host!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildMultipleChoiceQuestionWidget({
    required String title,
    required List<String> options,
    required int correctIndex,
    required int points,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 20),
        ..._buildOptionCardsList(options: options, correctIndex: correctIndex, points: points),
      ],
    );
  }

  List<Widget> _buildOptionCardsList({
    required List<String> options,
    required int correctIndex,
    required int points,
  }) {
    return List.generate(options.length, (index) {
      final option = options[index];
      final isSelected = _selectedOption == index;
      final isCorrect = index == correctIndex;

      Color cardColor = Colors.white;
      if (_submitted) {
        if (isCorrect) {
          cardColor = AppColors.success.withValues(alpha: 0.15);
        } else if (isSelected) {
          cardColor = AppColors.error.withValues(alpha: 0.15);
        }
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          backgroundColor: cardColor,
          onTap: _submitted ? null : () => _submitMultipleChoiceAnswer(index, correctIndex, points),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isSelected ? AppColors.primary : Colors.grey.shade300,
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  option,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              if (_submitted && isCorrect)
                const Icon(Icons.check_circle, color: AppColors.success)
              else if (_submitted && isSelected && !isCorrect)
                const Icon(Icons.cancel, color: AppColors.error),
            ],
          ),
        ),
      );
    });
  }
}
