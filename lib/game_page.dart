import 'package:flutter/material.dart';
import 'chess.dart' as chess_lib;
import 'chess_board.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late chess_lib.Chess chess;
  int? selectedSquare;
  List<chess_lib.Move> validMoves = [];
  bool isPlayerAsBlack = false;
  bool gameStarted = false; // Track if game has started

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    chess = chess_lib.Chess();
    selectedSquare = null;
    validMoves = [];
    gameStarted = false; // Reset game state
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
    });
  }

  void _handleSquareTap(int square) {
    if (!gameStarted) return;
    final piece = chess.board[square];
    if (piece != null && piece.color != (isPlayerAsBlack ? chess_lib.Color.BLACK : chess_lib.Color.WHITE)) {
      return;
    }

    setState(() {
      final moves = chess.generate_moves({'square': chess_lib.Chess.algebraic(square)});
      
      if (selectedSquare == square) {
        selectedSquare = null;
        validMoves = [];
      } else if (moves.isNotEmpty) {
        selectedSquare = square;
        validMoves = moves;
      } else if (selectedSquare != null) {
        final matchingMoves = validMoves.where((m) => m.to == square);
        if (matchingMoves.isNotEmpty) {
          _makeMove(matchingMoves.first);
          selectedSquare = null;
          validMoves = [];
        }
      }
    });
  }

  void _makeMove(chess_lib.Move move) {
    chess.make_move(move);
    if (chess.game_over) {
      _showGameOverDialog();
    }
    setState(() {}); // Update UI after move
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(chess.in_checkmate ? "CHECKMATE!" : "GAME OVER"),
        content: Text(chess.in_checkmate
            ? "${chess.turn == chess_lib.Color.BLACK ? "White" : "Black"} wins!"
            : "Draw"),
        actions: [
          TextButton(
            onPressed: () {
              _initializeGame();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("New Game"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _initializeGame();
              setState(() {});
            },
          ),
          // Only show flip button if game hasn't started
          if (!gameStarted) IconButton(
            icon: Icon(isPlayerAsBlack ? Icons.rotate_90_degrees_ccw : Icons.rotate_90_degrees_cw),
            onPressed: () {
              setState(() {
                isPlayerAsBlack = !isPlayerAsBlack;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Text(
            chess.in_check ? "CHECK!" : "",
            style: const TextStyle(
              color: Colors.red,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: ChessBoard(
              chess: chess,
              selectedSquare: selectedSquare,
              validMoves: validMoves,
              isFlipped: isPlayerAsBlack,
              onSquareSelected: _handleSquareTap,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Turn: ${chess.turn == chess_lib.Color.WHITE ? 'White' : 'Black'}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Start game button (only shown when game hasn't started)
          if (!gameStarted) Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: ElevatedButton(
              onPressed: _startGame,
              child: const Text('Start Game'),
            ),
          ),
        ],
      ),
    );
  }
}