import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/socket_provider.dart';
import '../../providers/chat_provider.dart';
import '../../config/theme.dart';
import '../game/lobby_screen.dart';
import '../game/play_ai_screen.dart';
import '../puzzles/puzzle_screen.dart';
import '../learn/learn_screen.dart';
import '../profile/profile_screen.dart';
import '../chat/global_chat_screen.dart';
import '../tournaments/tournament_list_screen.dart';
import 'widgets/home_card.dart';
import 'widgets/quick_play_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _HomeTab(),
    const PuzzleScreen(),
    const LearnScreen(),
    const TournamentListScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  void _connectSocket() {
    final auth = context.read<AuthProvider>();
    final socket = context.read<SocketProvider>();
    if (auth.isLoggedIn) {
      socket.connect(auth.user!.uid, auth.user!.username);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          _navItem(Icons.home, 'Home'),
          _navItem(Icons.extension, 'Puzzles'),
          _navItem(Icons.school, 'Learn'),
          _navItem(Icons.emoji_events, 'Events'),
          _navItem(Icons.person, 'Profile'),
        ],
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, String label) {
    return BottomNavigationBarItem(icon: Icon(icon), label: label);
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.primaryGreenGradient,
              ),
              child: Center(
                child: Text(
                  user?.initials ?? '?',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.displayName ?? 'Player', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${user?.getRating('rapid') ?? 1200} pts', style: const TextStyle(fontSize: 12, color: AppTheme.primaryGreen)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: true,
              label: const Text('3', style: TextStyle(fontSize: 10)),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalChatScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDailyPuzzleBanner(context),
            const SizedBox(height: 20),
            const Text('Play', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: QuickPlayCard(
                    icon: Icons.public,
                    label: 'Play Online',
                    gradient: AppGradients.primaryGreenGradient,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LobbyScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QuickPlayCard(
                    icon: Icons.computer,
                    label: 'Play AI',
                    gradient: AppGradients.goldAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayAIScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildGameModes(context),
            const SizedBox(height: 20),
            _buildLeaderboardPreview(context),
            const SizedBox(height: 20),
            _buildActiveGames(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyPuzzleBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D1B69), Color(0xFF1A1A2E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('DAILY PUZZLE', style: TextStyle(fontSize: 10, color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    const Text('Solve today\'s puzzle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Train your tactics', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6))),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('🧩', style: TextStyle(fontSize: 60)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameModes(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Game Modes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _gameModeCard(context, '⚡', 'Bullet', '1 min', AppTheme.primaryGreen, () => _startMatchmaking(context, 'bullet'))),
            const SizedBox(width: 8),
            Expanded(child: _gameModeCard(context, '🔥', 'Blitz', '3+2', Colors.orange, () => _startMatchmaking(context, 'blitz'))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _gameModeCard(context, '⏱️', 'Rapid', '10+5', Colors.blue, () => _startMatchmaking(context, 'rapid'))),
            const SizedBox(width: 8),
            Expanded(child: _gameModeCard(context, '⌛', 'Classical', '30+10', Colors.purple, () => _startMatchmaking(context, 'classical'))),
          ],
        ),
      ],
    );
  }

  void _startMatchmaking(BuildContext context, String timeControl) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => LobbyScreen(initialTimeControl: timeControl)));
  }

  Widget _gameModeCard(BuildContext context, String emoji, String name, String time, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
            Text(time, style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardPreview(BuildContext context) {
    return HomeCard(
      title: 'Leaderboard',
      child: Column(
        children: [
          _leaderboardRow(1, 'MagnusCarlsen', '🏆', 2850, AppTheme.accentGold),
          const Divider(color: AppTheme.cardDark),
          _leaderboardRow(2, 'HikaruNakamura', '⚔️', 2830, AppTheme.accentSilver),
          const Divider(color: AppTheme.cardDark),
          _leaderboardRow(3, 'SpeedDemon', '🐉', 2755, AppTheme.accentBronze),
        ],
      ),
    );
  }

  Widget _leaderboardRow(int rank, String name, String emoji, int elo, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.2)),
            child: Center(child: Text('$rank', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))),
          ),
          const SizedBox(width: 12),
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
          Text('$elo', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActiveGames(BuildContext context) {
    return HomeCard(
      title: 'Live Games',
      trailing: TextButton(
        onPressed: () {},
        child: const Text('View All', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 13)),
      ),
      child: Column(
        children: [
          _liveGameRow('MagnusCarlsen', 'HikaruNakamura', 'Blitz • 24 moves'),
          const Divider(color: AppTheme.cardDark),
          _liveGameRow('LevyRozman', 'SpeedDemon', 'Rapid • 12 moves'),
          const Divider(color: AppTheme.cardDark),
          _liveGameRow('QueenGambit', 'SicilianDragon', 'Bullet • 45 moves'),
        ],
      ),
    );
  }

  Widget _liveGameRow(String white, String black, String info) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.videocam, size: 16, color: AppTheme.errorRed),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$white vs $black', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
                Text(info, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('LIVE', style: TextStyle(color: AppTheme.errorRed, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
