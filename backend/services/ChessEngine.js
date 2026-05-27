class ChessEngine {
  constructor() {
    this.pieceValues = {
      p: 100, n: 320, b: 330, r: 500, q: 900, k: 20000,
      P: 100, N: 320, B: 330, R: 500, Q: 900, K: 20000,
    };

    this.positions = [
      // Pawn table
      [
        0,  0,  0,  0,  0,  0,  0,  0,
        50, 50, 50, 50, 50, 50, 50, 50,
        10, 10, 20, 30, 30, 20, 10, 10,
        5,  5, 10, 25, 25, 10,  5,  5,
        0,  0,  0, 20, 20,  0,  0,  0,
        5, -5,-10,  0,  0,-10, -5,  5,
        5, 10, 10,-20,-20, 10, 10,  5,
        0,  0,  0,  0,  0,  0,  0,  0,
      ],
      // Knight table
      [
        -50,-40,-30,-30,-30,-30,-40,-50,
        -40,-20,  0,  0,  0,  0,-20,-40,
        -30,  0, 10, 15, 15, 10,  0,-30,
        -30,  5, 15, 20, 20, 15,  5,-30,
        -30,  0, 15, 20, 20, 15,  0,-30,
        -30,  5, 10, 15, 15, 10,  5,-30,
        -40,-20,  0,  5,  5,  0,-20,-40,
        -50,-40,-30,-30,-30,-30,-40,-50,
      ],
      // Bishop table
      [
        -20,-10,-10,-10,-10,-10,-10,-20,
        -10,  0,  0,  0,  0,  0,  0,-10,
        -10,  0,  5, 10, 10,  5,  0,-10,
        -10,  5,  5, 10, 10,  5,  5,-10,
        -10,  0, 10, 10, 10, 10,  0,-10,
        -10, 10, 10, 10, 10, 10, 10,-10,
        -10,  5,  0,  0,  0,  0,  5,-10,
        -20,-10,-10,-10,-10,-10,-10,-20,
      ],
      // Rook table
      [
        0,  0,  0,  0,  0,  0,  0,  0,
        5, 10, 10, 10, 10, 10, 10,  5,
        -5,  0,  0,  0,  0,  0,  0, -5,
        -5,  0,  0,  0,  0,  0,  0, -5,
        -5,  0,  0,  0,  0,  0,  0, -5,
        -5,  0,  0,  0,  0,  0,  0, -5,
        -5,  0,  0,  0,  0,  0,  0, -5,
        0,  0,  0,  5,  5,  0,  0,  0,
      ],
      // Queen table
      [
        -20,-10,-10, -5, -5,-10,-10,-20,
        -10,  0,  0,  0,  0,  0,  0,-10,
        -10,  0,  5,  5,  5,  5,  0,-10,
        -5,  0,  5,  5,  5,  5,  0, -5,
        0,  0,  5,  5,  5,  5,  0, -5,
        -10,  5,  5,  5,  5,  5,  0,-10,
        -10,  0,  5,  0,  0,  0,  0,-10,
        -20,-10,-10, -5, -5,-10,-10,-20,
      ],
      // King middle game table
      [
        -30,-40,-40,-50,-50,-40,-40,-30,
        -30,-40,-40,-50,-50,-40,-40,-30,
        -30,-40,-40,-50,-50,-40,-40,-30,
        -30,-40,-40,-50,-50,-40,-40,-30,
        -20,-30,-30,-40,-40,-30,-30,-20,
        -10,-20,-20,-20,-20,-20,-20,-10,
        20, 20,  0,  0,  0,  0, 20, 20,
        20, 30, 10,  0,  0, 10, 30, 20,
      ],
    ];

    this.tables = {
      p: this.positions[0],
      n: this.positions[1],
      b: this.positions[2],
      r: this.positions[3],
      q: this.positions[4],
      k: this.positions[5],
    };
  }

  evaluateBoard(fen, color = 'white') {
    const board = this.fenToBoard(fen);
    let score = 0;
    const isWhite = color === 'white';

    for (let row = 0; row < 8; row++) {
      for (let col = 0; col < 8; col++) {
        const piece = board[row][col];
        if (piece === '') continue;

        const pieceType = piece.toLowerCase();
        const pieceColor = piece === piece.toUpperCase() ? 'white' : 'black';
        const value = this.pieceValues[piece] || 0;

        let positionBonus = 0;
        if (this.tables[pieceType]) {
          const index = isWhite ? (7 - row) * 8 + col : row * 8 + col;
          positionBonus = pieceColor === color
            ? this.tables[pieceType][index]
            : -this.tables[pieceType][index];
        }

        if (pieceColor === color) {
          score += value + positionBonus;
        } else {
          score -= value + positionBonus;
        }
      }
    }

    return score;
  }

  fenToBoard(fen) {
    const board = Array(8).fill(null).map(() => Array(8).fill(''));
    const rows = fen.split(' ')[0].split('/');

    for (let r = 0; r < 8; r++) {
      let c = 0;
      for (const ch of rows[r]) {
        if (isNaN(parseInt(ch))) {
          board[r][c++] = ch;
        } else {
          c += parseInt(ch);
        }
      }
    }

    return board;
  }

  getPieceValue(piece) {
    return this.pieceValues[piece] || 0;
  }

  classifyMove(fen, move, piece, captured, isCheckmate, isCheck, isStalemate) {
    if (isCheckmate || isStalemate) return 'game_ender';
    if (isCheck) return 'check';

    const pieceType = piece.toLowerCase();
    const pieceVal = this.pieceValues[piece] || 0;
    const capturedVal = this.pieceValues[captured] || 0;

    if ((pieceType === 'p' || pieceType === 'b' || pieceType === 'n') && capturedVal >= pieceVal) {
      return 'brilliant';
    }

    if (pieceType === 'n' || pieceType === 'b') {
      if (isCheck) return 'great';
    }

    if (capturedVal > 0 && pieceVal <= capturedVal) {
      return 'excellent';
    }

    if (capturedVal > 0) return 'good';

    if (pieceType === 'p' && (move.includes('8') || move.includes('1'))) {
      return 'promotion';
    }

    return 'normal';
  }

  getOpeningName(moveHistory, openingBook = {}) {
    const pgn = moveHistory.join(' ');
    return openingBook[pgn] || null;
  }
}

module.exports = new ChessEngine();
