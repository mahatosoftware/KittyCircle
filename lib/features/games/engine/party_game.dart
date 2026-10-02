import 'dart:math';
import '../domain/game_models.dart';

abstract class PartyGame {
  String get id;
  String get name;
  String get description;
  GameType get type;
  GameSessionModel? get activeSession;

  Future<void> initialize(GameSessionModel session);
  Future<void> start();
  Future<void> pause();
  Future<void> resume();
  Future<void> nextRound();
  Future<void> end();
  Future<void> submitAnswer(String playerId, dynamic answer);
  Future<Map<String, int>> calculateScores();
}

/// 🎁 Lucky Draw Game Implementation
class LuckyDrawGame implements PartyGame {
  @override
  final String id = 'lucky_draw';
  @override
  final String name = 'Lucky Draw';
  @override
  final String description = 'Random winner selector for party treats and gifts!';
  @override
  final GameType type = GameType.luckyDraw;

  @override
  GameSessionModel? activeSession;
  final List<String> _participants = [];
  String? selectedWinner;
  final List<String> winnerHistory = [];

  static const List<String> defaultParticipants = [];

  @override
  Future<void> initialize(GameSessionModel session) async {
    activeSession = session;
    _participants.clear();
    selectedWinner = null;
  }

  void addParticipant(String userId) {
    if (!_participants.contains(userId)) {
      _participants.add(userId);
    }
  }

  List<String> get participants => List.unmodifiable(_participants);

  String? drawWinner() {
    if (_participants.isEmpty) return null;
    final random = Random();
    final index = random.nextInt(_participants.length);
    selectedWinner = _participants[index];
    winnerHistory.add(selectedWinner!);
    return selectedWinner;
  }

  @override
  Future<void> start() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> nextRound() async {
    drawWinner();
  }
  @override
  Future<void> end() async {}
  @override
  Future<void> submitAnswer(String playerId, dynamic answer) async {}
  @override
  Future<Map<String, int>> calculateScores() async {
    if (selectedWinner != null) {
      return {selectedWinner!: 100};
    }
    return {};
  }
}

/// 🧠 Memory Challenge Game Implementation
class MemoryChallengeGame implements PartyGame {
  @override
  final String id = 'memory_challenge';
  @override
  final String name = 'Memory Challenge';
  @override
  final String description = 'Memorize the items/emojis before they disappear!';
  @override
  final GameType type = GameType.memoryChallenge;

  @override
  GameSessionModel? activeSession;
  final Map<String, List<String>> playerAnswers = {};
  static const List<String> targetItems = ['🍎', '🍌', '🍊', '🌸', '⭐', '🎁'];
  static const List<String> questionOptions = ['🍎', '🍌', '🍊', '🌸', '⭐', '🎁', '🍇', '🍕'];

  @override
  Future<void> initialize(GameSessionModel session) async {
    activeSession = session;
    playerAnswers.clear();
  }

  @override
  Future<void> start() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> nextRound() async {}
  @override
  Future<void> end() async {}

  @override
  Future<void> submitAnswer(String playerId, dynamic answer) async {
    if (answer is String) {
      playerAnswers.putIfAbsent(playerId, () => []).add(answer);
    } else if (answer is List<String>) {
      playerAnswers[playerId] = List.from(answer);
    }
  }

  @override
  Future<Map<String, int>> calculateScores() async {
    final Map<String, int> scores = {};
    playerAnswers.forEach((player, answers) {
      int score = 0;
      for (final a in answers) {
        if (targetItems.contains(a)) {
          score += 20;
        }
      }
      scores[player] = score;
    });
    return scores;
  }
}

/// 🎬 Bollywood Quiz Game Implementation
class BollywoodQuizGame implements PartyGame {
  @override
  final String id = 'bollywood_quiz';
  @override
  final String name = 'Bollywood Quiz';
  @override
  final String description = 'Fun movie trivia and timed questions!';
  @override
  final GameType type = GameType.bollywoodQuiz;

  @override
  GameSessionModel? activeSession;
  final Map<String, Map<int, String>> playerRoundAnswers = {}; // userId -> {round: option}

  static const List<Map<String, dynamic>> questions = [
    {
      'question': 'Which film features the song "Shava Shava"?',
      'options': ['Kabhi Khushi Kabhie Gham', 'DDLJ', 'Kuch Kuch Hota Hai', 'Main Hoon Na'],
      'correct': 0,
    },
    {
      'question': 'Who directed "Dil Chahta Hai"?',
      'options': ['Karan Johar', 'Farhan Akhtar', 'Zoya Akhtar', 'Sanjay Leela Bhansali'],
      'correct': 1,
    },
    {
      'question': 'Complete the dialogue: "Mogambo ___ hua!"',
      'options': ['Khush', 'Dukhi', 'Gussa', 'Pareshaan'],
      'correct': 0,
    },
  ];

  @override
  Future<void> initialize(GameSessionModel session) async {
    activeSession = session;
    playerRoundAnswers.clear();
  }

  @override
  Future<void> start() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> nextRound() async {}
  @override
  Future<void> end() async {}

  @override
  Future<void> submitAnswer(String playerId, dynamic answer) async {
    if (answer is Map) {
      final round = answer['round'] as int;
      final option = answer['option'] as String;
      playerRoundAnswers.putIfAbsent(playerId, () => {})[round] = option;
    }
  }

  @override
  Future<Map<String, int>> calculateScores() async {
    final Map<String, int> scores = {};
    playerRoundAnswers.forEach((player, roundMap) {
      int score = 0;
      roundMap.forEach((roundIndex, chosenOption) {
        if (roundIndex < questions.length) {
          final correctOptIndex = questions[roundIndex]['correct'] as int;
          final correctOptionText = questions[roundIndex]['options'][correctOptIndex];
          if (chosenOption == correctOptionText) {
            score += 30; // 30 pts per correct answer
          }
        }
      });
      scores[player] = score;
    });
    return scores;
  }
}

/// 😀 Emoji Guess Game Implementation
class EmojiGuessGame implements PartyGame {
  @override
  final String id = 'emoji_guess';
  @override
  final String name = 'Emoji Guess';
  @override
  final String description = 'Guess the movie, song or phrase from emojis!';
  @override
  final GameType type = GameType.emojiGuess;

  @override
  GameSessionModel? activeSession;
  final Map<String, String> playerGuesses = {};

  static const List<Map<String, dynamic>> emojiPuzzles = [
    {
      'emojis': '👑 ❤️ 🚂',
      'answer': 'Dilwale Dulhania Le Jayenge',
      'options': ['Dilwale Dulhania Le Jayenge', 'Jab We Met', 'Kabhi Khushi Kabhie Gham', 'Chennai Express'],
      'correct': 0,
    },
    {
      'emojis': '3️⃣ 🤓 🏫',
      'answer': '3 Idiots',
      'options': ['Chhichhore', '3 Idiots', 'Taare Zameen Par', 'Student of the Year'],
      'correct': 1,
    },
    {
      'emojis': '🦁 👑',
      'answer': 'The Lion King',
      'options': ['Jungle Book', 'Madagascar', 'The Lion King', 'Kung Fu Panda'],
      'correct': 2,
    },
  ];

  @override
  Future<void> initialize(GameSessionModel session) async {
    activeSession = session;
    playerGuesses.clear();
  }

  @override
  Future<void> start() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> nextRound() async {}
  @override
  Future<void> end() async {}

  @override
  Future<void> submitAnswer(String playerId, dynamic answer) async {
    if (answer is String) {
      playerGuesses[playerId] = answer;
    }
  }

  @override
  Future<Map<String, int>> calculateScores() async {
    final Map<String, int> scores = {};
    playerGuesses.forEach((player, guess) {
      if (guess.trim().isNotEmpty) {
        scores[player] = 25;
      }
    });
    return scores;
  }
}

/// 🎵 Guess the Song Implementation
class GuessTheSongGame implements PartyGame {
  @override
  final String id = 'guess_song';
  @override
  final String name = 'Guess the Song';
  @override
  final String description = 'Listen to lyrics/clues and name that song!';
  @override
  final GameType type = GameType.guessSong;

  @override
  GameSessionModel? activeSession;
  final Map<String, String> playerGuesses = {};

  static const List<Map<String, dynamic>> songClues = [
    {
      'lyrics': '🎶 "Tujhe dekha toh yeh jana sanam... pyaar hota hai deewana sanam"',
      'songTitle': 'Tujhe Dekha Toh',
      'options': ['Tujhe Dekha Toh', 'Yeh Ladka Hai Deewana', 'Pehla Nasha', 'Tum Hi Ho'],
      'correct': 0,
    },
    {
      'lyrics': '🎶 "Channa mereya mereya... beliya o piya"',
      'songTitle': 'Channa Mereya',
      'options': ['Kabira', 'Channa Mereya', 'Ae Dil Hai Mushkil', 'Kal Ho Naa Ho'],
      'correct': 1,
    },
    {
      'lyrics': '🎶 "Kesariya tera ishq hai piya... rang jaun jo main haath lagaun"',
      'songTitle': 'Kesariya',
      'options': ['Apna Bana Le', 'Tere Vaaste', 'Kesariya', 'Deva Deva'],
      'correct': 2,
    },
  ];

  @override
  Future<void> initialize(GameSessionModel session) async {
    activeSession = session;
    playerGuesses.clear();
  }

  @override
  Future<void> start() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> nextRound() async {}
  @override
  Future<void> end() async {}

  @override
  Future<void> submitAnswer(String playerId, dynamic answer) async {
    if (answer is String) {
      playerGuesses[playerId] = answer;
    }
  }

  @override
  Future<Map<String, int>> calculateScores() async {
    final Map<String, int> scores = {};
    playerGuesses.forEach((player, guess) {
      if (guess.trim().isNotEmpty) {
        scores[player] = 30;
      }
    });
    return scores;
  }
}

/// ⚡ Rapid Fire Game Implementation
class RapidFireGame implements PartyGame {
  @override
  final String id = 'rapid_fire';
  @override
  final String name = 'Rapid Fire';
  @override
  final String description = 'Quick This-or-That questions to break the ice!';
  @override
  final GameType type = GameType.rapidFire;

  @override
  GameSessionModel? activeSession;
  final Map<String, List<String>> playerResponses = {};

  static const List<Map<String, String>> rapidFireQuestions = [
    {
      'prompt': 'Tea or Coffee preference?',
      'optionA': 'Chai ☕',
      'optionB': 'Coffee ☕',
    },
    {
      'prompt': 'Vacation Choice?',
      'optionA': 'Beach Resort 🏖️',
      'optionB': 'Mountain Cabin 🏔️',
    },
    {
      'prompt': 'Street Food Pick?',
      'optionA': 'Samosa 🥟',
      'optionB': 'Pani Puri 🍲',
    },
    {
      'prompt': 'Entertainment Pick?',
      'optionA': 'Bollywood Movie 🎬',
      'optionB': 'Binge Web Series 📺',
    },
    {
      'prompt': 'Pamper Session?',
      'optionA': 'Shopping Spree 🛍️',
      'optionB': 'Relaxing Spa 💆‍♀️',
    },
  ];

  @override
  Future<void> initialize(GameSessionModel session) async {
    activeSession = session;
    playerResponses.clear();
  }

  @override
  Future<void> start() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> nextRound() async {}
  @override
  Future<void> end() async {}

  @override
  Future<void> submitAnswer(String playerId, dynamic answer) async {
    if (answer is String) {
      playerResponses.putIfAbsent(playerId, () => []).add(answer);
    }
  }

  @override
  Future<Map<String, int>> calculateScores() async {
    final Map<String, int> scores = {};
    playerResponses.forEach((player, answers) {
      scores[player] = answers.length * 10;
    });
    return scores;
  }
}

/// 🔤 Word Challenge Game Implementation
class WordChallengeGame implements PartyGame {
  @override
  final String id = 'word_challenge';
  @override
  final String name = 'Word Challenge';
  @override
  final String description = 'Unscramble words and solve word puzzles!';
  @override
  final GameType type = GameType.wordChallenge;

  @override
  GameSessionModel? activeSession;
  final Map<String, String> playerAnswers = {};

  static const List<Map<String, dynamic>> wordPuzzles = [
    {
      'scrambled': 'N B I A Y I R',
      'answer': 'BIRYANI',
      'options': ['BIRYANI', 'BIRYANA', 'BARIYNI', 'BURAYNI'],
      'correct': 0,
    },
    {
      'scrambled': 'Y T T K I',
      'answer': 'KITTY',
      'options': ['KITYY', 'KITTY', 'TIKYT', 'KTYTI'],
      'correct': 1,
    },
    {
      'scrambled': 'B O L L Y W O O D',
      'answer': 'BOLLYWOOD',
      'options': ['BOLLYWOOD', 'BOLLYWOAD', 'BULLYWOOD', 'BOLLYWOODS'],
      'correct': 0,
    },
  ];

  @override
  Future<void> initialize(GameSessionModel session) async {
    activeSession = session;
    playerAnswers.clear();
  }

  @override
  Future<void> start() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> nextRound() async {}
  @override
  Future<void> end() async {}

  @override
  Future<void> submitAnswer(String playerId, dynamic answer) async {
    if (answer is String) {
      playerAnswers[playerId] = answer;
    }
  }

  @override
  Future<Map<String, int>> calculateScores() async {
    final Map<String, int> scores = {};
    playerAnswers.forEach((player, ans) {
      if (ans.trim().isNotEmpty) {
        scores[player] = 20;
      }
    });
    return scores;
  }
}

/// 🎯 Target Challenge Implementation
class TargetChallengeGame implements PartyGame {
  @override
  final String id = 'target_challenge';
  @override
  final String name = 'Target Challenge';
  @override
  final String description = 'Compete for the highest target score!';
  @override
  final GameType type = GameType.targetChallenge;

  @override
  GameSessionModel? activeSession;
  final Map<String, int> playerScores = {};

  @override
  Future<void> initialize(GameSessionModel session) async {
    activeSession = session;
    playerScores.clear();
  }

  @override
  Future<void> start() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> nextRound() async {}
  @override
  Future<void> end() async {}

  @override
  Future<void> submitAnswer(String playerId, dynamic answer) async {
    if (answer is int) {
      playerScores[playerId] = (playerScores[playerId] ?? 0) + answer;
    }
  }

  @override
  Future<Map<String, int>> calculateScores() async => playerScores;
}

/// 🛠️ Custom Game Implementation
class CustomGame implements PartyGame {
  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final GameType type = GameType.custom;

  @override
  GameSessionModel? activeSession;
  final Map<String, int> manualScores = {};

  CustomGame({
    required this.id,
    required this.name,
    required this.description,
  });

  @override
  Future<void> initialize(GameSessionModel session) async {
    activeSession = session;
    manualScores.clear();
  }

  @override
  Future<void> start() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> nextRound() async {}
  @override
  Future<void> end() async {}

  @override
  Future<void> submitAnswer(String playerId, dynamic answer) async {
    if (answer is int) {
      manualScores[playerId] = answer;
    }
  }

  @override
  Future<Map<String, int>> calculateScores() async => manualScores;
}
