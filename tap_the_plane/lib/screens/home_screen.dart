import 'package:flutter/material.dart';
import 'game_screen.dart';
import '../services/score_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _best = 0;
  @override
  void initState() {
    super.initState();
    ScoreService().loadBest().then((v){ if (mounted) setState(()=>_best=v); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Plane Escape', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text('최고 점수: $_best', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_)=>const GameScreen())),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Text('게임 시작', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}