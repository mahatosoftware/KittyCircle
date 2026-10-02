import '../constants/app_constants.dart';

class DeepLinkService {
  DeepLinkService._();

  static String createGroupInviteLink(String groupId) {
    return 'https://${AppConstants.deepLinkDomain}/join/group/$groupId';
  }

  static String createEventLink(String eventId) {
    return 'https://${AppConstants.deepLinkDomain}/event/$eventId';
  }

  static String createGameLink(String gameId) {
    return 'https://${AppConstants.deepLinkDomain}/game/$gameId';
  }

  static String createProfileLink(String userId) {
    return 'https://${AppConstants.deepLinkDomain}/profile/$userId';
  }

  /// Parse incoming deep link path into route components
  static Map<String, String>? parseDeepLink(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final pathSegments = uri.pathSegments;
    if (pathSegments.length >= 3 && pathSegments[0] == 'join' && pathSegments[1] == 'group') {
      return {'type': 'group_invite', 'id': pathSegments[2]};
    } else if (pathSegments.length >= 2 && pathSegments[0] == 'event') {
      return {'type': 'event', 'id': pathSegments[1]};
    } else if (pathSegments.length >= 2 && pathSegments[0] == 'game') {
      return {'type': 'game', 'id': pathSegments[1]};
    } else if (pathSegments.length >= 2 && pathSegments[0] == 'profile') {
      return {'type': 'profile', 'id': pathSegments[1]};
    }
    return null;
  }
}
