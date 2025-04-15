import 'package:flutter/material.dart';
import 'game_page.dart';
import 'stockfish_engine.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  late StockfishEngine stockfishEngine;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    stockfishEngine = StockfishEngine();
    await stockfishEngine.initialize();

    setState(() {
      isInitialized = true;
    });

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => GamePage(stockfishEngine: stockfishEngine),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
            const SizedBox(height: 20),
            const Text(
              '正在加载',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (!isInitialized) {
      stockfishEngine.dispose();
    }
    super.dispose();
  }
}