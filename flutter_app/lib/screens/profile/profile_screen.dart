import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/socket_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
            child: const Text('Login'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettings(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(user),
            const SizedBox(height: 20),
            _buildStatsCards(user),
            const SizedBox(height: 20),
            _buildRatingCards(user),
            const SizedBox(height: 20),
            _buildAchievements(user),
            const SizedBox(height: 20),
            _buildDailyReward(),
            const SizedBox(height: 20),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.darkGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.primaryGreenGradient,
            ),
            child: Center(
              child: Text(user.initials, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          Text(user.displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Level ${user.level} • ${user.rank}', style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 13)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _infoChip(Icons.monetization_on, '${user.coins}', AppTheme.accentGold),
              const SizedBox(width: 12),
              _infoChip(Icons.stars, '${user.xp} XP', AppTheme.primaryGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStatsCards(dynamic user) {
    final stats = user.stats;

    return Row(
      children: [
        Expanded(child: _statCard('Games', '${stats['gamesPlayed'] ?? 0}', Icons.sports_esports, AppTheme.primaryGreen)),
        const SizedBox(width: 8),
        Expanded(child: _statCard('Wins', '${stats['wins'] ?? 0}', Icons.emoji_events, Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _statCard('Win %', '${user.winRate}%', Icons.trending_up, Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _statCard('Streak', '${stats['winStreak'] ?? 0}', Icons.local_fire_department, Colors.orange)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildRatingCards(dynamic user) {
    final elo = user.elo;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ratings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          _ratingRow('⚡', 'Bullet', '${elo['bullet'] ?? 1200}', AppTheme.primaryGreen, elo['bullet'] ?? 1200),
          _ratingRow('🔥', 'Blitz', '${elo['blitz'] ?? 1200}', Colors.orange, elo['blitz'] ?? 1200),
          _ratingRow('⏱️', 'Rapid', '${elo['rapid'] ?? 1200}', Colors.blue, elo['rapid'] ?? 1200),
          _ratingRow('⌛', 'Classical', '${elo['classical'] ?? 1200}', Colors.purple, elo['classical'] ?? 1200),
        ],
      ),
    );
  }

  Widget _ratingRow(String emoji, String label, String value, Color color, int rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white))),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 8),
          Container(
            width: 60, height: 4,
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (rating - 100) / (3000 - 100),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Achievements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const Spacer(),
              Text('${user.achievements?.length ?? 0} unlocked', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _achievementBadge('🏆', 'First Win', user.achievements?.contains('first_win') ?? false),
                _achievementBadge('♟️', 'First Game', user.achievements?.contains('first_game') ?? false),
                _achievementBadge('🔥', 'On Fire', user.achievements?.contains('win_streak_3') ?? false),
                _achievementBadge('💯', 'Century', user.achievements?.contains('century') ?? false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _achievementBadge(String emoji, String name, bool unlocked) {
    return Container(
      width: 72,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: unlocked ? AppTheme.accentGold.withOpacity(0.2) : AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: unlocked ? AppTheme.accentGold.withOpacity(0.5) : Colors.transparent),
            ),
            child: Center(child: Text(emoji, style: TextStyle(fontSize: 24, color: unlocked ? Colors.white : Colors.grey))),
          ),
          const SizedBox(height: 4),
          Text(name, style: TextStyle(fontSize: 10, color: unlocked ? Colors.white : AppTheme.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDailyReward() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFD700).withOpacity(0.1), Color(0xFFFFA500).withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Reward', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Claim your daily bonus!', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Claim', style: TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              _settingTile(Icons.volume_up, 'Sound Effects', true),
              _settingTile(Icons.animation, 'Piece Animation', true),
              _settingTile(Icons.lightbulb, 'Move Hints', true),
              _settingTile(Icons.chat, 'In-Game Chat', true),
              _settingTile(Icons.notifications, 'Push Notifications', true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingTile(IconData icon, String title, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15))),
          Switch(
            value: value,
            onChanged: (_) {},
            activeColor: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    final auth = context.read<AuthProvider>();
    if (auth.user?.isGuest ?? false) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              child: const Text('Save Progress - Create Account'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          context.read<AuthProvider>().logout();
          context.read<SocketProvider>().disconnect();
          Navigator.pushReplacementNamed(context, '/auth');
        },
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorRed, side: const BorderSide(color: AppTheme.errorRed)),
      ),
    );
  }
}
