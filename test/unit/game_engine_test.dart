import 'package:flutter_test/flutter_test.dart';
import 'package:kitty_circle/features/games/domain/game_models.dart';
import 'package:kitty_circle/features/games/engine/game_engine.dart';
import 'package:kitty_circle/features/games/engine/party_game.dart';

void main() {
  group('Party Games Engine Tests', () {
    test('Lucky Draw random selection', () {
      final luckyDraw = LuckyDrawGame();
      luckyDraw.addParticipant('user_priya_1');
      luckyDraw.addParticipant('user_neha_2');

      final winner = luckyDraw.drawWinner();
      expect(winner, isNotNull);
      expect(['user_priya_1', 'user_neha_2'], contains(winner));
    });

    test('Bollywood Quiz scoring calculation', () async {
      final quiz = BollywoodQuizGame();
      await quiz.submitAnswer('user_priya_1', {'round': 0, 'option': 'Kabhi Khushi Kabhie Gham'});
      await quiz.submitAnswer('user_priya_1', {'round': 1, 'option': 'Farhan Akhtar'});

      final scores = await quiz.calculateScores();
      expect(scores['user_priya_1'], equals(60));
    });

    test('Memory Challenge scoring calculation', () async {
      final memory = MemoryChallengeGame();
      await memory.submitAnswer('user_neha_2', ['🍎', '🍌', '🍊']);

      final scores = await memory.calculateScores();
      expect(scores['user_neha_2'], equals(60));
    });

    test('Emoji Guess & Rapid Fire scoring', () async {
      final emojiGame = EmojiGuessGame();
      await emojiGame.submitAnswer('user_priya_1', 'Dilwale Dulhania Le Jayenge');
      final emojiScores = await emojiGame.calculateScores();
      expect(emojiScores['user_priya_1'], equals(25));

      final rapidFire = RapidFireGame();
      await rapidFire.submitAnswer('user_priya_1', 'Chai ☕');
      await rapidFire.submitAnswer('user_priya_1', 'Samosa 🥟');
      final rapidScores = await rapidFire.calculateScores();
      expect(rapidScores['user_priya_1'], equals(20));
    });

    test('Target Challenge & Custom Game scoring', () async {
      final targetGame = TargetChallengeGame();
      await targetGame.submitAnswer('user_kavita_3', 50);
      await targetGame.submitAnswer('user_kavita_3', 30);
      final targetScores = await targetGame.calculateScores();
      expect(targetScores['user_kavita_3'], equals(80));

      final customGame = CustomGame(id: 'c1', name: 'Custom', description: 'Custom game');
      await customGame.submitAnswer('user_ritu_4', 100);
      final customScores = await customGame.calculateScores();
      expect(customScores['user_ritu_4'], equals(100));
    });

    test('GameEngine winner rank computation', () {
      final scores = {
        'user_priya_1': 90,
        'user_neha_2': 80,
        'user_kavita_3': 70,
      };

      final participantMap = {
        'user_priya_1': GameParticipantModel(userId: 'user_priya_1', gameId: 'g1', displayName: 'Priya'),
        'user_neha_2': GameParticipantModel(userId: 'user_neha_2', gameId: 'g1', displayName: 'Neha'),
        'user_kavita_3': GameParticipantModel(userId: 'user_kavita_3', gameId: 'g1', displayName: 'Kavita'),
      };

      final winners = GameEngine.computeWinners(
        eventId: 'event_1',
        gameId: 'g1',
        gameName: 'Bollywood Quiz',
        scores: scores,
        participantMap: participantMap,
      );

      expect(winners.length, equals(3));
      expect(winners[0].rank, equals(1));
      expect(winners[0].playerName, equals('Priya'));
      expect(winners[1].rank, equals(2));
      expect(winners[1].playerName, equals('Neha'));
      expect(winners[2].rank, equals(3));
      expect(winners[2].playerName, equals('Kavita'));
    });
  });
}
