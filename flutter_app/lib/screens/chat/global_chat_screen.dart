import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/socket_provider.dart';
import '../../models/game_model.dart';

class GlobalChatScreen extends StatefulWidget {
  const GlobalChatScreen({super.key});

  @override
  State<GlobalChatScreen> createState() => _GlobalChatScreenState();
}

class _GlobalChatScreenState extends State<GlobalChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ChatProvider>().loadGlobalHistory();
    _setupListeners();
  }

  void _setupListeners() {
    final socket = context.read<SocketProvider>();
    socket.on('chat:global:message', (data) {
      context.read<ChatProvider>().addGlobalMessage(ChatMessage.fromJson(data));
      _scrollDown();
    });
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final socket = context.read<SocketProvider>();
    socket.emit('chat:global:send', {
      'uid': auth.user!.uid,
      'username': auth.user!.username,
      'message': text,
    });

    _messageController.clear();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(title: const Text('Global Chat')),
      body: Column(
        children: [
          Expanded(
            child: chat.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chat.globalMessages.length,
                    itemBuilder: (_, i) => _buildMessage(chat.globalMessages[i]),
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryGreen.withOpacity(0.3),
            ),
            child: Center(
              child: Text(
                msg.username[0].toUpperCase(),
                style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(msg.username, style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(msg.message, style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: AppTheme.cardDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
