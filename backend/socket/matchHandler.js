function MatchHandler(io, socket, matchmakingService, connectedUsers) {
  socket.on('matchmaking:join', (data) => {
    const { uid, username, elo, timeControl, isRated } = data;

    matchmakingService.removeFromQueue(uid, timeControl);
    const player = matchmakingService.addToQueue(socket.id, {
      uid, username, elo, timeControl, isRated,
    });

    if (player) {
      socket.join(`queue:${timeControl}`);
      socket.emit('matchmaking:in_queue', {
        timeControl,
        position: matchmakingService.getQueueSize(timeControl),
      });
    }
  });

  socket.on('matchmaking:leave', (data) => {
    const { uid, timeControl } = data;
    matchmakingService.removeFromQueue(uid, timeControl);
    if (timeControl) {
      socket.leave(`queue:${timeControl}`);
    }
    socket.emit('matchmaking:cancelled');
  });

  socket.on('matchmaking:status', (data) => {
    const { uid } = data;
    const queueInfo = matchmakingService.getPlayerQueue(uid);
    if (queueInfo) {
      socket.emit('matchmaking:status', {
        inQueue: true,
        timeControl: queueInfo.timeControl,
        position: matchmakingService.getQueueSize(queueInfo.timeControl),
      });
    } else {
      socket.emit('matchmaking:status', { inQueue: false });
    }
  });

  socket.on('friend:invite', (data) => {
    const { uid, username, inviteCode } = data;
    const targetUser = connectedUsers.get(data.targetUid);
    if (targetUser) {
      io.to(targetUser.socketId).emit('friend:invite', {
        from: uid,
        username: username,
        inviteCode,
      });
    } else {
      socket.emit('error', { message: 'User is offline' });
    }
  });

  socket.on('friend:accept', (data) => {
    const { inviteCode, uid } = data;
    io.to(`queue:friend_${inviteCode}`).emit('friend:accepted', {
      uid,
      inviteCode,
    });
  });
}

module.exports = MatchHandler;
