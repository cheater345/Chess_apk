import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/game_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/socket_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/game_model.dart';
import '../../widgets/chess_board.dart';

class GameScreen extends StatefulWidget {
  final String? gameId;
  final String? playerColor;
  final Map<String, dynamic>? opponent;

  const GameScreen({super.key, this.gameId, this.playerColor, this.opponent});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _showMoveHistory = false;
  bool _showChat = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setupListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.gameId != null) {
        final socket = context.read<SocketProvider>();
        final auth = context.read<AuthProvider>();
        socket.emit('game:join', {'gameId': widget.gameId, 'uid': auth.user?.uid ?? ''});
      }
    });
  }

  void _setupListeners() {
    final socket = context.read<SocketProvider>();
    final game = context.read<GameProvider>();

    socket.on('game:move', (data) {
      game.addMove(data);
    });

    socket.on('game:clock', (data) {
      game.updateClocks(data);
    });

    socket.on('game:over', (data) {
      game.endGame(data);
      _showGameOverDialog(data);
    });

    socket.on('game:state', (data) {
      game.setGame(GameModel.fromJson(data));
      game.startClockTimer();
    });

    socket.on('chat:game:message', (data) {
      context.read<ChatProvider>().addGameMessage(ChatMessage.fromJson(data));
    });

    socket.on('player:disconnected', (data) {
      _showSnackBar('${data['color']} player disconnected');
    });

    socket.on('game:draw:offer', (data) {
      _showDrawOffer();
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  void _showDrawOffer() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Draw Offer', style: TextStyle(color: Colors.white)),
        content: const Text('Your opponent offers a draw', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Decline', style: TextStyle(color: AppTheme.errorRed))),
          ElevatedButton(onPressed: () {
            final socket = context.read<SocketProvider>();
            socket.emit('game:draw:response', {'gameId': widget.gameId, 'accepted': true});
            Navigator.pop(context);
          }, child: const Text('Accept')),
        ],
      ),
    );
  }

  void _showGameOverDialog(Map<String, dynamic> data) {
    final userId = context.read<AuthProvider>().user?.uid ?? '';
    final game = context.read<GameProvider>().currentGame;
    if (game == null) return;

    final winner = data['winner'];
    final reason = data['reason'] ?? '';
    final isWin = winner == game.getPlayerColor(userId);

    String title, message;
    if (reason == 'resignation') {
      title = isWin ? 'Opponent Resigned' : 'You Resigned';
      message = isWin ? 'You won by resignation' : 'Game ended by resignation';
    } else if (reason == 'checkmate') {
      title = isWin ? 'Checkmate! You Won!' : 'Checkmate';
      message = isWin ? 'Congratulations!' : 'You lost by checkmate';
    } else if (reason == 'stalemate') {
      title = 'Stalemate';
      message = 'The game is a draw';
    } else if (reason == 'agreement') {
      title = 'Draw';
      message = 'Draw by agreement';
    } else if (reason == 'timeout') {
      title = isWin ? 'You Won on Time' : 'You Lost on Time';
      message = isWin ? 'Opponent ran out of time' : 'You ran out of time';
    } else {
      title = isWin ? 'You Won!' : 'Game Over';
      message = 'Winner: $winner';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Leave', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final socket = context.read<SocketProvider>();
              socket.emit('game:rematch', {'gameId': widget.gameId, 'uid': userId});
            },
            child: const Text('Rematch'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();
    final userId = auth.user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: _buildGameAppBar(game, userId),
      body: Column(
        children: [
          if (game.currentGame != null) ...[
            _buildOpponentInfo(game, 'black', userId),
            _buildClock(game, 'black'),
          ],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ChessBoardWidget(
                fen: game.currentGame?.fen ?? 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
                isFlipped: widget.playerColor != null ? widget.playerColor == 'black' : game.currentGame?.getPlayerColor(userId) == 'black',
                interactive: game.currentGame?.isActive ?? false,
                onMove: (from, to) {
                  final socket = context.read<SocketProvider>();
                  socket.emit('game:move', {
                    'gameId': widget.gameId,
                    'uid': userId,
                    'from': from,
                    'to': to,
                    'moveTime': 0,
                  });
                },
                lastMoveFrom: game.currentGame?.moves.isNotEmpty == true
                    ? game.currentGame!.moves.last.from
                    : null,
                lastMoveTo: game.currentGame?.moves.isNotEmpty == true
                    ? game.currentGame!.moves.last.to
                    : null,
              ),
            ),
          ),
          if (game.currentGame != null) ...[
            _buildClock(game, 'white'),
            _buildPlayerInfo(game, 'white'),
          ],
          _buildActionBar(game, userId),
          if (_showMoveHistory) _buildMoveHistory(game),
          if (_showChat) _buildGameChat(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildGameAppBar(GameProvider game, String userId) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          game.resetGame();
          context.read<ChatProvider>().clearGameMessages();
          Navigator.pop(context);
        },
      ),
      title: Text(
        game.currentGame?.isRated == true ? 'Rated • ${game.currentGame?.timeControl.toUpperCase()}' : 'Casual',
        style: const TextStyle(fontSize: 14),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.menu_book),
          onPressed: () {},
          tooltip: 'Analysis',
        ),
        PopupMenuButton<String>(
          onSelected: (v) {
            final socket = context.read<SocketProvider>();
            switch (v) {
              case 'resign':
                socket.emit('game:resign', {'gameId': widget.gameId, 'uid': userId});
                break;
              case 'draw':
                socket.emit('game:draw', {'gameId': widget.gameId, 'uid': userId});
                break;
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'draw', child: Text('Offer Draw')),
            const PopupMenuItem(value: 'resign', child: Text('Resign')),
            const PopupMenuItem(value: 'abort', child: Text('Abort Game')),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayerInfo(GameProvider game, String color) {
    final player = color == 'white' ? game.currentGame!.white : game.currentGame!.black;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surfaceDark,
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color == 'white' ? Colors.white : Colors.black,
            ),
            child: Center(
              child: Text(
                color == 'white' ? 'W' : 'B',
                style: TextStyle(
                  color: color == 'white' ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(player.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text('(${player.elo})', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildOpponentInfo(GameProvider game, String color, String userId) {
    final player = game.currentGame!.getOpponent(userId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surfaceDark,
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: game.currentGame!.getPlayerColor(userId) == 'white' ? Colors.black : Colors.white,
            ),
            child: Center(
              child: Text(
                game.currentGame!.getPlayerColor(userId) == 'white' ? 'B' : 'W',
                style: TextStyle(
                  color: game.currentGame!.getPlayerColor(userId) == 'white' ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(player.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text('(${player.elo})', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const Spacer(),
          if (player.disconnected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppTheme.errorRed.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
              child: const Text('DISCONNECTED', style: TextStyle(color: AppTheme.errorRed, fontSize: 9)),
            ),
        ],
      ),
    );
  }

  Widget _buildClock(GameProvider game, String color) {
    final time = game.clocks[color] ?? 0;
    final minutes = (time / 60).floor();
    final seconds = (time % 60).floor();
    final isActive = game.currentGame?.currentTurn == (color == 'white' ? 'w' : 'b');
    final isLow = time < 30;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isActive ? (isLow ? AppTheme.errorRed.withOpacity(0.2) : AppTheme.primaryGreen.withOpacity(0.1)) : Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: isActive ? (isLow ? AppTheme.errorRed : Colors.white) : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(GameProvider game, String userId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionButton(Icons.undo, 'Moves', () => setState(() => _showMoveHistory = !_showMoveHistory)),
          _actionButton(Icons.chat, 'Chat', () => setState(() => _showChat = !_showChat)),
          _actionButton(Icons.flag, 'Resign', () {
            context.read<SocketProvider>().emit('game:resign', {'gameId': widget.gameId, 'uid': userId});
          }),
          _actionButton(Icons.handshake, 'Draw', () {
            context.read<SocketProvider>().emit('game:draw', {'gameId': widget.gameId, 'uid': userId});
          }),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 22),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildMoveHistory(GameProvider game) {
    final moves = game.currentGame?.moves ?? [];
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Text('Move History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${moves.length} moves', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: moves.length,
              itemBuilder: (_, i) {
                final move = moves[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${(i ~/ 2) + 1}${i % 2 == 0 ? '.' : '...'}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ),
                      Text(move.notation, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      if (move.classification != null) ...[
                        const SizedBox(width: 4),
                        _classificationChip(move.classification!),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _classificationChip(String classification) {
    Color color;
    String label;

    switch (classification) {
      case 'brilliant':
        color = Colors.purple; label = '!!';
        break;
      case 'great':
        color = Colors.blue; label = '!';
        break;
      case 'excellent':
        color = Colors.green; label = '!!';
        break;
      case 'good':
        color = Colors.green; label = '!';
        break;
      case 'mistake':
        color = Colors.orange; label = '?';
        break;
      case 'blunder':
        color = AppTheme.errorRed; label = '??';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(3)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildGameChat() {
    final chat = context.watch<ChatProvider>();

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: chat.gameMessages.length,
              itemBuilder: (_, i) {
                final msg = chat.gameMessages[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(msg.username, style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Expanded(child: Text(msg.message, style: const TextStyle(color: Colors.white, fontSize: 12))),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    final controller = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Chat...',
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  final socket = context.read<SocketProvider>();
                  final auth = context.read<AuthProvider>();
                  socket.emit('chat:game:send', {
                    'gameId': widget.gameId,
                    'uid': auth.user!.uid,
                    'username': auth.user!.username,
                    'message': text.trim(),
                  });
                  controller.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
