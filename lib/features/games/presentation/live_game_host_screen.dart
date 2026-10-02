import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../app/providers.dart';
import '../domain/game_models.dart';
import '../engine/game_engine.dart';
import '../engine/party_game.dart';

class LiveGameHostScreen extends ConsumerStatefulWidget {
  final String gameId;

  const LiveGameHostScreen({super.key, required this.gameId});

  @override
  ConsumerState<LiveGameHostScreen> createState() => _LiveGameHostScreenState();
}

class _LiveGameHostScreenState extends ConsumerState<LiveGameHostScreen> {
  late PartyGame _gameInstance;
  bool _isLive = false;
  int _currentRound = 1;
  int _timerSeconds = 15;
  Timer? _timer;
  String? _luckyWinner;
  bool _isSpinning = false;
  int _highlightedIndex = 0;

  final Map<String, int> _playerScores = {
    'user_priya_1': 90,
    'user_neha_2': 80,
    'user_kavita_3': 75,
    'user_ritu_4': 60,
  };

  final Map<String, String> _playerNames = {
    'user_priya_1': 'Priya Sharma',
    'user_neha_2': 'Neha Gupta',
    'user_kavita_3': 'Kavita Verma',
    'user_ritu_4': 'Ritu Kapoor',
  };

  @override
  void initState() {
    super.initState();
    _gameInstance = GameEngine.createGameInstance(GameType.bollywoodQuiz);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() => _timerSeconds = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _initGameForSession(GameSessionModel session) {
    if (_gameInstance.type != session.type) {
      _gameInstance = GameEngine.createGameInstance(session.type);
    }
  }

  void _startRound(GameSessionModel session) {
    _gameInstance.start();
    setState(() {
      _isLive = true;
      _startTimer(session.type == GameType.rapidFire ? 10 : 15);
      if (session.type == GameType.luckyDraw) {
        _spinLuckyDraw();
      }
    });
  }

  void _nextRound(int totalRounds) {
    _gameInstance.nextRound();
    setState(() {
      if (_currentRound < totalRounds) {
        _currentRound++;
        _startTimer(15);
      }
    });
  }

  void _spinLuckyDraw() {
    final participants = LuckyDrawGame.defaultParticipants;
    if (participants.isEmpty) return;

    setState(() {
      _isSpinning = true;
      _luckyWinner = null;
    });

    int ticks = 0;
    Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _highlightedIndex = (ticks) % participants.length;
      });
      ticks++;
      if (ticks >= 20) {
        timer.cancel();
        final finalWinnerIndex = Random().nextInt(participants.length);
        setState(() {
          _highlightedIndex = finalWinnerIndex;
          _luckyWinner = participants[finalWinnerIndex];
          _isSpinning = false;
        });
      }
    });
  }

  void _adjustScore(String userId, int delta) {
    setState(() {
      _playerScores[userId] = max(0, (_playerScores[userId] ?? 0) + delta);
    });
  }

  void _finishGame(GameSessionModel session) async {
    _timer?.cancel();
    await _gameInstance.end();
    final eventId = ref.read(selectedEventIdProvider) ?? 'event_oct_18';
    final participantMap = _playerNames.map(
      (id, name) => MapEntry(
        id,
        GameParticipantModel(userId: id, gameId: widget.gameId, displayName: name),
      ),
    );

    final winners = GameEngine.computeWinners(
      eventId: eventId,
      gameId: widget.gameId,
      gameName: session.gameName,
      scores: _playerScores,
      participantMap: participantMap,
    );

    await ref.read(gameRepositoryProvider).saveWinners(eventId, winners);

    if (mounted) {
      context.push('/winners/$eventId');
    }
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
              eventId: 'event_oct_18',
              groupId: 'group_sunshine_1',
              gameName: 'Party Game',
              type: GameType.bollywoodQuiz,
              hostUserId: 'user_priya_1',
            );

        _initGameForSession(session);

        return Scaffold(
          appBar: AppBar(
            title: Text('${session.gameName} (Host) 🎮'),
            actions: [
              IconButton(
                icon: const Icon(Icons.phone_android),
                tooltip: 'Player View 📱',
                onPressed: () => context.push('/player-game/${widget.gameId}'),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 20 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // STATUS BADGE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isLive ? AppColors.success.withValues(alpha: 0.15) : AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 4,
                        backgroundColor: _isLive ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isLive ? 'LIVE SESSION' : 'READY TO START',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _isLive ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // TIMER & ROUND CARD
                AppCard(
                  gradient: AppColors.primaryGradient,
                  child: Column(
                    children: [
                      Text(
                        'ROUND $_currentRound OF ${session.totalRounds}',
                        style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 12),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 90,
                            height: 90,
                            child: CircularProgressIndicator(
                              value: _timerSeconds / (session.type == GameType.rapidFire ? 10 : 15),
                              strokeWidth: 7,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                            ),
                          ),
                          Text(
                            '$_timerSeconds s',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // DYNAMIC GAME-TYPE SPECIFIC HOST DISPLAY
                      _buildGameSpecificHostContent(session),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // HOST CONTROL BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        text: _isLive
                            ? (_currentRound < session.totalRounds ? 'Next Round →' : 'Final Round Completed 🎉')
                            : 'Start Round 🚀',
                        onPressed: _isLive
                            ? (_currentRound < session.totalRounds ? () => _nextRound(session.totalRounds) : null)
                            : () => _startRound(session),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SecondaryButton(
                        text: 'End & Declare Winners 🏆',
                        onPressed: () => _finishGame(session),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // PARTICIPANTS SCOREBOARD / HOST ADJUSTER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('LIVE LEADERBOARD', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2)),
                    TextButton.icon(
                      icon: const Icon(Icons.phone_iphone, size: 16),
                      label: const Text('Open Player View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => context.push('/player-game/${widget.gameId}'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                AppCard(
                  child: Column(
                    children: _playerScores.entries.map((entry) {
                      final name = _playerNames[entry.key] ?? entry.key;
                      return ListTile(
                        leading: MemberAvatar(name: name),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (session.type == GameType.custom) ...[
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                                onPressed: () => _adjustScore(entry.key, -10),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppColors.success, size: 20),
                                onPressed: () => _adjustScore(entry.key, 10),
                              ),
                            ],
                            Text(
                              '${entry.value} pts',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameSpecificHostContent(GameSessionModel session) {
    switch (session.type) {
      case GameType.luckyDraw:
        final participants = LuckyDrawGame.defaultParticipants;
        return Column(
          children: [
            const Text('🎁 LUCKY DRAW WHEEL', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(participants.length, (idx) {
                final isSelected = _highlightedIndex == idx;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.gold : Colors.white12,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    participants[idx],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            if (_luckyWinner != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎉 WINNER: ', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(_luckyWinner!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton.icon(
              onPressed: _spinLuckyDraw,
              icon: const Icon(Icons.casino),
              label: Text(_isSpinning ? 'Spinning...' : 'Spin Lucky Draw Wheel 🎲'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        );

      case GameType.bollywoodQuiz:
        final roundIdx = (_currentRound - 1) % BollywoodQuizGame.questions.length;
        final q = BollywoodQuizGame.questions[roundIdx];
        return Column(
          children: [
            Text(
              'Q$_currentRound: ${q['question']}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Column(
              children: List.generate((q['options'] as List).length, (idx) {
                final isCorrect = idx == q['correct'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCorrect ? AppColors.success.withValues(alpha: 0.3) : Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text('${String.fromCharCode(65 + idx)}. ', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      Expanded(child: Text(q['options'][idx], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                      if (isCorrect) const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                    ],
                  ),
                );
              }),
            ),
          ],
        );

      case GameType.memoryChallenge:
        return Column(
          children: [
            const Text('🧠 MEMORY GRID (Memorize for 10s)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: MemoryChallengeGame.targetItems
                  .map((e) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                        child: Text(e, style: const TextStyle(fontSize: 24)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            const Text('Players must recall these 6 emojis correctly!', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        );

      case GameType.emojiGuess:
        final puzzleIdx = (_currentRound - 1) % EmojiGuessGame.emojiPuzzles.length;
        final p = EmojiGuessGame.emojiPuzzles[puzzleIdx];
        return Column(
          children: [
            const Text('DECODE EMOJI PUZZLE', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(p['emojis'], style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 10),
            Text('Correct Answer: ${p['answer']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        );

      case GameType.guessSong:
        final clueIdx = (_currentRound - 1) % GuessTheSongGame.songClues.length;
        final c = GuessTheSongGame.songClues[clueIdx];
        return Column(
          children: [
            const Text('LYRIC CLUE 🎵', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(c['lyrics'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            Text('Song Title: ${c['songTitle']}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        );

      case GameType.rapidFire:
        final qIdx = (_currentRound - 1) % RapidFireGame.rapidFireQuestions.length;
        final rf = RapidFireGame.rapidFireQuestions[qIdx];
        return Column(
          children: [
            const Text('⚡ THIS OR THAT', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(rf['prompt']!, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Chip(label: Text(rf['optionA']!, style: const TextStyle(fontWeight: FontWeight.bold))),
                const Text('VS', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                Chip(label: Text(rf['optionB']!, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ],
        );

      case GameType.wordChallenge:
        final wIdx = (_currentRound - 1) % WordChallengeGame.wordPuzzles.length;
        final wp = WordChallengeGame.wordPuzzles[wIdx];
        return Column(
          children: [
            const Text('🔤 UNSCRAMBLE WORD', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(wp['scrambled'], style: const TextStyle(fontSize: 28, letterSpacing: 3, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            Text('Answer: ${wp['answer']}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        );

      case GameType.targetChallenge:
        return const Column(
          children: [
            Text('🎯 TARGET SCORE COMPETITION', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Target: 150 Points', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 8),
            Text('Players tap bullseye target on their device to earn points!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        );

      case GameType.custom:
        return const Column(
          children: [
            Text('🛠️ CUSTOM HOST MANAGED GAME', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Use host control buttons below to add/remove points!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 14)),
          ],
        );
    }
  }
}
