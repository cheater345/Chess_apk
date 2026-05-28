import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

class _ChessBoardWidgetState extends State<ChessBoardWidget>
    with SingleTickerProviderStateMixin {
  String? _selectedSquare;
  List<String> _legalMoves = [];
  bool _isDragging = false;
  String? _dragFrom;
  Offset? _dragPosition;
  Offset? _pointerDownPos;
  late AnimationController _pulseController;
  Set<String> _lastMoveSquares = {};

  final Set<String> _whitePieces = {'K', 'Q', 'R', 'B', 'N', 'P'};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _updateLastMoveSquares();
  }

  @override
  void didUpdateWidget(ChessBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fen != widget.fen) {
      _selectedSquare = null;
      _legalMoves = [];
      _updateLastMoveSquares();
    }
  }

  void _updateLastMoveSquares() {
    _lastMoveSquares = {};
    if (widget.lastMoveFrom != null) _lastMoveSquares.add(widget.lastMoveFrom!);
    if (widget.lastMoveTo != null) _lastMoveSquares.add(widget.lastMoveTo!);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  (int, int) _tapToBoardCoords(Offset localPos, double sqSize) {
    final file = (localPos.dx / sqSize).floor();
    final rank = (localPos.dy / sqSize).floor();
    return (file.clamp(0, 7), rank.clamp(0, 7));
  }

  String _coordsToSquare(int file, int rank) {
    final df = widget.isFlipped ? 7 - file : file;
    final dr = widget.isFlipped ? rank : 7 - rank;
    return '${String.fromCharCode(97 + df)}${dr + 1}';
  }

  (int, int) _squareToCoords(String square) {
    final file = square.codeUnitAt(0) - 97;
    final rank = int.parse(square[1]) - 1;
    final df = widget.isFlipped ? 7 - file : file;
    final dr = widget.isFlipped ? rank : 7 - rank;
    return (df, dr);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.maxWidth;
        final sqSize = boardSize / 8;

        return GestureDetector(
          onTapUp: widget.interactive ? (details) => _handleTap(details, sqSize) : null,
          onPanStart: widget.interactive ? (details) => _onPanStart(details, sqSize) : null,
          onPanUpdate: widget.interactive && _isDragging ? (details) => _onPanUpdate(details) : null,
          onPanEnd: widget.interactive && _isDragging ? (details) => _onPanEnd(details, sqSize) : null,
          child: Container(
            width: boardSize,
            height: boardSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  _buildBoard(sqSize),
                  if (_isDragging && _dragFrom != null && _dragPosition != null)
                    Positioned(
                      left: _dragPosition!.dx - sqSize / 2,
                      top: _dragPosition!.dy - sqSize / 2,
                      child: _buildPiece(
                        _getPieceAt(_dragFrom!),
                        sqSize * 1.15,
                        true,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String get _activeColor => widget.fen.split(' ').length > 1 ? widget.fen.split(' ')[1] : 'w';

  void _onPanStart(DragStartDetails details, double sqSize) {
    final pos = details.localPosition;
    final (f, r) = _tapToBoardCoords(pos, sqSize);
    if (f < 0 || f > 7 || r < 0 || r > 7) return;

    final square = _coordsToSquare(f, r);
    final piece = _getPieceAt(square);
    if (piece == '') return;

    final isWhite = piece == piece.toUpperCase();
    if ((isWhite ? 'w' : 'b') != _activeColor) return;

    _pointerDownPos = pos;
    _isDragging = false;
    _dragFrom = square;
    _dragPosition = pos;
    _selectedSquare = square;
    _legalMoves = _getLegalMovesForSquare(square);
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragFrom == null) return;
    final dist = (details.localPosition - (_pointerDownPos ?? details.localPosition)).distance;
    if (dist > 10) _isDragging = true;
    setState(() {
      _dragPosition = details.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails details, double sqSize) {
    if (_dragFrom == null) return;

    final pos = _dragPosition ?? details.localPosition;
    final (f, r) = _tapToBoardCoords(pos, sqSize);
    final targetSquare = _coordsToSquare(f, r);

    if (_legalMoves.contains(targetSquare) && widget.onMove != null) {
      widget.onMove!(_dragFrom!, targetSquare);
    }

    setState(() {
      _isDragging = false;
      _dragFrom = null;
      _dragPosition = null;
      _pointerDownPos = null;
      _selectedSquare = null;
      _legalMoves = [];
    });
  }

  void _handleTap(TapUpDetails details, double sqSize) {
    final pos = details.localPosition;
    final (f, r) = _tapToBoardCoords(pos, sqSize);
    if (f < 0 || f > 7 || r < 0 || r > 7) return;

    final square = _coordsToSquare(f, r);

    if (_selectedSquare == null) {
      final piece = _getPieceAt(square);
      if (piece != '') {
        final isWhite = piece == piece.toUpperCase();
        if ((isWhite ? 'w' : 'b') != _activeColor) return;
        setState(() {
          _selectedSquare = square;
          _legalMoves = _getLegalMovesForSquare(square);
        });
      }
    } else {
      if (_legalMoves.contains(square) && widget.onMove != null) {
        widget.onMove!(_selectedSquare!, square);
      }
      setState(() {
        _selectedSquare = null;
        _legalMoves = [];
      });
    }
  }

  Widget _buildBoard(double sqSize) {
    final board = _fenToBoard();
    final pieces = <Widget>[];

    for (int rank = 0; rank < 8; rank++) {
      for (int file = 0; file < 8; file++) {
        final dr = widget.isFlipped ? 7 - rank : rank;
        final df = widget.isFlipped ? 7 - file : file;

        final squareName = '${String.fromCharCode(97 + df)}${dr + 1}';
        final piece = board[dr][df];
        final isLight = (dr + df) % 2 == 0;
        final isLastMove = _lastMoveSquares.contains(squareName);
        final isSelected = _selectedSquare == squareName;
        final isLegalTarget = _legalMoves.contains(squareName) && _selectedSquare != null;

        pieces.add(
          Positioned(
            left: file * sqSize,
            top: rank * sqSize,
            child: Container(
              width: sqSize,
              height: sqSize,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryGreen.withOpacity(0.5)
                    : isLastMove
                        ? const Color(0x55FFFF00)
                        : isLight
                            ? AppTheme.boardGreenLight
                            : AppTheme.boardGreenDark,
              ),
              child: Stack(
                children: [
                  if (isLegalTarget)
                    piece == ''
                        ? Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3), width: 1),
                              borderRadius: BorderRadius.circular(sqSize * 0.06),
                            ),
                            child: Center(
                              child: Container(
                                width: sqSize * 0.33,
                                height: sqSize * 0.33,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primaryGreen.withOpacity(0.65),
                                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))],
                                ),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.errorRed.withOpacity(0.8), width: 2.5),
                              borderRadius: BorderRadius.circular(sqSize * 0.06),
                            ),
                          ),
                  if (piece != '')
                    Center(
                      child: _buildPiece(piece, sqSize, false),
                    ),
                  if (widget.showCoordinates && file == (widget.isFlipped ? 7 : 0))
                    Positioned(
                      left: 2,
                      bottom: 1,
                      child: Text(
                        squareName[1],
                        style: TextStyle(
                          color: isLight
                              ? AppTheme.boardGreenDark.withOpacity(0.6)
                              : AppTheme.boardGreenLight.withOpacity(0.6),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (widget.showCoordinates && rank == (widget.isFlipped ? 0 : 7))
                    Positioned(
                      right: 2,
                      top: 1,
                      child: Text(
                        squareName[0].toUpperCase(),
                        style: TextStyle(
                          color: isLight
                              ? AppTheme.boardGreenDark.withOpacity(0.6)
                              : AppTheme.boardGreenLight.withOpacity(0.6),
                          fontSize: 9,
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

    return Stack(children: pieces);
  }

  Widget _buildPiece(String piece, double size, bool isDragging) {
    final isWhite = _whitePieces.contains(piece);
    final fn = 'assets/images/pieces/${isWhite ? 'w' : 'b'}${piece.toUpperCase()}.svg';
    return AnimatedScale(
      scale: isDragging ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: SvgPicture.asset(
        fn,
        width: size * 0.88,
        height: size * 0.88,
        fit: BoxFit.contain,
      ),
    );
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
          if (_getPieceAt('${String.fromCharCode(97 + file)}${rank + dir + 1}') == '') {
            moves.add('${String.fromCharCode(97 + file)}${rank + dir + 1}');
            if (rank == startRank) {
              if (_getPieceAt('${String.fromCharCode(97 + file)}${rank + 2 * dir + 1}') == '') {
                moves.add('${String.fromCharCode(97 + file)}${rank + 2 * dir + 1}');
              }
            }
          }
          if (file > 0) {
            final cap = _getPieceAt('${String.fromCharCode(97 + file - 1)}${rank + dir + 1}');
            if (cap != '' && (cap == cap.toUpperCase()) != isWhite) {
              moves.add('${String.fromCharCode(97 + file - 1)}${rank + dir + 1}');
            }
          }
          if (file < 7) {
            final cap = _getPieceAt('${String.fromCharCode(97 + file + 1)}${rank + dir + 1}');
            if (cap != '' && (cap == cap.toUpperCase()) != isWhite) {
              moves.add('${String.fromCharCode(97 + file + 1)}${rank + dir + 1}');
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
            final target = _getPieceAt('${String.fromCharCode(97 + f)}${r + 1}');
            if (target == '' || (target == target.toUpperCase()) != isWhite) {
              moves.add('${String.fromCharCode(97 + f)}${r + 1}');
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
            final target = _getPieceAt('${String.fromCharCode(97 + f)}${r + 1}');
            if (target == '') {
              moves.add('${String.fromCharCode(97 + f)}${r + 1}');
            } else {
              if ((target == target.toUpperCase()) != isWhite) {
                moves.add('${String.fromCharCode(97 + f)}${r + 1}');
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
            final target = _getPieceAt('${String.fromCharCode(97 + f)}${r + 1}');
            if (target == '') {
              moves.add('${String.fromCharCode(97 + f)}${r + 1}');
            } else {
              if ((target == target.toUpperCase()) != isWhite) {
                moves.add('${String.fromCharCode(97 + f)}${r + 1}');
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
            final target = _getPieceAt('${String.fromCharCode(97 + f)}${r + 1}');
            if (target == '') {
              moves.add('${String.fromCharCode(97 + f)}${r + 1}');
            } else {
              if ((target == target.toUpperCase()) != isWhite) {
                moves.add('${String.fromCharCode(97 + f)}${r + 1}');
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
            final target = _getPieceAt('${String.fromCharCode(97 + f)}${r + 1}');
            if (target == '' || (target == target.toUpperCase()) != isWhite) {
              moves.add('${String.fromCharCode(97 + f)}${r + 1}');
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
