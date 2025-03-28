import 'package:flutter/material.dart';
import 'package:stockfish/stockfish.dart';

void main() {
  runApp(const MaterialApp(home: StockfishSelfPlay()));
}

class StockfishSelfPlay extends StatefulWidget {
  const StockfishSelfPlay({super.key});

  @override
  State<StockfishSelfPlay> createState() => _StockfishSelfPlayState();
}

class _StockfishSelfPlayState extends State<StockfishSelfPlay> {
  final stockfish = Stockfish();
  String currentFEN = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  String currentTurn = 'white';
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    stockfish.stdout.listen((line) {
      if (line.startsWith('bestmove ')) {
        final parts = line.split(' ');
        if (parts.length >= 2) {
          final move = parts[1];
          stockfish.stdin = 'position fen $currentFEN moves $move';
          stockfish.stdin = 'd';
        }
      } else if (line.startsWith('Fen: ')) {
        final fen = line.substring(5).trim();
        final activeColor = fen.split(' ')[1];
        setState(() {
          currentFEN = fen;
          currentTurn = activeColor == 'w' ? 'black' : 'white';
          isProcessing = false;
        });
      }
    });
  }

  @override
  void dispose() {
    stockfish.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stockfish Self-Play')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Current Position:', style: Theme.of(context).textTheme.titleLarge),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SelectableText(
                currentFEN,
                style: const TextStyle(fontFamily: 'Monospace', fontSize: 16),
              ),
            ),
            Text('Current Turn: $currentTurn'),
            const SizedBox(height: 20),
            ValueListenableBuilder<StockfishState>(
              valueListenable: stockfish.state,
              builder: (context, state, _) {
                return ElevatedButton(
                  onPressed: state == StockfishState.ready && !isProcessing
                      ? () {
                          setState(() => isProcessing = true);
                          stockfish.stdin = 'position fen $currentFEN';
                          stockfish.stdin = 'go movetime 1000';
                        }
                      : null,
                  child: const Text('Make Next Move'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}