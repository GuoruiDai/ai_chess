import 'package:flutter/material.dart';
import 'chess.dart' as chess_lib;

class Square extends StatelessWidget {
  final Color? highlightColor;
  final bool isSelected;
  final bool isWhiteSquare;
  final chess_lib.Piece? piece;
  final VoidCallback? onTap;
  final String? rankLabel;
  final String? fileLabel;
  final bool isInCheck;
  final Color checkHighlightColor;

  const Square({
    super.key,
    this.highlightColor,
    required this.isSelected,
    required this.isWhiteSquare,
    required this.piece,
    required this.onTap,
    this.rankLabel,
    this.fileLabel,
    this.isInCheck = false,
    this.checkHighlightColor = const Color(0x55FF0000),
  });

  String _getPieceImage(chess_lib.PieceType type) {
    switch (type) {
      case chess_lib.PieceType.PAWN: return 'images/p.png';
      case chess_lib.PieceType.KNIGHT: return 'images/n.png';
      case chess_lib.PieceType.BISHOP: return 'images/b.png';
      case chess_lib.PieceType.ROOK: return 'images/r.png';
      case chess_lib.PieceType.QUEEN: return 'images/q.png';
      case chess_lib.PieceType.KING: return 'images/k.png';
    }
    throw ArgumentError('Unknown piece type: $type');
  }

  @override
  Widget build(BuildContext context) {
    Color baseColor = isWhiteSquare 
        ? const Color.fromARGB(255, 218, 218, 218) 
        : const Color.fromARGB(255, 53, 54, 56);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(color: baseColor),
          
          if (isInCheck)
            Positioned.fill(
              child: Container(color: checkHighlightColor),
            ),
          
          if (highlightColor != null)
            Positioned.fill(
              child: Container(
                color: highlightColor,
              ),
            ),

          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromARGB(139, 138, 138, 138),
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(139, 138, 138, 138),
                      spreadRadius: 1,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),

          if (piece != null)
            Positioned.fill(
              child: Image.asset(
                _getPieceImage(piece!.type),
                color: piece!.color == chess_lib.Color.WHITE 
                    ? Colors.white 
                    : Color.fromARGB(255, 109, 109, 109),
                colorBlendMode: BlendMode.modulate,
              ),
            ),
          
          if (rankLabel != null)
            Positioned(
              left: 4,
              top: 4,
              child: Text(
                rankLabel!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isWhiteSquare ? const Color(0xFF779556) : const Color(0xFFEBECD0),
                ),
              ),
            ),
          if (fileLabel != null)
            Positioned(
              right: 4,
              bottom: 4,
              child: Text(
                fileLabel!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isWhiteSquare ? const Color(0xFF779556) : const Color(0xFFEBECD0),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ChessBoard extends StatelessWidget {
  final chess_lib.Chess chess;
  final int? selectedSquare;
  final List<chess_lib.Move> validMoves;
  final bool isFlipped;
  final void Function(int)? onSquareSelected;
  final int? checkHighlight;
  final chess_lib.Move? lastMove;
  final chess_lib.Move? engineSuggestion;

  const ChessBoard({
    super.key,
    required this.chess,
    required this.selectedSquare,
    required this.validMoves,
    required this.isFlipped,
    required this.onSquareSelected,
    this.checkHighlight,
    this.lastMove,
    this.engineSuggestion,
  });

  int _gridIndexToSquare(int index) {
    final row = index ~/ 8;
    final col = index % 8;
    return isFlipped ? (7 - row) * 16 + (7 - col) : row * 16 + col;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
      ),
      itemCount: 64,
      itemBuilder: (context, index) {
        final square = _gridIndexToSquare(index);
        final isFrom = lastMove?.from == square;
        final isTo = lastMove?.to == square;
        final isValidMove = validMoves.any((m) => m.to == square);
        final isEngineSuggestion = engineSuggestion != null && 
            (engineSuggestion!.from == square || engineSuggestion!.to == square);

        Color? highlightColor;
        if (checkHighlight == square) {
          highlightColor = const Color(0x55FF0000); // Red for check
        } else if (isEngineSuggestion) {
          highlightColor = const Color(0x5500FF00); // Green for engine suggestion
        } else if (isFrom || isTo) {
          highlightColor = const Color(0x5533B5E5); // Blue for last move
        } else if (isValidMove) {
          highlightColor = const Color(0x5563B5E5); // Light blue for valid moves
        }

        return Square(
          highlightColor: highlightColor,
          isSelected: selectedSquare == square,
          isWhiteSquare: (square ~/ 16 + square % 16) % 2 == 0,
          piece: chess.board[square],
          onTap: () => onSquareSelected?.call(square),
          rankLabel: index % 8 == 0 
              ? (isFlipped ? (index ~/ 8 + 1).toString() : (8 - index ~/ 8).toString())
              : null,
          fileLabel: index >= 56 
              ? String.fromCharCode(isFlipped ? 104 - (index % 8) : 97 + (index % 8))
              : null,
          isInCheck: checkHighlight == square,
        );
      },
    );
  }
}