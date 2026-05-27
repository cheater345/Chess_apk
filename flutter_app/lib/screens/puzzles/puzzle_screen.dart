import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/puzzle_provider.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PuzzleProvider>().loadDailyPuzzle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = context.watch<PuzzleProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(title: const Text('Puzzles')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsBar(puzzle),
            const SizedBox(height: 16),
            _buildDailyPuzzle(puzzle),
            const SizedBox(height: 24),
            const Text('Puzzle Themes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            _buildThemeGrid(),
            const SizedBox(height: 24),
            const Text('By Rating', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            _buildRatingLevels(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar(PuzzleProvider puzzle) {
    return Row(
      children: [
        _statChip('🧩', 'Score', '${puzzle.score}'),
        const SizedBox(width: 12),
        _statChip('🔥', 'Streak', '${puzzle.streak}'),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('Rated Puzzles', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _statChip(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyPuzzle(PuzzleProvider puzzle) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D1B69), Color(0xFF1A1A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('DAILY', style: TextStyle(fontSize: 10, color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(puzzle.currentPuzzle != null ? puzzle.currentPuzzle!.theme.toUpperCase() : 'TACTICS',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5), letterSpacing: 2)),
                const SizedBox(height: 8),
                const Text('Solve the daily puzzle', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text('${puzzle.currentPuzzle?.moves.length ?? 0} moves • ${puzzle.currentPuzzle?.rating ?? 1200} rating',
                    style: TextStyle(color: Colors.white.withOpacity(0.6))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Solve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeGrid() {
    final themes = [
      {'icon': '🎯', 'name': 'Forks', 'color': const Color(0xFFE74C3C)},
      {'icon': '📌', 'name': 'Pins', 'color': const Color(0xFF3498DB)},
      {'icon': '⚡', 'name': 'Sacrifices', 'color': const Color(0xFFF39C12)},
      {'icon': '🛡️', 'name': 'Defense', 'color': const Color(0xFF2ECC71)},
      {'icon': '👑', 'name': 'Endgame', 'color': const Color(0xFF9B59B6)},
      {'icon': '⚔️', 'name': 'Attack', 'color': const Color(0xFFE67E22)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: themes.length,
      itemBuilder: (_, i) => _themeCard(themes[i]),
    );
  }

  Widget _themeCard(Map<String, dynamic> theme) {
    return Container(
      decoration: BoxDecoration(
        color: (theme['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (theme['color'] as Color).withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(theme['icon'] as String, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(theme['name'] as String, style: TextStyle(color: theme['color'] as Color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRatingLevels() {
    final levels = [
      {'range': '0-1200', 'label': 'Beginner'},
      {'range': '1200-1400', 'label': 'Intermediate'},
      {'range': '1400-1600', 'label': 'Advanced'},
      {'range': '1600-1800', 'label': 'Expert'},
      {'range': '1800-2000', 'label': 'Master'},
      {'range': '2000+', 'label': 'Grandmaster'},
    ];

    return Column(
      children: levels.map((l) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(child: Text(l['label'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(l['range'] as String, style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      )).toList(),
    );
  }
}
