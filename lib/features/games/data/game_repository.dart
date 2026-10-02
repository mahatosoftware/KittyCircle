import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../domain/game_models.dart';
import '../../../core/constants/app_constants.dart';

class GameRepository {
  final FirebaseFirestore? _firestore;

  final Map<String, GameSessionModel> _sessionStore = {};
  final Map<String, List<GameParticipantModel>> _participantStore = {};
  final Map<String, List<WinnerModel>> _winnerStore = {
    'event_oct_18': [
      WinnerModel(
        winnerId: 'w1',
        eventId: 'event_oct_18',
        gameId: 'game_bolly_1',
        gameName: 'Bollywood Quiz',
        playerId: 'user_priya_1',
        playerName: 'Priya Sharma',
        rank: 1,
        score: 90,
        prizeName: 'Luxury Gift Hamper',
        prizeValue: 1000,
      ),
      WinnerModel(
        winnerId: 'w2',
        eventId: 'event_oct_18',
        gameId: 'game_mem_1',
        gameName: 'Memory Challenge',
        playerId: 'user_neha_2',
        playerName: 'Neha Gupta',
        rank: 2,
        score: 80,
        prizeName: 'Chocolate Box',
        prizeValue: 500,
      ),
      WinnerModel(
        winnerId: 'w3',
        eventId: 'event_oct_18',
        gameId: 'game_lucky_1',
        gameName: 'Lucky Draw',
        playerId: 'user_kavita_3',
        playerName: 'Kavita Verma',
        rank: 3,
        score: 75,
        prizeName: 'Scented Candle Set',
        prizeValue: 350,
      ),
    ]
  };

  final Map<String, List<PrizeModel>> _prizeStore = {
    'event_oct_18': [
      PrizeModel(prizeId: 'p1', eventId: 'event_oct_18', name: 'Luxury Gift Hamper', value: 1000, winnerId: 'user_priya_1', winnerName: 'Priya'),
      PrizeModel(prizeId: 'p2', eventId: 'event_oct_18', name: 'Chocolate Box', value: 500, winnerId: 'user_neha_2', winnerName: 'Neha'),
      PrizeModel(prizeId: 'p3', eventId: 'event_oct_18', name: 'Scented Candle Set', value: 350, winnerId: 'user_kavita_3', winnerName: 'Kavita'),
    ]
  };

  GameRepository({this._firestore});

  Stream<GameSessionModel?> watchGameSession(String gameId) async* {
    yield _sessionStore[gameId];

    if (Firebase.apps.isEmpty && _firestore == null) return;

    try {
      final db = _firestore ?? FirebaseFirestore.instance;
      final stream = db
          .collection(AppConstants.gamesCollection)
          .doc(gameId)
          .snapshots();

      await for (final snap in stream) {
        if (snap.exists && snap.data() != null) {
          final model = GameSessionModel.fromMap(snap.data()!, snap.id);
          _sessionStore[gameId] = model;
          yield model;
        } else {
          yield _sessionStore[gameId];
        }
      }
    } catch (_) {
      yield _sessionStore[gameId];
    }
  }

  Future<GameSessionModel> createGameSession({
    required String eventId,
    required String groupId,
    required String gameName,
    required GameType type,
    required String hostUserId,
    int totalRounds = 3,
  }) async {
    final gameId = 'game_${DateTime.now().millisecondsSinceEpoch}';
    final session = GameSessionModel(
      gameId: gameId,
      eventId: eventId,
      groupId: groupId,
      gameName: gameName,
      type: type,
      hostUserId: hostUserId,
      totalRounds: totalRounds,
    );

    _sessionStore[gameId] = session;

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.gamesCollection)
            .doc(gameId)
            .set(session.toMap());
      } catch (_) {}
    }

    return session;
  }

  Future<void> updateGameSession(GameSessionModel session) async {
    _sessionStore[session.gameId] = session;

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.gamesCollection)
            .doc(session.gameId)
            .set(session.toMap(), SetOptions(merge: true));
      } catch (_) {}
    }
  }

  // Participants
  Stream<List<GameParticipantModel>> watchParticipants(String gameId) async* {
    yield _participantStore[gameId] ?? [];
  }

  Future<void> joinGameSession(String gameId, String userId, String displayName, {String? photoUrl}) async {
    final list = _participantStore.putIfAbsent(gameId, () => []);
    if (!list.any((p) => p.userId == userId)) {
      final p = GameParticipantModel(userId: userId, gameId: gameId, displayName: displayName, photoUrl: photoUrl);
      list.add(p);
    }
  }

  // Winners
  Stream<List<WinnerModel>> watchEventWinners(String eventId) async* {
    yield _winnerStore[eventId] ?? [];
  }

  Future<void> saveWinners(String eventId, List<WinnerModel> winners) async {
    final existing = _winnerStore.putIfAbsent(eventId, () => []);
    existing.addAll(winners);
  }

  // Prizes
  Stream<List<PrizeModel>> watchEventPrizes(String eventId) async* {
    yield _prizeStore[eventId] ?? [];
  }

  Future<void> addPrize(PrizeModel prize) async {
    _prizeStore.putIfAbsent(prize.eventId, () => []).add(prize);
  }
}
