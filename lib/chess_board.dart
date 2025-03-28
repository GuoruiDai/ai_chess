import 'package:flutter/material.dart';
import 'chess.dart' as chess_lib;


class Square extends StatelessWidget {
  final bool isValidMove;
  final bool isSelected;
  final bool isWhiteSquare;
  final chess_lib.Piece? piece;
  final VoidCallback? onTap;
  final String? rankLabel;
  final String? fileLabel;

  const Square({
    super.key,
    required this.isValidMove,
    required this.isSelected,
    required this.isWhiteSquare,
    required this.piece,
    required this.onTap,
    this.rankLabel,
    this.fileLabel,
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
    final glowColor = const Color.fromARGB(195, 255, 255, 255);
    final blueTint = const Color.fromARGB(171, 63, 119, 216);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Base square
          Container(
            color: baseColor,
          ),
          
          // Glow effect for both selected square and valid moves
          if (isSelected || isValidMove)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: glowColor,
                    width: 0.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: blueTint,
                      spreadRadius: 1.5,
                      blurRadius: 2.0,
                    ),
                    BoxShadow(
                      color: glowColor,
                      spreadRadius: 0.5,
                      blurRadius: 2.0,
                    ),
                  ],
                ),
              ),
            ),
          
          // Piece image
          if (piece != null)
            Positioned.fill(
              child: Image.asset(
                _getPieceImage(piece!.type),
                color: piece!.color == chess_lib.Color.WHITE 
                    ? Colors.white 
                    : const Color.fromARGB(255, 109, 109, 109),
                colorBlendMode: BlendMode.modulate,
              ),
            ),
          
          // Labels
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

  const ChessBoard({
    super.key,
    required this.chess,
    required this.selectedSquare,
    required this.validMoves,
    required this.isFlipped,
    required this.onSquareSelected,
  });

  int _gridIndexToSquare(int index) {
    final row = index ~/ 8;
    final col = index % 8;
    
    if (isFlipped) {
      final flippedRow = 7 - row;
      final flippedCol = 7 - col;
      return flippedRow * 16 + flippedCol;
    }
    return row * 16 + col;
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
        final gridRow = index ~/ 8;
        final gridCol = index % 8;
        
        final square = _gridIndexToSquare(index);
        final piece = chess.board[square];
        final isSelected = selectedSquare == square;
        final isValidMove = validMoves.any((m) => m.to == square);

        final file = square % 16;
        final rank = square ~/ 16;
        final isWhiteSquare = (rank + file) % 2 == 0;

        // Determine rank label (only for leftmost column)
        String? rankLabel;
        if (gridCol == 0) {
          // Rank labels are always 8-1 from top to bottom
          final rankNumber = isFlipped ? (gridRow + 1) : (8 - gridRow);
          rankLabel = rankNumber.toString();
        }

        // Determine file label (only for bottom row)
        String? fileLabel;
        if (gridRow == 7) {
          // File labels are always a-h from left to right
          final fileChar = isFlipped ? 
              String.fromCharCode(104 - gridCol) : // 'h' (ASCII 104) down to 'a'
              String.fromCharCode(97 + gridCol);   // 'a' (ASCII 97) up to 'h'
          fileLabel = fileChar;
        }

        return Square(
          isValidMove: isValidMove,
          isSelected: isSelected,
          isWhiteSquare: isWhiteSquare,
          piece: piece,
          onTap: () => onSquareSelected?.call(square),
          rankLabel: rankLabel,
          fileLabel: fileLabel,
        );
      },
    );
  }
}