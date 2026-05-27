import 'package:flutter/material.dart';
import '../config/theme.dart';

class ChessBoardWidget extends StatefulWidget {
  final String fen;
  final bool isFlipped;
  final bool interactive;
  final Function(String from, String to)? onMove;
  final List<String>? highlightedSquares;
  final String? lastMoveFrom;
  final String? lastMoveTo;
  final String? selectedSquare;
  final bool showCoordinates;

  const ChessBoardWidget({
    super.key,
    required this.fen,
    this.isFlipped = false,
    this.interactive = false,
    this.onMove,
    this.highlightedSquares,
    this.lastMoveFrom,
    this.lastMoveTo,
    this.selectedSquare,
    this.showCoordinates = true,
  });

  @override
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget> {
  String? _selectedSquare;
  List<String> _legalMoves = [];
  bool _isDragging = false;
  String? _dragFrom;
  Offset? _dragPosition;

  final Map<String, String> _unicodePieces = {
    'K': '♔', 'Q': '♕', 'R': '♖', 'B': '♗', 'N': '♘', 'P': '♙',
    'k': '♚', 'q': '♛', 'r': '♜', 'b': '♝', 'n': '♞', 'p': '♟',
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.maxWidth;
        final squareSize = boardSize / 8;

        return GestureDetector(
          onTapDown: widget.interactive ? (details) => _handleTap(details, squareSize, boardSize) : null,
          child: Container(
            width: boardSize,
            height: boardSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                _buildBoard(squareSize),
                if (_isDragging && _dragFrom != null && _dragPosition != null)
                  Positioned(
                    left: _dragPosition!.dx - squareSize / 2,
                    top: _dragPosition!.dy - squareSize / 2,
                    child: _buildPiece(_getPieceAt(_dragFrom!), squareSize * 1.1, true),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBoard(double squareSize) {
    final board = _fenToBoard();
    final squares = <Widget>[];

    for (int rank = 0; rank < 8; rank++) {
      for (int file = 0; file < 8; file++) {
        final displayRank = widget.isFlipped ? rank : 7 - rank;
        final displayFile = widget.isFlipped ? 7 - file : file;
        final isLight = (displayRank + displayFile) % 2 == 0;

        final squareName = String.fromCharCode(97 + displayFile) + (displayRank + 1).toString();
        final piece = board[displayRank][displayFile];

        squares.add(
          Positioned(
            left: file * squareSize,
            top: rank * squareSize,
            child: Container(
              width: squareSize,
              height: squareSize,
              decoration: BoxDecoration(
                color: _getSquareColor(squareName, isLight),
                border: widget.lastMoveTo == squareName || widget.lastMoveFrom == squareName
                    ? Border.all(color: Colors.yellow.withOpacity(0.5), width: 2)
                    : null,
              ),
              child: Stack(
                children: [
                  if (_legalMoves.contains(squareName) && piece == '')
                    Center(
                      child: Container(
                        width: squareSize * 0.3,
                        height: squareSize * 0.3,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryGreen.withOpacity(0.4),
                        ),
                      ),
                    ),
                  if (_legalMoves.contains(squareName) && piece != '')
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: AppTheme.errorRed.withOpacity(0.3),
                      ),
                    ),
                  if (piece != '')
                    Center(
                      child: _buildPiece(piece, squareSize, false),
                    ),
                  if (widget.showCoordinates && file == (widget.isFlipped ? 7 : 0))
                    Positioned(
                      left: 2,
                      bottom: 0,
                      child: Text(
                        squareName[1],
                        style: TextStyle(
                          color: isLight ? AppTheme.boardGreenDark.withOpacity(0.7) : AppTheme.boardGreenLight.withOpacity(0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (widget.showCoordinates && rank == (widget.isFlipped ? 0 : 7))
                    Positioned(
                      right: 2,
                      top: 0,
                      child: Text(
                        squareName[0].toUpperCase(),
                        style: TextStyle(
                          color: isLight ? AppTheme.boardGreenDark.withOpacity(0.7) : AppTheme.boardGreenLight.withOpacity(0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return Stack(children: squares);
  }

  Widget _buildPiece(String piece, double size, bool isDragging) {
    return Transform.scale(
      scale: isDragging ? 1.1 : 1.0,
      child: Text(
        _unicodePieces[piece] ?? '',
        style: TextStyle(
          fontSize: size * 0.75,
          color: piece == piece.toUpperCase() ? Colors.white : Colors.black,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSquareColor(String square, bool isLight) {
    if (_selectedSquare == square) {
      return AppTheme.primaryGreen.withOpacity(0.6);
    }
    if (widget.lastMoveFrom == square || widget.lastMoveTo == square) {
      return Colors.yellow.withOpacity(0.3);
    }
    if (widget.highlightedSquares?.contains(square) ?? false) {
      return AppTheme.primaryGreen.withOpacity(0.4);
    }
    return isLight ? AppTheme.boardGreenDark : AppTheme.boardGreenLight;
  }

  void _handleTap(TapDownDetails details, double squareSize, double boardSize) {
    final file = (details.localPosition.dx / squareSize).floor();
    final rank = (details.localPosition.dy / squareSize).floor();

    if (file < 0 || file > 7 || rank < 0 || rank > 7) return;

    final displayFile = widget.isFlipped ? 7 - file : file;
    final displayRank = widget.isFlipped ? rank : 7 - rank;

    final squareName = String.fromCharCode(97 + displayFile) + (displayRank + 1).toString();

    if (_selectedSquare == null) {
      final piece = _getPieceAt(squareName);
      if (piece != '') {
        setState(() {
          _selectedSquare = squareName;
          _legalMoves = _getLegalMovesForSquare(squareName);
        });
      }
    } else {
      if (_legalMoves.contains(squareName) && widget.onMove != null) {
        widget.onMove!(_selectedSquare!, squareName);
      }
      setState(() {
        _selectedSquare = null;
        _legalMoves = [];
      });
    }
  }

  String _getPieceAt(String square) {
    final board = _fenToBoard();
    final file = square.codeUnitAt(0) - 97;
    final rank = int.parse(square[1]) - 1;
    return board[7 - rank][file];
  }

  List<String> _getLegalMovesForSquare(String square) {
    final piece = _getPieceAt(square);
    if (piece == '') return [];

    final file = square.codeUnitAt(0) - 97;
    final rank = int.parse(square[1]) - 1;
    final pieceType = piece.toLowerCase();
    final isWhite = piece == piece.toUpperCase();
    final moves = <String>[];

    switch (pieceType) {
      case 'p':
        final dir = isWhite ? 1 : -1;
        final startRank = isWhite ? 1 : 6;

        if (rank + dir >= 0 && rank + dir < 8) {
          if (_getPieceAt(String.fromCharCode(97 + file) + (rank + dir + 1).toString()) == '') {
            moves.add(String.fromCharCode(97 + file) + (rank + dir + 1).toString());
            if (rank == startRank) {
              if (_getPieceAt(String.fromCharCode(97 + file) + (rank + 2 * dir + 1).toString()) == '') {
                moves.add(String.fromCharCode(97 + file) + (rank + 2 * dir + 1).toString());
              }
            }
          }
          if (file > 0) {
            final cap = _getPieceAt(String.fromCharCode(97 + file - 1) + (rank + dir + 1).toString());
            if (cap != '' && (cap == cap.toUpperCase()) != isWhite) {
              moves.add(String.fromCharCode(97 + file - 1) + (rank + dir + 1).toString());
            }
          }
          if (file < 7) {
            final cap = _getPieceAt(String.fromCharCode(97 + file + 1) + (rank + dir + 1).toString());
            if (cap != '' && (cap == cap.toUpperCase()) != isWhite) {
              moves.add(String.fromCharCode(97 + file + 1) + (rank + dir + 1).toString());
            }
          }
        }
        break;

      case 'n':
        const offsets = [[-2, -1], [-2, 1], [-1, -2], [-1, 2], [1, -2], [1, 2], [2, -1], [2, 1]];
        for (final o in offsets) {
          final r = rank + o[0];
          final f = file + o[1];
          if (r >= 0 && r < 8 && f >= 0 && f < 8) {
            final target = _getPieceAt(String.fromCharCode(97 + f) + (r + 1).toString());
            if (target == '' || (target == target.toUpperCase()) != isWhite) {
              moves.add(String.fromCharCode(97 + f) + (r + 1).toString());
            }
          }
        }
        break;

      case 'b':
        for (final d in [[-1, -1], [-1, 1], [1, -1], [1, 1]]) {
          for (int i = 1; i < 8; i++) {
            final r = rank + d[0] * i;
            final f = file + d[1] * i;
            if (r < 0 || r >= 8 || f < 0 || f >= 8) break;
            final target = _getPieceAt(String.fromCharCode(97 + f) + (r + 1).toString());
            if (target == '') {
              moves.add(String.fromCharCode(97 + f) + (r + 1).toString());
            } else {
              if ((target == target.toUpperCase()) != isWhite) {
                moves.add(String.fromCharCode(97 + f) + (r + 1).toString());
              }
              break;
            }
          }
        }
        break;

      case 'r':
        for (final d in [[-1, 0], [1, 0], [0, -1], [0, 1]]) {
          for (int i = 1; i < 8; i++) {
            final r = rank + d[0] * i;
            final f = file + d[1] * i;
            if (r < 0 || r >= 8 || f < 0 || f >= 8) break;
            final target = _getPieceAt(String.fromCharCode(97 + f) + (r + 1).toString());
            if (target == '') {
              moves.add(String.fromCharCode(97 + f) + (r + 1).toString());
            } else {
              if ((target == target.toUpperCase()) != isWhite) {
                moves.add(String.fromCharCode(97 + f) + (r + 1).toString());
              }
              break;
            }
          }
        }
        break;

      case 'q':
        for (final d in [[-1, -1], [-1, 0], [-1, 1], [0, -1], [0, 1], [1, -1], [1, 0], [1, 1]]) {
          for (int i = 1; i < 8; i++) {
            final r = rank + d[0] * i;
            final f = file + d[1] * i;
            if (r < 0 || r >= 8 || f < 0 || f >= 8) break;
            final target = _getPieceAt(String.fromCharCode(97 + f) + (r + 1).toString());
            if (target == '') {
              moves.add(String.fromCharCode(97 + f) + (r + 1).toString());
            } else {
              if ((target == target.toUpperCase()) != isWhite) {
                moves.add(String.fromCharCode(97 + f) + (r + 1).toString());
              }
              break;
            }
          }
        }
        break;

      case 'k':
        for (final d in [[-1, -1], [-1, 0], [-1, 1], [0, -1], [0, 1], [1, -1], [1, 0], [1, 1]]) {
          final r = rank + d[0];
          final f = file + d[1];
          if (r >= 0 && r < 8 && f >= 0 && f < 8) {
            final target = _getPieceAt(String.fromCharCode(97 + f) + (r + 1).toString());
            if (target == '' || (target == target.toUpperCase()) != isWhite) {
              moves.add(String.fromCharCode(97 + f) + (r + 1).toString());
            }
          }
        }
        break;
    }

    return moves;
  }

  List<List<String>> _fenToBoard() {
    final board = List.generate(8, (_) => List.filled(8, ''));
    final rows = widget.fen.split(' ')[0].split('/');

    for (int r = 0; r < 8; r++) {
      int c = 0;
      for (int i = 0; i < rows[r].length; i++) {
        final ch = rows[r][i];
        if (int.tryParse(ch) != null) {
          c += int.parse(ch);
        } else {
          board[r][c] = ch;
          c++;
        }
      }
    }

    return board;
  }
}
