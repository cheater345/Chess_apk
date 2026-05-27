import 'package:flutter/material.dart';
import '../../config/theme.dart';

class PlayAIScreen extends StatefulWidget {
  const PlayAIScreen({super.key});

  @override
  State<PlayAIScreen> createState() => _PlayAIScreenState();
}

class _PlayAIScreenState extends State<PlayAIScreen> {
  int _selectedDifficulty = 3;
  bool _isBlack = false;

  final List<Map<String, dynamic>> _difficulties = [
    {'name': 'Beginner', 'el': 800, 'color': const Color(0xFF2ECC71), 'icon': '🌱', 'desc': 'Makes random mistakes'},
    {'name': 'Easy', 'el': 1100, 'color': const Color(0xFF27AE60), 'icon': '♟️', 'desc': 'Basic tactics'},
    {'name': 'Medium', 'el': 1500, 'color': const Color(0xFFF39C12), 'icon': '⚔️', 'desc': 'Club player level'},
    {'name': 'Hard', 'el': 1900, 'color': const Color(0xFFE67E22), 'icon': '🎯', 'desc': 'Strong club player'},
    {'name': 'Expert', 'el': 2200, 'color': const Color(0xFFE74C3C), 'icon': '👑', 'desc': 'Master level'},
    {'name': 'Grandmaster', 'el': 2600, 'color': const Color(0xFF8E44AD), 'icon': '🏆', 'desc': 'GM strength'},
  ];

  String get _selectedLevel => _difficulties[_selectedDifficulty]['name'];
  int get _selectedElo => _difficulties[_selectedDifficulty]['el'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(title: const Text('Play vs AI')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAIInfo(),
            const SizedBox(height: 24),
            const Text('Select Difficulty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            ...List.generate(_difficulties.length, (i) => _buildDifficultyCard(i)),
            const SizedBox(height: 24),
            _buildPlayOptions(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                child: Text('Play as ${_isBlack ? 'Black' : 'White'} vs $_selectedLevel', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.darkGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.primaryGreenGradient,
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 30))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Stockfish Engine', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$_selectedLevel • ~$_selectedElo ELO', style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 14)),
                Text('Free unlimited games', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyCard(int index) {
    final diff = _difficulties[index];
    final isSelected = index == _selectedDifficulty;

    return GestureDetector(
      onTap: () => setState(() => _selectedDifficulty = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? (diff['color'] as Color).withOpacity(0.15) : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? diff['color'] as Color : Colors.transparent),
        ),
        child: Row(
          children: [
            Text(diff['icon'] as String, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(diff['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(diff['desc'] as String, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Text('${diff['el']}', style: TextStyle(color: diff['color'] as Color, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Options', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Play as', style: TextStyle(color: AppTheme.textSecondary)),
              const Spacer(),
              _colorChip('White', !_isBlack, Colors.white),
              const SizedBox(width: 8),
              _colorChip('Black', _isBlack, Colors.black),
            ],
          ),
        ],
      ),
    );
  }

  Widget _colorChip(String label, bool selected, Color color) {
    return GestureDetector(
      onTap: () => setState(() => _isBlack = label == 'Black'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              width: 16, height: 16,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: selected ? Colors.white : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
