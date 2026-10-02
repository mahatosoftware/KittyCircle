import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../domain/game_models.dart';
import '../../../core/constants/app_constants.dart';

class GameRepository {
  final FirebaseFirestore? _firestore;

  final Map<String, GameSessionModel> _sessionStore = {};
  final Map<String, List<GameParticipantModel>> _participantStore = {};
  final Map<String, List<WinnerModel>> _winnerStore = {};
  final Map<String, List<PrizeModel>> _prizeStore = {};

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
          _sessionStore.remove(gameId);
          yield null;
        }
      }
    } catch (e) {
      debugPrint('Error watching game session: $e');
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
      } catch (e) {
        debugPrint('Error creating game session in Firestore: $e');
      }
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
      } catch (e) {
        debugPrint('Error updating game session in Firestore: $e');
      }
    }
  }

  // Participants
  Stream<List<GameParticipantModel>> watchParticipants(String gameId) async* {
    yield _participantStore[gameId] ?? [];

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        final snapStream = db
            .collection(AppConstants.gamesCollection)
            .doc(gameId)
            .collection(AppConstants.participantsCollection)
            .snapshots();

        await for (final snap in snapStream) {
          final list = snap.docs.map((d) => GameParticipantModel.fromMap(d.data(), d.id)).toList();
          _participantStore[gameId] = list;
          yield list;
        }
      } catch (e) {
        debugPrint('Error watching participants: $e');
        yield _participantStore[gameId] ?? [];
      }
    }
  }

  Future<void> joinGameSession(String gameId, String userId, String displayName, {String? photoUrl}) async {
    final p = GameParticipantModel(userId: userId, gameId: gameId, displayName: displayName, photoUrl: photoUrl);
    final list = _participantStore.putIfAbsent(gameId, () => []);
    if (!list.any((item) => item.userId == userId)) {
      list.add(p);
    }

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db
            .collection(AppConstants.gamesCollection)
            .doc(gameId)
            .collection(AppConstants.participantsCollection)
            .doc(userId)
            .set(p.toMap());
      } catch (e) {
        debugPrint('Error joining game session in Firestore: $e');
      }
    }
  }

  // Winners
  Stream<List<WinnerModel>> watchEventWinners(String eventId) async* {
    yield _winnerStore[eventId] ?? [];

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        final snapStream = db
            .collection(AppConstants.winnersCollection)
            .where('eventId', isEqualTo: eventId)
            .snapshots();

        await for (final snap in snapStream) {
          final list = snap.docs.map((d) => WinnerModel.fromMap(d.data(), d.id)).toList();
          _winnerStore[eventId] = list;
          yield list;
        }
      } catch (e) {
        debugPrint('Error watching winners: $e');
        yield _winnerStore[eventId] ?? [];
      }
    }
  }

  Future<void> saveWinners(String eventId, List<WinnerModel> winners) async {
    _winnerStore[eventId] = winners;

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        final batch = db.batch();
        for (final w in winners) {
          final docRef = db.collection(AppConstants.winnersCollection).doc('${eventId}_${w.playerId}');
          batch.set(docRef, w.toMap());
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Error saving winners to Firestore: $e');
      }
    }
  }

  // Prizes
  Stream<List<PrizeModel>> watchEventPrizes(String eventId) async* {
    yield _prizeStore[eventId] ?? [];

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        final snapStream = db
            .collection('prizes')
            .where('eventId', isEqualTo: eventId)
            .snapshots();

        await for (final snap in snapStream) {
          final list = snap.docs.map((d) => PrizeModel.fromMap(d.data(), d.id)).toList();
          _prizeStore[eventId] = list;
          yield list;
        }
      } catch (e) {
        debugPrint('Error watching prizes: $e');
        yield _prizeStore[eventId] ?? [];
      }
    }
  }

  Future<void> addPrize(PrizeModel prize) async {
    _prizeStore.putIfAbsent(prize.eventId, () => []).add(prize);

    if (Firebase.apps.isNotEmpty || _firestore != null) {
      try {
        final db = _firestore ?? FirebaseFirestore.instance;
        await db.collection('prizes').doc(prize.prizeId).set(prize.toMap());
      } catch (e) {
        debugPrint('Error adding prize to Firestore: $e');
      }
    }
  }
}
