const { getDb, admin } = require('../config/firebase');

class ChatHandler {
  constructor(io, socket, connectedUsers) {
    this.io = io;
    this.socket = socket;
    this.connectedUsers = connectedUsers;
  }

  static setup(io, socket, connectedUsers) {
    const handler = new ChatHandler(io, socket, connectedUsers);

    socket.on('chat:global:send', (data) => handler.sendGlobalMessage(data));
    socket.on('chat:game:send', (data) => handler.sendGameMessage(data));
    socket.on('chat:private:send', (data) => handler.sendPrivateMessage(data));
    socket.on('chat:global:history', () => handler.getGlobalHistory());
    socket.on('chat:private:history', (data) => handler.getPrivateHistory(data));
  }

  async sendGlobalMessage(data) {
    const { uid, username, message } = data;
    if (!message?.trim() || message.length > 500) return;

    const msg = {
      uid,
      username,
      message: message.trim(),
      timestamp: new Date().toISOString(),
      type: 'global',
    };

    try {
      const db = getDb();
      await db.collection('chat_global').add({
        ...msg,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (e) {}

    this.io.emit('chat:global:message', {
      ...msg,
      id: `${Date.now()}_${uid}`,
    });
  }

  async sendGameMessage(data) {
    const { gameId, uid, username, message } = data;
    if (!message?.trim() || message.length > 300) return;

    const msg = {
      uid,
      username,
      message: message.trim(),
      timestamp: Date.now(),
    };

    this.io.to(`game:${gameId}`).emit('chat:game:message', msg);
  }

  async sendPrivateMessage(data) {
    const { to, from, message } = data;
    if (!message?.trim() || message.length > 500) return;

    const msg = {
      from: from.uid,
      fromUsername: from.username,
      message: message.trim(),
      timestamp: new Date().toISOString(),
    };

    try {
      const db = getDb();
      const chatId = [from.uid, to].sort().join('_');
      await db.collection('private_chats').doc(chatId).collection('messages').add({
        ...msg,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (e) {}

    const targetSocket = this.connectedUsers.get(to);
    if (targetSocket) {
      this.io.to(targetSocket.socketId).emit('chat:private:message', msg);
    }

    this.socket.emit('chat:private:message', msg);
  }

  async getGlobalHistory() {
    try {
      const db = getDb();
      const snapshot = await db
        .collection('chat_global')
        .orderBy('timestamp', 'desc')
        .limit(50)
        .get();

      const messages = snapshot.docs
        .map((doc) => ({ id: doc.id, ...doc.data() }))
        .reverse();

      this.socket.emit('chat:global:history', messages);
    } catch (e) {
      this.socket.emit('chat:global:history', []);
    }
  }

  async getPrivateHistory(data) {
    const { with: otherUid, myUid } = data;
    try {
      const db = getDb();
      const chatId = [myUid, otherUid].sort().join('_');
      const snapshot = await db
        .collection('private_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', 'desc')
        .limit(50)
        .get();

      const messages = snapshot.docs
        .map((doc) => ({ id: doc.id, ...doc.data() }))
        .reverse();

      this.socket.emit('chat:private:history', { with: otherUid, messages });
    } catch (e) {
      this.socket.emit('chat:private:history', { with: otherUid, messages: [] });
    }
  }
}

module.exports = ChatHandler;
