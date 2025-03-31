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
      await Future.delayed(const Duration(milliseconds: 200));
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

  void getMove(String fen, int elo) {
    if (!_isReady) return;
    
    // Set strength before calculating move
    if (elo >= 3600) {
      stockfish.stdin = 'setoption name UCI_LimitStrength value false';
    } else {
      stockfish.stdin = 'setoption name UCI_LimitStrength value true';
      stockfish.stdin = 'setoption name UCI_Elo value $elo';
    }
    stockfish.stdin = 'position fen $fen';
    stockfish.stdin = 'go movetime 3000';
  }

  void dispose() {
    stockfish.stdin = 'quit';
    stockfish.dispose();
    _isReady = false;
  }
}
