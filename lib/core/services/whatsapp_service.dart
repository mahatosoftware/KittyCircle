import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class WhatsAppService {
  WhatsAppService._();

  /// Share Kitty Group invitation text with deep link
  static Future<void> shareKittyInvitation({
    required String groupName,
    required String inviteLink,
    String? contributionAmount,
  }) async {
    final message = '''
🎉 *You're invited to join*

🌸 *$groupName*

on *KittyCircle*!

${contributionAmount != null ? "Monthly Contribution: $contributionAmount\n" : ""}
Join our kitty group using the link below:
$inviteLink

_Plan. Play. Celebrate._
''';
    await _shareText(message);
  }

  /// Share Monthly Kitty Event invitation
  static Future<void> shareEventInvitation({
    required String eventTitle,
    required String groupName,
    required String date,
    required String time,
    required String hostName,
    required String venue,
    String? theme,
    required String eventLink,
  }) async {
    final themeText = theme != null && theme.isNotEmpty ? "\n🎭 *Theme:* $theme" : "";
    final message = '''
🎉 *$eventTitle* ($groupName)

📅 *Date:* $date
⏰ *Time:* $time
👑 *Host:* $hostName
📍 *Venue:* $venue$themeText

RSVP & Details:
$eventLink

_KittyCircle — Plan. Play. Celebrate._
''';
    await _shareText(message);
  }

  /// Share Game Results & Winners
  static Future<void> shareGameResult({
    required String eventTitle,
    required List<Map<String, String>> winners, // [{'rank': '🥇', 'name': 'Priya', 'game': 'Bollywood Quiz'}]
    required String groupName,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln("🏆 *$eventTitle - Game Winners* ($groupName)\n");
    for (final winner in winners) {
      buffer.writeln("${winner['rank']} *${winner['name']}* (${winner['game']})");
    }
    buffer.writeln("\n_Shared via KittyCircle App_ 🎉");
    await _shareText(buffer.toString());
  }

  /// Share Next Kitty information
  static Future<void> shareNextKitty({
    required String groupName,
    required String nextHost,
    required String date,
    required String nextKittyLink,
  }) async {
    final message = '''
🌸 *Next Kitty for $groupName*

📅 *Date:* $date
👑 *Upcoming Host:* $nextHost

See details & prepare:
$nextKittyLink

_KittyCircle_
''';
    await _shareText(message);
  }

  /// Share Expense Settlement Breakdown
  static Future<void> shareExpenseSettlement({
    required String eventTitle,
    required String groupName,
    required double totalExpenses,
    required double perPersonShare,
    required List<Map<String, dynamic>> memberBalances,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln("🧾 *Expense Split & Settlement Summary*");
    buffer.writeln("🎉 *$eventTitle* ($groupName)\n");
    buffer.writeln("💵 *Total Expenses:* ₹${totalExpenses.toInt()}");
    buffer.writeln("👥 *Equal Share:* ₹${perPersonShare.toInt()} per member\n");
    buffer.writeln("*Member Balances:*");
    for (final m in memberBalances) {
      final double bal = (m['balance'] as num).toDouble();
      final String name = m['name'] as String;
      final bool isSettled = m['isSettled'] as bool? ?? false;
      if (isSettled) {
        buffer.writeln("✅ *$name*: Settled (Paid ₹${(m['paid'] as num).toInt()})");
      } else if (bal > 0) {
        buffer.writeln("🟢 *$name*: Receives ₹${bal.toInt()} (Paid ₹${(m['paid'] as num).toInt()})");
      } else if (bal < 0) {
        buffer.writeln("🔴 *$name*: Owes ₹${(-bal).toInt()} (Paid ₹${(m['paid'] as num).toInt()})");
      } else {
        buffer.writeln("✅ *$name*: Settled (₹0 net balance)");
      }
    }
    buffer.writeln("\n_Please complete your UPI payments to settle balances!_ 💸");
    buffer.writeln("_Shared via KittyCircle_");
    await _shareText(buffer.toString());
  }

  static Future<void> _shareText(String text) async {
    // Primary: Native Share dialog (user can pick WhatsApp, Messages, etc.)
    final result = await Share.share(text);
    if (result.status == ShareResultStatus.unavailable) {
      // Fallback: direct whatsapp web/app launch
      final encoded = Uri.encodeComponent(text);
      final url = Uri.parse("https://wa.me/?text=$encoded");
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }
}
