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
  bool isEngineActive = false;
  chess_lib.Move? lastMove;
  chess_lib.Move? engineSuggestedMove;
  bool showEngineHint = false;

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
    isEngineActive = false;
    lastMove = null;
    engineSuggestedMove = null;
  }

  void _getEngineMove(int elo) {
    if (!isEngineActive) {
      setState(() => isEngineActive = true);
      stockfishEngine.getMove(chess.fen, elo);
    }
  }

  void _startGame() {
    setState(() {
      gameStarted = true;
      if (isPlayerAsBlack) _getEngineMove(_opponentElo);
    });
  }

  void _handleEngineMove(String moveUci) {
    setState(() {
      isEngineActive = false;
      final isPlayerTurn = (isPlayerAsBlack && chess.turn == chess_lib.Color.BLACK) ||
                          (!isPlayerAsBlack && chess.turn == chess_lib.Color.WHITE);
      
      if (isPlayerTurn) {
        _parseEngineSuggestion(moveUci);
      } else {
        _parseEngineMove(moveUci);
      }
    });
  }

  void _parseEngineSuggestion(String moveUci) {
    final from = moveUci.substring(0, 2);
    final to = moveUci.substring(2, 4);
    final moves = chess.generate_moves();
    
    for (final move in moves) {
      if (move.fromAlgebraic == from && move.toAlgebraic == to) {
        engineSuggestedMove = move;
        break;
      }
    }
  }

  void _parseEngineMove(String moveUci) {
    final from = moveUci.substring(0, 2);
    final to = moveUci.substring(2, 4);
    final moves = chess.generate_moves();
    
    for (final move in moves) {
      if (move.fromAlgebraic == from && move.toAlgebraic == to) {
        _makeMove(move);
        break;
      }
    }
  }

  void _handleSquareTap(int square) {
    if (!gameStarted || isEngineActive) return;
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
      lastMove = move;
      selectedSquare = null;
      validMoves = [];
      engineSuggestedMove = null;
    });

    if (chess.game_over) {
      _showGameOverDialog();
    } else if (mounted) {
      if ((isPlayerAsBlack && chess.turn == chess_lib.Color.WHITE) ||
          (!isPlayerAsBlack && chess.turn == chess_lib.Color.BLACK)) {
        _getEngineMove(_opponentElo);
      } else if (showEngineHint) {
        if (engineSuggestedMove == null) {
          _getEngineMove(3600);
        }
      }
    }
  }

  void _handleUndo() {
    if (!gameStarted || isEngineActive) return;
    final firstUndo = chess.undo_move();
    final secondUndo = chess.undo_move();
    if (firstUndo != null && secondUndo != null) {
      setState(() {
        lastMove = null;
        selectedSquare = null;
        validMoves = [];
        engineSuggestedMove = null;
      });
    }
  }

  int? _getKingSquare(chess_lib.Color color) {
    return chess.kings[color] != chess_lib.Chess.EMPTY 
        ? chess.kings[color]
        : null;
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
    final isPlayerTurn = gameStarted && 
        ((isPlayerAsBlack && chess.turn == chess_lib.Color.BLACK) ||
         (!isPlayerAsBlack && chess.turn == chess_lib.Color.WHITE));

    return Scaffold(
      appBar: AppBar(
        title: isEngineActive 
            ? const Text("Engine is calculating...")
            : const Text('Chess'),
        actions: [
          if (isEngineActive)
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
          const SizedBox(height: 16),
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
                    setState(() => _opponentElo = value.round());
                  },
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 1,
            child: AbsorbPointer(
              absorbing: isEngineActive,
              child: ChessBoard(
                chess: chess,
                selectedSquare: selectedSquare,
                validMoves: validMoves,
                isFlipped: isPlayerAsBlack,
                onSquareSelected: _handleSquareTap,
                checkHighlight: chess.in_check ? _getKingSquare(chess.turn) : null,
                lastMove: lastMove,
                engineSuggestion: showEngineHint ? engineSuggestedMove : null,
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (gameStarted && isPlayerTurn)
                    TextButton(
                      onPressed: _handleUndo,
                      child: const Text('Undo'),
                    )
                  else
                    const SizedBox(width: 80),
                  if (gameStarted && isPlayerTurn)
                    TextButton.icon(
                      icon: const Icon(Icons.lightbulb_outline, size: 20),
                      label: Text(showEngineHint ? 'Hide Hint' : 'Show Hint'),
                      onPressed: () {
                        if (!isEngineActive) {
                          setState(() {
                            showEngineHint = !showEngineHint;
                            if (showEngineHint && engineSuggestedMove == null) {
                              _getEngineMove(3600);
                            }
                          });
                        }
                      },
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