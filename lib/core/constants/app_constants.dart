class AppConstants {
  AppConstants._();

  static const String appName = 'Kitty Circle';
  static const String appTagline = 'Kitty Circle — Plan. Play. Celebrate.';

  // Deep Link Prefix
  static const String deepLinkDomain = 'kittycircle.app';
  static const String deepLinkScheme = 'kittycircle';

  // Collection names
  static const String usersCollection = 'users';
  static const String groupsCollection = 'groups';
  static const String membersCollection = 'members';
  static const String eventsCollection = 'events';
  static const String rsvpsCollection = 'rsvps';
  static const String attendanceCollection = 'attendance';
  static const String gamesCollection = 'games';
  static const String participantsCollection = 'participants';
  static const String roundsCollection = 'rounds';
  static const String scoresCollection = 'scores';
  static const String resultsCollection = 'results';
  static const String winnersCollection = 'winners';
  static const String contributionsCollection = 'contributions';
  static const String expensesCollection = 'expenses';
  static const String memoriesCollection = 'memories';
  static const String hostScheduleCollection = 'hostSchedule';
  static const String potluckCollection = 'potluck';
  static const String timelineCollection = 'timeline';

  // Supported Languages
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'hi', 'name': 'Hindi (हिंदी)'},
    {'code': 'mr', 'name': 'Marathi (मराठी)'},
    {'code': 'gu', 'name': 'Gujarati (ગુજરાતી)'},
    {'code': 'pa', 'name': 'Punjabi (પંજાબી)'},
  ];

  // Default currencies
  static const String defaultCurrencySymbol = '₹';
  static const String defaultCurrencyCode = 'INR';
}
