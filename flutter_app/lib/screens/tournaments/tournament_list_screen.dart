import 'package:flutter/material.dart';
import '../../config/theme.dart';

class TournamentListScreen extends StatelessWidget {
  const TournamentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Tournaments'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Create', style: TextStyle(color: AppTheme.primaryGreen)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeaturedTournament(),
            const SizedBox(height: 20),
            _buildFilterBar(),
            const SizedBox(height: 16),
            const Text('Active Tournaments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            _buildTournamentCard('Blitz Championship', 'Blitz • 3+2', '🏆', 24, 16, AppTheme.accentGold, 'registering'),
            _buildTournamentCard('Rapid Masters', 'Rapid • 10+5', '👑', 8, 16, Colors.blue, 'registering'),
            _buildTournamentCard('Bullet Arena', 'Bullet • 1+0', '⚡', 12, 32, Colors.orange, 'in_progress'),
            const SizedBox(height: 20),
            const Text('Upcoming', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            _buildTournamentCard('Weekend Classic', 'Classical • 30+10', '⌛', 0, 16, Colors.purple, 'upcoming'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedTournament() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A2E), Color(0xFF0D1B2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('FEATURED', style: TextStyle(fontSize: 10, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                const Text('Grandmaster Invitational', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('256 players • 2500+ rating', style: TextStyle(color: Colors.white.withOpacity(0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('All', true),
          _filterChip('Blitz', false),
          _filterChip('Rapid', false),
          _filterChip('Bullet', false),
          _filterChip('Classical', false),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected) {
    return GestureDetector(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryGreen : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : AppTheme.textSecondary)),
      ),
    );
  }

  Widget _buildTournamentCard(String name, String format, String emoji, int players, int maxPlayers, Color color, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(format, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.people, color: AppTheme.textSecondary, size: 14),
                    const SizedBox(width: 4),
                    Text('$players/$maxPlayers', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(width: 8),
                    if (status == 'registering')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
                        child: const Text('OPEN', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 9, fontWeight: FontWeight.bold)),
                      )
                    else if (status == 'in_progress')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.errorRed.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
                        child: const Text('LIVE', style: TextStyle(color: AppTheme.errorRed, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}
