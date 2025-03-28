import 'package:stockfish/stockfish.dart';


class StockfishEngine {
  late Stockfish stockfish;
  Function(String)? onBestMoveReceived;
  bool _isReady = false;

  Future<void> initialize() async {
    stockfish = Stockfish();
    stockfish.stdout.listen(_handleEngineResponse);
    
    // Wait until engine is ready
    while (stockfish.state.value != StockfishState.ready) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _isReady = true;
  }

  void _handleEngineResponse(String line) {
    if (line.startsWith('bestmove ')) {
      final parts = line.split(' ');
      if (parts.length >= 2) {
        final moveUci = parts[1];
        onBestMoveReceived?.call(moveUci);
      }
    }
  }

  void getMove(String fen) {
    if (!_isReady) return;
    stockfish.stdin = 'position fen $fen';
    stockfish.stdin = 'go movetime 1000';
  }

  void dispose() {
    stockfish.stdin = 'quit';
    stockfish.dispose();
    _isReady = false;
  }
}
