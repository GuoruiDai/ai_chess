// import 'package:flutter/material.dart';
// import 'package:stockfish/stockfish.dart';

// void main() {
//   runApp(const ChessEngineDemo());
// }

// class ChessEngineDemo extends StatefulWidget {
//   const ChessEngineDemo({super.key});

//   @override
//   State<ChessEngineDemo> createState() => _ChessEngineDemoState();
// }

// class _ChessEngineDemoState extends State<ChessEngineDemo> {
//   final Stockfish stockfish = Stockfish();
//   List<String> engineOutput = [];
//   bool isEngineReady = false;

//   @override
//   void initState() {
//     super.initState();
//     _initEngine();
//   }

//   void _initEngine() async {
//     // Wait for engine to initialize
//     await Future.delayed(const Duration(milliseconds: 500));

//     // Listen for engine state changes
//     stockfish.state.addListener(() {
//       if (stockfish.state.value == StockfishState.ready) {
//         setState(() => isEngineReady = true);
//         _analyzePawnMove();
//       }
//     });

//     // Capture engine output
//     stockfish.stdout.listen((String line) {
//       setState(() => engineOutput.add(line));
//       print("Stockfish: $line"); // Debug print
//     });
//   }

//   void _analyzePawnMove() {
//     if (!isEngineReady) return;

//     // 1. Set up the starting position (pawn to e4)
//     stockfish.stdin = 'position startpos moves e2e4';

//     // 2. Request analysis for 2 seconds
//     stockfish.stdin = 'go movetime 2000';
//   }

//   @override
//   void dispose() {
//     stockfish.dispose(); // Clean up the engine
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(title: const Text('Stockfish Demo - Pawn to e4')),
//         body: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Engine Status: ${isEngineReady ? "Ready" : "Loading..."}',
//                 style: const TextStyle(fontSize: 18),
//               ),
//               const SizedBox(height: 20),
//               const Text(
//                 'Stockfish Output:',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//               ),
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: engineOutput.length,
//                   itemBuilder: (context, index) => Text(engineOutput[index]),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }