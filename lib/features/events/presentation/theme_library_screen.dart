import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';

class ThemeLibraryScreen extends StatelessWidget {
  const ThemeLibraryScreen({super.key});

  static const List<Map<String, dynamic>> partyThemes = [
    {
      'title': 'Bollywood Glam',
      'emoji': '🎬',
      'dressCode': 'Retro 90s Saree, Filmy Kurtis or Red Carpet Gowns',
      'decor': 'Movie posters, red carpet entry, selfie photobooth with clapboards',
      'food': 'Mumbai Street Food, Chat counter, Cutting Chai & Gulab Jamun',
      'games': 'Bollywood Quiz, Dumb Charades, Guess the Song',
      'prizes': 'Filmy Gift Hampers, Movie Vouchers, Retro Sunglasses',
    },
    {
      'title': 'Retro 90s',
      'emoji': '📻',
      'dressCode': 'Polka Dots, Bell-bottoms, Bright Neons',
      'decor': 'Cassette tapes, vinyl records, disco lights',
      'food': 'Samosas, Cold Drinks, Parathas, Ice Cream Sunder',
      'games': 'Memory Challenge, 90s Music Quiz',
      'prizes': 'Cassette-shaped Bluetooth Speaker, Vintage Tea Set',
    },
    {
      'title': 'Black & Gold Royale',
      'emoji': '✨',
      'dressCode': 'Elegant Black Gowns or Gold Draped Sarees',
      'decor': 'Gold balloons, fairy lights, glitter tablecloths',
      'food': 'Mocktails, Cheese Board, Gourmet Pasta & Cheesecake',
      'games': 'Lucky Draw, Rapid Fire, Target Challenge',
      'prizes': 'Gold Plated Decor Piece, Premium Fragrance Set',
    },
    {
      'title': 'Floral Paradise',
      'emoji': '🌸',
      'dressCode': 'Pastel Floral Print Sarees or Dresses',
      'decor': 'Fresh rose petals, flower arches, botanical scents',
      'food': 'High Tea Snacks, Sandwiches, Fruit Tart & Herbal Teas',
      'games': 'Emoji Guess, Word Challenge',
      'prizes': 'Floral Scented Candles, Plant Terrarium',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Party Theme Library 🎭'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: partyThemes.length,
        itemBuilder: (context, index) {
          final theme = partyThemes[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppCard(
              child: ExpansionTile(
                leading: Text(theme['emoji'], style: const TextStyle(fontSize: 32)),
                title: Text(theme['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Text('Dress code: ${theme['dressCode']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ThemeDetailRow(icon: Icons.checkroom, title: 'Dress Code', desc: theme['dressCode']),
                        const SizedBox(height: 8),
                        _ThemeDetailRow(icon: Icons.brush, title: 'Decoration', desc: theme['decor']),
                        const SizedBox(height: 8),
                        _ThemeDetailRow(icon: Icons.restaurant, title: 'Food & Snacks', desc: theme['food']),
                        const SizedBox(height: 8),
                        _ThemeDetailRow(icon: Icons.sports_esports, title: 'Suggested Games', desc: theme['games']),
                        const SizedBox(height: 8),
                        _ThemeDetailRow(icon: Icons.card_giftcard, title: 'Prize Ideas', desc: theme['prizes']),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ThemeDetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _ThemeDetailRow({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              children: [
                TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
