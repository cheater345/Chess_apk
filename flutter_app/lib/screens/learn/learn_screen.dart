import 'package:flutter/material.dart';
import '../../config/theme.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(title: const Text('Learn')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Chess Basics', Icons.menu_book),
            const SizedBox(height: 12),
            _buildLessonCard('How Pieces Move', 'Learn the basics', '♟️', AppTheme.primaryGreen, () {}),
            _buildLessonCard('Basic Rules', 'Check, checkmate, stalemate', '📖', Colors.blue, () {}),
            _buildLessonCard('Special Moves', 'Castling, en passant, promotion', '⚡', Colors.orange, () {}),
            const SizedBox(height: 24),
            _buildSectionHeader('Openings', Icons.explore),
            const SizedBox(height: 12),
            _buildLessonCard('Italian Game', '1.e4 e5 2.Nf3 Nc6 3.Bc4', '🇮🇹', const Color(0xFF2ECC71), () {}),
            _buildLessonCard('Sicilian Defense', '1.e4 c5', '🛡️', const Color(0xFFE74C3C), () {}),
            _buildLessonCard('Queen\'s Gambit', '1.d4 d5 2.c4', '👑', const Color(0xFF9B59B6), () {}),
            _buildLessonCard('London System', 'Solid and reliable', '🏛️', const Color(0xFF3498DB), () {}),
            const SizedBox(height: 24),
            _buildSectionHeader('Openings Explorer', Icons.map),
            const SizedBox(height: 12),
            _buildExplorerBanner(),
            const SizedBox(height: 24),
            _buildSectionHeader('Tactics', Icons.bolt),
            const SizedBox(height: 12),
            _buildTacticsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildLessonCard(String title, String subtitle, String emoji, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExplorerBanner() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A2E), Color(0xFF1A1A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Openings Explorer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Explore 2000+ opening lines', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Explore', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticsGrid() {
    final tactics = [
      {'name': 'Forks', 'emoji': '🍴', 'color': const Color(0xFFE74C3C)},
      {'name': 'Pins', 'emoji': '📌', 'color': const Color(0xFF3498DB)},
      {'name': 'Skewers', 'emoji': '🍢', 'color': const Color(0xFFF39C12)},
      {'name': 'Discovered', 'emoji': '💡', 'color': const Color(0xFF2ECC71)},
      {'name': 'Sacrifice', 'emoji': '🎯', 'color': const Color(0xFF9B59B6)},
      {'name': 'Zugzwang', 'emoji': '🔄', 'color': const Color(0xFFE67E22)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.1,
      ),
      itemCount: tactics.length,
      itemBuilder: (_, i) => Container(
        decoration: BoxDecoration(
          color: (tactics[i]['color'] as Color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (tactics[i]['color'] as Color).withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(tactics[i]['emoji'] as String, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(tactics[i]['name'] as String, style: TextStyle(color: tactics[i]['color'] as Color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
