import 'package:cloud_firestore/cloud_firestore.dart';

enum GameType {
  luckyDraw,
  memoryChallenge,
  bollywoodQuiz,
  emojiGuess,
  guessSong,
  rapidFire,
  wordChallenge,
  targetChallenge,
  custom
}

enum GameSessionStatus { ready, live, paused, completed, cancelled }

enum ScoringMethod { manual, highestWins, lowestWins, firstPlacePoints, customPoints }

class GameDefinition {
  final String id;
  final String name;
  final String description;
  final GameType type;
  final String iconEmoji;
  final int defaultRounds;
  final int defaultDurationSeconds;
  final ScoringMethod scoringMethod;
  final String rules;

  const GameDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.iconEmoji,
    this.defaultRounds = 3,
    this.defaultDurationSeconds = 15,
    this.scoringMethod = ScoringMethod.highestWins,
    this.rules = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'iconEmoji': iconEmoji,
      'defaultRounds': defaultRounds,
      'defaultDurationSeconds': defaultDurationSeconds,
      'scoringMethod': scoringMethod.name,
      'rules': rules,
    };
  }

  factory GameDefinition.fromMap(Map<String, dynamic> map) {
    return GameDefinition(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Party Game',
      description: map['description'] ?? '',
      type: GameType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => GameType.custom,
      ),
      iconEmoji: map['iconEmoji'] ?? '🎮',
      defaultRounds: map['defaultRounds'] ?? 3,
      defaultDurationSeconds: map['defaultDurationSeconds'] ?? 15,
      scoringMethod: ScoringMethod.values.firstWhere(
        (e) => e.name == map['scoringMethod'],
        orElse: () => ScoringMethod.highestWins,
      ),
      rules: map['rules'] ?? '',
    );
  }
}

class GameSessionModel {
  final String gameId;
  final String eventId;
  final String groupId;
  final String gameName;
  final GameType type;
  final GameSessionStatus status;
  final int currentRound;
  final int totalRounds;
  final int timeRemaining;
  final String? activeQuestionId;
  final String hostUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  GameSessionModel({
    required this.gameId,
    required this.eventId,
    required this.groupId,
    required this.gameName,
    required this.type,
    this.status = GameSessionStatus.ready,
    this.currentRound = 1,
    this.totalRounds = 3,
    this.timeRemaining = 15,
    this.activeQuestionId,
    required this.hostUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'gameId': gameId,
      'eventId': eventId,
      'groupId': groupId,
      'gameName': gameName,
      'type': type.name,
      'status': status.name,
      'currentRound': currentRound,
      'totalRounds': totalRounds,
      'timeRemaining': timeRemaining,
      'activeQuestionId': activeQuestionId,
      'hostUserId': hostUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory GameSessionModel.fromMap(Map<String, dynamic> map, String id) {
    return GameSessionModel(
      gameId: id,
      eventId: map['eventId'] ?? '',
      groupId: map['groupId'] ?? '',
      gameName: map['gameName'] ?? 'Party Game',
      type: GameType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => GameType.custom,
      ),
      status: GameSessionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => GameSessionStatus.ready,
      ),
      currentRound: map['currentRound'] ?? 1,
      totalRounds: map['totalRounds'] ?? 3,
      timeRemaining: map['timeRemaining'] ?? 15,
      activeQuestionId: map['activeQuestionId'],
      hostUserId: map['hostUserId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  GameSessionModel copyWith({
    GameSessionStatus? status,
    int? currentRound,
    int? totalRounds,
    int? timeRemaining,
    String? activeQuestionId,
  }) {
    return GameSessionModel(
      gameId: gameId,
      eventId: eventId,
      groupId: groupId,
      gameName: gameName,
      type: type,
      status: status ?? this.status,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      activeQuestionId: activeQuestionId ?? this.activeQuestionId,
      hostUserId: hostUserId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class GameParticipantModel {
  final String userId;
  final String gameId;
  final String displayName;
  final String? photoUrl;
  final int totalScore;

  GameParticipantModel({
    required this.userId,
    required this.gameId,
    required this.displayName,
    this.photoUrl,
    this.totalScore = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'gameId': gameId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'totalScore': totalScore,
    };
  }

  factory GameParticipantModel.fromMap(Map<String, dynamic> map, String id) {
    return GameParticipantModel(
      userId: id,
      gameId: map['gameId'] ?? '',
      displayName: map['displayName'] ?? 'Player',
      photoUrl: map['photoUrl'],
      totalScore: map['totalScore'] ?? 0,
    );
  }
}

class WinnerModel {
  final String winnerId;
  final String eventId;
  final String gameId;
  final String gameName;
  final String playerId;
  final String playerName;
  final String? playerPhotoUrl;
  final int rank; // 1 = 🥇, 2 = 🥈, 3 = 🥉
  final int score;
  final String prizeName;
  final double prizeValue;
  final DateTime createdAt;

  WinnerModel({
    required this.winnerId,
    required this.eventId,
    required this.gameId,
    required this.gameName,
    required this.playerId,
    required this.playerName,
    this.playerPhotoUrl,
    required this.rank,
    required this.score,
    this.prizeName = '',
    this.prizeValue = 0.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get rankEmoji {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '#$rank';
  }

  Map<String, dynamic> toMap() {
    return {
      'winnerId': winnerId,
      'eventId': eventId,
      'gameId': gameId,
      'gameName': gameName,
      'playerId': playerId,
      'playerName': playerName,
      'playerPhotoUrl': playerPhotoUrl,
      'rank': rank,
      'score': score,
      'prizeName': prizeName,
      'prizeValue': prizeValue,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory WinnerModel.fromMap(Map<String, dynamic> map, String id) {
    return WinnerModel(
      winnerId: id,
      eventId: map['eventId'] ?? '',
      gameId: map['gameId'] ?? '',
      gameName: map['gameName'] ?? 'Game',
      playerId: map['playerId'] ?? '',
      playerName: map['playerName'] ?? 'Winner',
      playerPhotoUrl: map['playerPhotoUrl'],
      rank: map['rank'] ?? 1,
      score: map['score'] ?? 0,
      prizeName: map['prizeName'] ?? '',
      prizeValue: (map['prizeValue'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class PrizeModel {
  final String prizeId;
  final String eventId;
  final String name; // e.g. "Gift Hamper"
  final double value; // e.g. 1000
  final String? winnerId;
  final String? winnerName;

  PrizeModel({
    required this.prizeId,
    required this.eventId,
    required this.name,
    required this.value,
    this.winnerId,
    this.winnerName,
  });

  Map<String, dynamic> toMap() {
    return {
      'prizeId': prizeId,
      'eventId': eventId,
      'name': name,
      'value': value,
      'winnerId': winnerId,
      'winnerName': winnerName,
    };
  }

  factory PrizeModel.fromMap(Map<String, dynamic> map, String id) {
    return PrizeModel(
      prizeId: id,
      eventId: map['eventId'] ?? '',
      name: map['name'] ?? '',
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      winnerId: map['winnerId'],
      winnerName: map['winnerName'],
    );
  }
}
