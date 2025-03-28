import 'package:flutter/material.dart';
import 'package:stockfish/stockfish.dart';
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
  bool gameStarted = false;
  late Stockfish stockfish;
  bool isEngineThinking = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _initStockfish();
  }

  void _initStockfish() async {
    stockfish = Stockfish();
    stockfish.stdout.listen(_handleEngineResponse);
    
    // Wait until engine is ready
    while (stockfish.state.value != StockfishState.ready) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void _initializeGame() {
    chess = chess_lib.Chess();
    selectedSquare = null;
    validMoves = [];
    gameStarted = false;
    isEngineThinking = false;
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      // If player is black, engine makes first move
      if (isPlayerAsBlack) {
        _getEngineMove();
      }
    });
  }

  void _handleEngineResponse(String line) {
    if (line.startsWith('bestmove ')) {
      final parts = line.split(' ');
      if (parts.length >= 2) {
        final moveUci = parts[1];
        _handleEngineMove(moveUci);
      }
    }
  }

  void _handleEngineMove(String moveUci) {
    // Parse UCI move (e.g. 'e2e4' or 'h7h8q')
    final from = moveUci.substring(0, 2);
    final to = moveUci.substring(2, 4);
    final promotion = moveUci.length > 4 ? moveUci[4].toLowerCase() : null;

    // Find matching legal move
    final moves = chess.generate_moves();
    chess_lib.Move? engineMove;
    
    for (final move in moves) {
      if (move.fromAlgebraic == from && 
          move.toAlgebraic == to &&
          (promotion == null || 
           move.promotion?.name.toLowerCase() == promotion)) {
        engineMove = move;
        break;
      }
    }

    if (engineMove != null && mounted) {
      setState(() {
        isEngineThinking = false;
        _makeMove(engineMove!);
      });
    }
  }

  void _getEngineMove() {
    if (!isEngineThinking && stockfish.state.value == StockfishState.ready) {
      setState(() => isEngineThinking = true);
      final fen = chess.fen;
      stockfish.stdin = 'position fen $fen';
      stockfish.stdin = 'go movetime 1000';
    }
  }

  void _handleSquareTap(int square) {
    if (!gameStarted || isEngineThinking) return;

    final isPlayerTurn = (isPlayerAsBlack && chess.turn == chess_lib.Color.BLACK) ||
                        (!isPlayerAsBlack && chess.turn == chess_lib.Color.WHITE);
    
    if (!isPlayerTurn) return;

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
        }
      }
    });
  }

  void _makeMove(chess_lib.Move move) {
    setState(() {
      chess.make_move(move);
      selectedSquare = null;
      validMoves = [];
    });

    if (chess.game_over) {
      _showGameOverDialog();
    } else if (mounted) {
      // Check if engine should respond
      final isEngineTurn = (isPlayerAsBlack && chess.turn == chess_lib.Color.WHITE) ||
                          (!isPlayerAsBlack && chess.turn == chess_lib.Color.BLACK);
      
      if (isEngineTurn) {
        _getEngineMove();
      }
    }
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
  void dispose() {
    stockfish.stdin = 'quit'; // Properly shut down the engine
    stockfish.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isEngineThinking 
            ? const Text("Engine is thinking...") 
            : const Text("Chess Game"),
        actions: [
          if (isEngineThinking)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _initializeGame();
              setState(() {});
            },
          ),
          if (!gameStarted) IconButton(
            icon: Icon(isPlayerAsBlack 
                ? Icons.rotate_90_degrees_ccw 
                : Icons.rotate_90_degrees_cw),
            onPressed: () {
              setState(() => isPlayerAsBlack = !isPlayerAsBlack);
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
            child: AbsorbPointer(
              absorbing: isEngineThinking,
              child: ChessBoard(
                chess: chess,
                selectedSquare: selectedSquare,
                validMoves: validMoves,
                isFlipped: isPlayerAsBlack,
                onSquareSelected: _handleSquareTap,
              ),
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