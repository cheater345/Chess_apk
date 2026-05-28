import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/theme.dart';

class ChessBoardWidget extends StatefulWidget {
  final String fen;
  final bool isFlipped;
  final bool interactive;
  final Function(String from, String to, {String? promotion})? onMove;
  final String? playerColor;

  const ChessBoardWidget({
    super.key,
    required this.fen,
    this.isFlipped = false,
    this.interactive = false,
    this.onMove,
    this.playerColor,
  });

  @override
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget> {
  String? _selectedSquare;
  bool _isDragging = false;
  String? _dragFrom;
  Offset? _dragPosition;
  Offset? _pointerDownPos;

  static const _lightSquare = Color(0xFFF0D9B5);
  static const _darkSquare = Color(0xFFB58863);
  static const _selectedColor = Color(0x6082962C);
  static const _lastMoveColor = Color(0x6082962C);

  bool _allowedToSelect(String piece) {
    final isWhite = piece == piece.toUpperCase();
    if (widget.playerColor != null) {
      final turn = widget.fen.split(' ').length > 1 ? widget.fen.split(' ')[1] : 'w';
      final playerTurn = turn == (widget.playerColor == 'white' ? 'w' : 'b');
      return playerTurn && (isWhite ? 'white' : 'black') == widget.playerColor;
    }
    return true;
  }

  bool _isPromotion(String from, String to) {
    final piece = _getPieceAt(from);
    if (piece == '') return false;
    final isWhite = piece == piece.toUpperCase();
    final toRank = int.parse(to[1]);
    if (isWhite && toRank == 8) return true;
    if (!isWhite && toRank == 1) return true;
    return false;
  }

  Future<String?> _showPromotionDialog(bool isWhite) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Promote Pawn', style: TextStyle(color: Colors.white)),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['q', 'r', 'b', 'n'].map((p) {
            final fn = 'assets/images/pieces/${isWhite ? 'w' : 'b'}${p.toUpperCase()}.svg';
            return GestureDetector(
              onTap: () => Navigator.pop(ctx, p),
              child: Container(
                width: 56, height: 56,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SvgPicture.asset(fn, width: 44, height: 44),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _doMove(String from, String to) async {
    if (widget.onMove == null) return;
    String? promotion;
    if (_isPromotion(from, to)) {
      final piece = _getPieceAt(from);
      promotion = await _showPromotionDialog(piece == piece.toUpperCase());
      if (promotion == null) return;
    }
    widget.onMove!(from, to, promotion: promotion);
  }

  (int, int) _tapToBoardCoords(Offset pos, double sqSize) {
    final file = (pos.dx / sqSize).floor();
    final rank = (pos.dy / sqSize).floor();
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

  void _onPanStart(DragStartDetails details, double sqSize) {
    final pos = details.localPosition;
    final (f, r) = _tapToBoardCoords(pos, sqSize);
    if (f < 0 || f > 7 || r < 0 || r > 7) return;
    final square = _coordsToSquare(f, r);
    final piece = _getPieceAt(square);
    if (piece == '' || !_allowedToSelect(piece)) return;
    _pointerDownPos = pos;
    _isDragging = false;
    _dragFrom = square;
    _dragPosition = pos;
    _selectedSquare = square;
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragFrom == null) return;
    final dist = (details.localPosition - (_pointerDownPos ?? details.localPosition)).distance;
    if (dist > 10) _isDragging = true;
    _dragPosition = details.localPosition;
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details, double sqSize) {
    if (_dragFrom == null) { setState(() { _selectedSquare = null; }); return; }
    final pos = _dragPosition ?? details.localPosition;
    final (f, r) = _tapToBoardCoords(pos, sqSize);
    final target = _coordsToSquare(f, r);
    if (target != _dragFrom) _doMove(_dragFrom!, target);
    setState(() { _isDragging = false; _dragFrom = null; _dragPosition = null; _pointerDownPos = null; _selectedSquare = null; });
  }

  void _handleTap(TapUpDetails details, double sqSize) {
    final pos = details.localPosition;
    final (f, r) = _tapToBoardCoords(pos, sqSize);
    if (f < 0 || f > 7 || r < 0 || r > 7) return;
    final square = _coordsToSquare(f, r);

    if (_selectedSquare == null) {
      final piece = _getPieceAt(square);
      if (piece == '' || !_allowedToSelect(piece)) return;
      _selectedSquare = square;
      setState(() {});
    } else {
      if (square != _selectedSquare) _doMove(_selectedSquare!, square);
      _selectedSquare = null;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.maxWidth;
        final sqSize = boardSize / 8;

        return GestureDetector(
          onTapUp: widget.interactive ? (d) => _handleTap(d, sqSize) : null,
          onPanStart: widget.interactive ? (d) => _onPanStart(d, sqSize) : null,
          onPanUpdate: widget.interactive && _isDragging ? _onPanUpdate : null,
          onPanEnd: widget.interactive && _isDragging ? (d) => _onPanEnd(d, sqSize) : null,
          child: Container(
            width: boardSize, height: boardSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 10))],
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
                      child: _buildPiece(_getPieceAt(_dragFrom!), sqSize * 1.15),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBoard(double sqSize) {
    final board = _fenToBoard();
    final pieces = <Widget>[];

    for (int rank = 0; rank < 8; rank++) {
      for (int file = 0; file < 8; file++) {
        final dr = widget.isFlipped ? 7 - rank : rank;
        final df = widget.isFlipped ? 7 - file : file;
        final sq = '${String.fromCharCode(97 + df)}${dr + 1}';
        final piece = board[dr][df];
        final isLight = (dr + df) % 2 == 0;
        final isSelected = _selectedSquare == sq;

        pieces.add(Positioned(
          left: file * sqSize, top: rank * sqSize,
          child: Container(
            width: sqSize, height: sqSize,
            decoration: BoxDecoration(
              color: isSelected
                  ? _selectedColor
                  : isLight ? _lightSquare : _darkSquare,
            ),
            child: piece != '' ? Center(child: _buildPiece(piece, sqSize)) : null,
          ),
        ));
      }
    }

    return Stack(children: pieces);
  }

  Widget _buildPiece(String piece, double size) {
    final isWhite = 'PKQRBN'.contains(piece);
    final fn = 'assets/images/pieces/${isWhite ? 'w' : 'b'}${piece.toUpperCase()}.svg';
    return SvgPicture.asset(fn, width: size * 0.85, height: size * 0.85, fit: BoxFit.contain);
  }

  String _getPieceAt(String square) {
    final board = _fenToBoard();
    final file = square.codeUnitAt(0) - 97;
    final rank = int.parse(square[1]) - 1;
    return board[7 - rank][file];
  }

  List<List<String>> _fenToBoard() {
    final board = List.generate(8, (_) => List.filled(8, ''));
    final rows = widget.fen.split(' ')[0].split('/');
    for (int r = 0; r < 8; r++) {
      int c = 0;
      for (int i = 0; i < rows[r].length; i++) {
        final ch = rows[r][i];
        if (int.tryParse(ch) != null) { c += int.parse(ch); }
        else { board[r][c++] = ch; }
      }
    }
    return board;
  }
}
