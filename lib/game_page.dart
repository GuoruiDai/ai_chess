import 'package:flutter/material.dart';
import 'stockfish_engine.dart';
import 'chess.dart' as chess_lib;
import 'chess_board.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late chess_lib.Chess chess;
  late StockfishEngine stockfishEngine;  
  bool gameStarted = false;
  bool isPlayerAsBlack = false;
  int _opponentElo = 2000;
  int? selectedSquare;
  List<chess_lib.Move> validMoves = [];
  bool isEngineThinking = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _initStockfish();
  }

  void _initStockfish() async {
    stockfishEngine = StockfishEngine();
    stockfishEngine.onBestMoveReceived = _handleEngineMove;
    await stockfishEngine.initialize();
  }

  void _initializeGame() {
    chess = chess_lib.Chess();
    gameStarted = false;    
    selectedSquare = null;
    validMoves = [];
    isEngineThinking = false;
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      if (isPlayerAsBlack) {
        _getEngineMove();
      }
    });
  }

  void _handleEngineMove(String moveUci) {
    final from = moveUci.substring(0, 2);
    final to = moveUci.substring(2, 4);
    final promotion = moveUci.length > 4 ? moveUci[4].toLowerCase() : null;

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
    if (!isEngineThinking) {
      setState(() => isEngineThinking = true);
      final fen = chess.fen;
      stockfishEngine.getMove(fen, _opponentElo);
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
      final isEngineTurn = (isPlayerAsBlack && chess.turn == chess_lib.Color.WHITE) ||
                          (!isPlayerAsBlack && chess.turn == chess_lib.Color.BLACK);
      
      if (isEngineTurn) {
        _getEngineMove();
      }
    }
  }

  void _handleUndo() {
    if (!gameStarted || isEngineThinking) return;

    final isPlayerTurn = (isPlayerAsBlack && chess.turn == chess_lib.Color.BLACK) ||
                        (!isPlayerAsBlack && chess.turn == chess_lib.Color.WHITE);
    
    if (!isPlayerTurn) return;

    final firstUndo = chess.undo_move();
    final secondUndo = chess.undo_move();

    if (firstUndo != null && secondUndo != null) {
      setState(() {
        selectedSquare = null;
        validMoves = [];
      });
    }
  }

  int? _getKingSquare(chess_lib.Color color) {
    for (int square = 0; square < 128; square++) {
      final piece = chess.board[square];
      if (piece != null && 
          piece.type == chess_lib.PieceType.KING && 
          piece.color == color) {
        return square;
      }
    }
    return null;
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
    stockfishEngine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isEngineThinking
            ? const Text("Engine is thinking...")
            : const Text(''),
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
          // Fixed space between app bar and board
          const SizedBox(height: 16),
          // Engine strength slider (only visible before game starts)
          if (!gameStarted) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Text(
                  'Engine Strength: ${_opponentElo == 3600 ? '3600+' : 'ELO $_opponentElo'}',
                  style: const TextStyle(fontSize: 16),
                ),
                Slider(
                  value: _opponentElo.toDouble(),
                  min: 1200,
                  max: 3600,
                  divisions: 6,
                  label: _opponentElo == 3600 ? '3600' : 'ELO $_opponentElo',
                  onChanged: (value) {
                    setState(() {
                      _opponentElo = value.round();
                    });
                  },
                ),
              ],
            ),
          ),
          // Fixed aspect ratio container for the chess board
          AspectRatio(
            aspectRatio: 1,
            child: AbsorbPointer(
              absorbing: isEngineThinking,
              child: ChessBoard(
                chess: chess,
                selectedSquare: selectedSquare,
                validMoves: validMoves,
                isFlipped: isPlayerAsBlack,
                onSquareSelected: _handleSquareTap,
                checkHighlight: chess.in_check ? _getKingSquare(chess.turn) : null,
                checkHighlightColor: const Color.fromARGB(160, 255, 60, 60),
              ),
            ),
          ),
          // Fixed height row for buttons below the board
          SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Undo button (left side)
                  if (gameStarted && 
                      ((isPlayerAsBlack && chess.turn == chess_lib.Color.BLACK) ||
                       (!isPlayerAsBlack && chess.turn == chess_lib.Color.WHITE)))
                    TextButton(
                      onPressed: _handleUndo,
                      child: const Text('Undo'),
                    )
                  else
                    const TextButton(
                      onPressed: null,
                      child: Text(''),
                    ),
                  // Placeholder button (right side)
                  const TextButton(
                    onPressed: null,
                    child: Text('Placeholder'),
                  ),
                ],
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