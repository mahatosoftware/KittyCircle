import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (_) {
      // Gracefully silent in offline or uninitialized environments
    }
  }

  static Future<void> logSignUp(String method) => logEvent('signup', {'method': method});
  static Future<void> logProfileCompleted() => logEvent('profile_completed');
  static Future<void> logGroupCreated(String groupId) => logEvent('group_created', {'group_id': groupId});
  static Future<void> logGroupJoined(String groupId) => logEvent('group_joined', {'group_id': groupId});
  static Future<void> logMemberInvited() => logEvent('member_invited');
  static Future<void> logEventCreated(String eventId) => logEvent('event_created', {'event_id': eventId});
  static Future<void> logEventRsvp(String status) => logEvent('event_rsvp', {'status': status});
  static Future<void> logEventStarted(String eventId) => logEvent('event_started', {'event_id': eventId});
  static Future<void> logEventCompleted(String eventId) => logEvent('event_completed', {'event_id': eventId});
  static Future<void> logGameStarted(String gameType) => logEvent('game_started', {'game_type': gameType});
  static Future<void> logGameCompleted(String gameType) => logEvent('game_completed', {'game_type': gameType});
  static Future<void> logGameParticipated(String gameId) => logEvent('game_participated', {'game_id': gameId});
  static Future<void> logWinnerDeclared(String rank) => logEvent('winner_declared', {'rank': rank});
  static Future<void> logMemoryUploaded() => logEvent('memory_uploaded');
  static Future<void> logWhatsAppShare(String type) => logEvent('whatsapp_share', {'type': type});
  static Future<void> logContributionMarked(String status) => logEvent('contribution_marked', {'status': status});
  static Future<void> logExpenseCreated(String category) => logEvent('expense_created', {'category': category});
}
