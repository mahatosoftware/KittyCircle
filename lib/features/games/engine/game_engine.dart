import '../domain/game_models.dart';
import 'party_game.dart';

class GameEngine {
  GameEngine._();

  static const List<GameDefinition> availableGames = [
    GameDefinition(
      id: 'lucky_draw',
      name: '🎁 Lucky Draw',
      description: 'Random winner generator for party gifts & treats!',
      type: GameType.luckyDraw,
      iconEmoji: '🎁',
      defaultRounds: 1,
      defaultDurationSeconds: 10,
      rules: 'Select participants and spin the wheel or draw to pick a lucky winner!',
    ),
    GameDefinition(
      id: 'bollywood_quiz',
      name: '🎬 Bollywood Quiz',
      description: 'Trivia quiz on classic & modern Hindi cinema!',
      type: GameType.bollywoodQuiz,
      iconEmoji: '🎬',
      defaultRounds: 3,
      defaultDurationSeconds: 20,
      rules: 'Answer the multiple-choice questions before timer runs out. Speed gives bonus points!',
    ),
    GameDefinition(
      id: 'memory_challenge',
      name: '🧠 Memory Challenge',
      description: 'Memorize objects and answer before they vanish!',
      type: GameType.memoryChallenge,
      iconEmoji: '🧠',
      defaultRounds: 3,
      defaultDurationSeconds: 15,
      rules: 'Examine the shown grid of emojis for 10 seconds, then identify which ones were displayed!',
    ),
    GameDefinition(
      id: 'emoji_guess',
      name: '😀 Emoji Guess',
      description: 'Decode movies, songs, and celebrities from emoji clues!',
      type: GameType.emojiGuess,
      iconEmoji: '😀',
      defaultRounds: 3,
      defaultDurationSeconds: 30,
      rules: 'Type or choose the correct movie or song title represented by the emoji combination!',
    ),
    GameDefinition(
      id: 'guess_song',
      name: '🎵 Guess the Song',
      description: 'Host provides song lyrics or melody clues to identify!',
      type: GameType.guessSong,
      iconEmoji: '🎵',
      defaultRounds: 3,
      defaultDurationSeconds: 25,
      rules: 'Listen to the host clue or lyrics line and guess the song name!',
    ),
    GameDefinition(
      id: 'rapid_fire',
      name: '⚡ Rapid Fire',
      description: 'Fast-paced This-or-That party questions!',
      type: GameType.rapidFire,
      iconEmoji: '⚡',
      defaultRounds: 5,
      defaultDurationSeconds: 10,
      rules: 'Pick your preference instantly between two options!',
    ),
    GameDefinition(
      id: 'word_challenge',
      name: '🔤 Word Challenge',
      description: 'Unscramble words and solve party word chains!',
      type: GameType.wordChallenge,
      iconEmoji: '🔤',
      defaultRounds: 3,
      defaultDurationSeconds: 20,
      rules: 'Unscramble the jumbled letter string into a valid theme word!',
    ),
    GameDefinition(
      id: 'target_challenge',
      name: '🎯 Target Challenge',
      description: 'Target score competition for all players!',
      type: GameType.targetChallenge,
      iconEmoji: '🎯',
      defaultRounds: 3,
      defaultDurationSeconds: 15,
      rules: 'Perform the action to earn points aiming for the target score!',
    ),
  ];

  static PartyGame createGameInstance(GameType type, {String? customId, String? customName, String? customDesc}) {
    switch (type) {
      case GameType.luckyDraw:
        return LuckyDrawGame();
      case GameType.memoryChallenge:
        return MemoryChallengeGame();
      case GameType.bollywoodQuiz:
        return BollywoodQuizGame();
      case GameType.emojiGuess:
        return EmojiGuessGame();
      case GameType.guessSong:
        return GuessTheSongGame();
      case GameType.rapidFire:
        return RapidFireGame();
      case GameType.wordChallenge:
        return WordChallengeGame();
      case GameType.targetChallenge:
        return TargetChallengeGame();
      case GameType.custom:
        return CustomGame(
          id: customId ?? 'custom_game',
          name: customName ?? 'Custom Party Game',
          description: customDesc ?? 'Host managed custom game',
        );
    }
  }

  /// Convert score map into ordered WinnerModel list
  static List<WinnerModel> computeWinners({
    required String eventId,
    required String gameId,
    required String gameName,
    required Map<String, int> scores,
    required Map<String, GameParticipantModel> participantMap,
    List<PrizeModel>? prizes,
  }) {
    final sortedEntries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<WinnerModel> winners = [];
    for (int i = 0; i < sortedEntries.length && i < 3; i++) {
      final entry = sortedEntries[i];
      final playerId = entry.key;
      final score = entry.value;
      final participant = participantMap[playerId];
      final prize = (prizes != null && i < prizes.length) ? prizes[i] : null;

      winners.add(
        WinnerModel(
          winnerId: '${gameId}_winner_${i + 1}',
          eventId: eventId,
          gameId: gameId,
          gameName: gameName,
          playerId: playerId,
          playerName: participant?.displayName ?? 'Player',
          playerPhotoUrl: participant?.photoUrl,
          rank: i + 1,
          score: score,
          prizeName: prize?.name ?? '',
          prizeValue: prize?.value ?? 0.0,
        ),
      );
    }
    return winners;
  }
}
