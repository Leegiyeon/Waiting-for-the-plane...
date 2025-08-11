import 'package:shared_preferences/shared_preferences.dart';

class ScoreService {
  static const _kBest = 'best_score';
  Future<int> loadBest() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kBest) ?? 0;
  }
  Future<void> saveBest(int score) async {
    final p = await SharedPreferences.getInstance();
    final cur = p.getInt(_kBest) ?? 0;
    if (score > cur) await p.setInt(_kBest, score);
  }
}