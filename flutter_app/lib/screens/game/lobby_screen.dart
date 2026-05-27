import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/socket_provider.dart';

class LobbyScreen extends StatefulWidget {
  final String? initialTimeControl;

  const LobbyScreen({super.key, this.initialTimeControl});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> with TickerProviderStateMixin {
  String _selectedTimeControl = 'blitz';
  bool _isSearching = false;
  late AnimationController _searchAnimController;
  late Animation<double> _searchPulseAnim;
  Timer? _searchTimer;
  int _searchDuration = 0;

  final List<Map<String, dynamic>> _timeControls = [
    {'key': 'bullet', 'name': 'Bullet', 'time': '1 min', 'increment': '0', 'icon': '⚡', 'color': const Color(0xFFE74C3C)},
    {'key': 'blitz', 'name': 'Blitz', 'time': '3 min', 'increment': '+2', 'icon': '🔥', 'color': const Color(0xFFE67E22)},
    {'key': 'rapid', 'name': 'Rapid', 'time': '10 min', 'increment': '+5', 'icon': '⏱️', 'color': AppTheme.primaryGreen},
    {'key': 'classical', 'name': 'Classical', 'time': '30 min', 'increment': '+10', 'icon': '⌛', 'color': const Color(0xFF9B59B6)},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTimeControl != null) {
      _selectedTimeControl = widget.initialTimeControl!;
    }

    _searchAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _searchPulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _searchAnimController, curve: Curves.easeInOut),
    );

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    final socket = context.read<SocketProvider>();
    socket.on('match:found', (data) {
      if (mounted) {
        _stopSearching();
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => GameScreen(
            gameId: data['gameId'],
            playerColor: data['color'],
            opponent: data['opponent'],
          ),
        ));
      }
    });

    socket.on('matchmaking:in_queue', (data) {
      if (mounted) {
        context.read<GameProvider>().updateQueuePosition(data['position']);
      }
    });

    socket.on('matchmaking:cancelled', (_) {
      if (mounted) {
        _stopSearching();
      }
    });
  }

  void _startSearching() {
    setState(() {
      _isSearching = true;
      _searchDuration = 0;
    });
    _searchAnimController.forward();

    final auth = context.read<AuthProvider>();
    final socket = context.read<SocketProvider>();
    socket.emit('matchmaking:join', {
      'uid': auth.user!.uid,
      'username': auth.user!.username,
      'elo': auth.user!.elo,
      'timeControl': _selectedTimeControl,
      'isRated': true,
    });

    _searchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _searchDuration++);
    });
  }

  void _stopSearching() {
    setState(() => _isSearching = false);
    _searchAnimController.reset();
    _searchTimer?.cancel();

    final auth = context.read<AuthProvider>();
    final socket = context.read<SocketProvider>();
    socket.emit('matchmaking:leave', {
      'uid': auth.user!.uid,
      'timeControl': _selectedTimeControl,
    });
  }

  @override
  void dispose() {
    if (_isSearching) _stopSearching();
    _searchAnimController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Play Online'),
        actions: [
          if (_isSearching)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  _formatDuration(_searchDuration),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildRatingInfo(),
          Expanded(
            child: _isSearching ? _buildSearchingUI() : _buildTimeControlList(),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildRatingInfo() {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final rating = user?.getRating(_selectedTimeControl) ?? 1200;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, color: AppTheme.primaryGreen, size: 20),
          const SizedBox(width: 8),
          Text(
            'Your ${_selectedTimeControl.toUpperCase()} Rating: ',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          Text(
            '$rating',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeControlList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _timeControls.length,
      itemBuilder: (context, index) {
        final tc = _timeControls[index];
        final isSelected = tc['key'] == _selectedTimeControl;

        return GestureDetector(
          onTap: () => setState(() => _selectedTimeControl = tc['key']),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? (tc['color'] as Color).withOpacity(0.15) : AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? tc['color'] as Color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Text(tc['icon'] as String, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tc['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${tc['time']} | ${tc['increment']}', style: TextStyle(color: (tc['color'] as Color).withOpacity(0.7), fontSize: 13)),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: tc['color'] as Color, size: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _searchPulseAnim,
            builder: (context, child) {
              return Transform.scale(
                scale: _searchPulseAnim.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.primaryGreenGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('♚', style: TextStyle(fontSize: 50, color: Colors.white)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Searching for opponent', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Looking for ${_selectedTimeControl.toUpperCase()} players...',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Text(
            _formatDuration(_searchDuration),
            style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '~${_estimateWaitTime()} avg wait time',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSearching ? _stopSearching : _startSearching,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSearching ? AppTheme.errorRed : AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: Text(
              _isSearching ? 'Cancel Search' : 'Play ${_selectedTimeControl.toUpperCase()}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  String _estimateWaitTime() {
    switch (_selectedTimeControl) {
      case 'bullet': return '5-10s';
      case 'blitz': return '10-20s';
      case 'rapid': return '20-40s';
      case 'classical': return '30-60s';
      default: return '15-30s';
    }
  }
}

class GameScreen extends StatelessWidget {
  final String gameId;
  final String playerColor;
  final Map<String, dynamic>? opponent;

  const GameScreen({
    super.key,
    required this.gameId,
    required this.playerColor,
    this.opponent,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Game: $gameId')),
      body: Center(child: Text('Game Screen - Under Construction')),
    );
  }
}
