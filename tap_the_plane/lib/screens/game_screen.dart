import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../services/score_service.dart';
import '../widgets/hud_chip.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker =
      AnimationController.unbounded(vsync: this)..addListener(_tick);
  final gs = GameState();
  final rng = Random();
  Size? playSize;

  // 🔸 터치 들어오는지 바로 보이게 하는 디버그 카운터
  int _tapCount = 0;

  @override
  void initState() {
    super.initState();
    ScoreService().loadBest().then((v){ gs.best = v; if (mounted) setState(() {}); });
    // 첫 빌드 뒤 1프레임 지연 후 시작 (디바이스별 타이밍 안전)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 16), _start);
    });
  }

  @override
  void dispose() { _ticker.dispose(); super.dispose(); }

  void _start() {
    gs.reset();
    gs.paused = false; // 🔸 재시작 시 강제 해제
    _ticker.repeat(min: 0, period: const Duration(milliseconds: 16));
    setState(() {});
  }

  void _pauseResume() {
    if (!gs.alive) { _start(); return; }
    gs.paused = !gs.paused;
    setState(() {});
  }

  Future<void> _gameOver() async {
    if (!gs.alive) return;
    gs.alive = false;
    _ticker.stop();
    await ScoreService().saveBest(gs.score);
    gs.best = max(gs.best, gs.score);
    if (mounted) setState(() {});
  }

  void _flap() {
    if (!gs.alive) { _start(); return; }
    if (gs.paused) return;
    gs.planeVy = gs.flapImpulse;
  }

  // logical -1..1 -> dy
  double _toDy(double logicalY) =>
      (playSize!.height * 0.5) + logicalY * (playSize!.height * 0.45);

  void _tick() {
    if (!gs.alive || gs.paused || playSize == null) return;
    const dt = 1/60.0;

    // physics
    gs.planeVy += gs.gravity * dt;
    gs.planeY += gs.planeVy * dt;

    // bounds
    if (_toDy(gs.planeY) < 0) {
      gs.planeY = -(playSize!.height*0.5 - 8) / (playSize!.height*0.45);
      gs.planeVy = 0;
    }
    if (_toDy(gs.planeY) > playSize!.height) { _gameOver(); return; }

    // world/difficulty
    gs.scrollX += gs.speed * dt;
    if (gs.score % 100 == 0 && gs.score > 0) gs.speed += 0.08;

    // spawn obstacles
    gs.obsTimer -= dt;
    if (gs.obsTimer <= 0) {
      gs.obsTimer = max(0.8, 1.8 - gs.speed * 0.3);
      final gap = max(110.0, 170.0 - gs.speed * 20);
      final center = rng.nextDouble() * (playSize!.height * 0.6) + playSize!.height * 0.2;
      const thickness = 60.0;
      final right = playSize!.width + 60;
      gs.obstacles.add(Rect.fromLTWH(right, 0, 48, (center - gap/2 - thickness).clamp(0, double.infinity)));
      gs.obstacles.add(Rect.fromLTWH(right, center + gap/2, 48, playSize!.height - (center + gap/2)));
    }

    // spawn items
    gs.itemTimer -= dt;
    if (gs.itemTimer <= 0) {
      gs.itemTimer = rng.nextDouble() * 2.2 + 1.2;
      final y = rng.nextDouble() * (playSize!.height * 0.7) + playSize!.height * 0.15;
      final right = playSize!.width + 40;
      gs.items.add(Rect.fromCenter(center: Offset(right, y), width: 24, height: 24));
    }

    // move & cull
    final vx = -(140 + gs.speed * 60) * dt;
    for (int i=0;i<gs.obstacles.length;i++) {
      gs.obstacles[i] = gs.obstacles[i].shift(Offset(vx, 0));
    }
    gs.obstacles.removeWhere((r) => r.right < -60);

    for (int i=0;i<gs.items.length;i++) {
      gs.items[i] = gs.items[i].shift(Offset(vx, 0));
    }
    gs.items.removeWhere((r) => r.right < -40);

    // collisions
    final planeRect = Rect.fromCenter(
      center: Offset(playSize!.width*0.28, _toDy(gs.planeY)),
      width: 44, height: 28,
    );
    for (final r in gs.obstacles) {
      if (r.overlaps(planeRect)) { _gameOver(); return; }
    }
    for (int i=gs.items.length-1;i>=0;i--) {
      if (gs.items[i].overlaps(planeRect.inflate(6))) {
        gs.items.removeAt(i);
        gs.score += 10;
      }
    }

    gs.score += 1; // passive score
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      playSize = Size(c.maxWidth, c.maxHeight - 120);

      // 비행기 이미지 위치 계산 (Stack에서 사용)
      final planeCenter = Offset(
        playSize!.width * 0.28,
        _toDy(gs.planeY),
      );

      return Scaffold(
        appBar: AppBar(
          title: const Text('Plane Escape'),
          actions: [
            IconButton(
              tooltip: gs.paused ? 'Resume' : 'Pause',
              onPressed: _pauseResume,
              icon: Icon(gs.paused ? Icons.play_arrow : Icons.pause),
            ),
            IconButton(
              tooltip: 'Restart',
              onPressed: _start,
              icon: const Icon(Icons.replay),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  HudChip(icon: Icons.speed, label: gs.speed.toStringAsFixed(1)),
                  const SizedBox(width: 8),
                  HudChip(icon: Icons.emoji_events, label: '${gs.score}'),
                  const Spacer(),
                  HudChip(icon: Icons.star_border, label: 'BEST ${gs.best}'),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  // 배경/장애물/코인
                  CustomPaint(
                    painter: _GamePainter(gs: gs),
                    child: const SizedBox.expand(),
                  ),

                  // 비행기 이미지 (assets/images/plane.png)
                  Positioned(
                    left: planeCenter.dx - 22,   // width ~44 기준 중앙 보정
                    top:  planeCenter.dy - 14,   // height ~28 기준 중앙 보정
                    child: Image.asset(
                      'assets/images/plane.png',
                      width: 44,
                      height: 28,
                      filterQuality: FilterQuality.high,
                    ),
                  ),

                  // 🔸 최상단 포인터 리스너: 화면 어디를 눌러도 바로 _flap()
                  Positioned.fill(
                    child: Listener(
                      onPointerDown: (_) {
                        _tapCount++;    // 디버그 카운터 (좌상단에 표시)
                        _flap();
                        setState(() {});
                      },
                      // 필요시 드래그에도 반응
                      // onPointerMove: (_) => _flap(),
                    ),
                  ),

                  // 🔸 좌상단 디버그 오버레이 (터치 유입 확인용)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'taps: $_tapCount',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _GamePainter extends CustomPainter {
  final GameState gs;
  _GamePainter({required this.gs});

  static final Paint _lane =
      Paint()..color = const Color(0xFFAEC8F9)..strokeWidth = 2;
  static final Paint _obsPaint = Paint()..color = const Color(0xFF3B5CCC);
  static final Paint _coin = Paint()..color = const Color(0xFFFFC22E);
  static final Paint _coinHi = Paint()..color = const Color(0xFFFFE08A);
  static final Paint _shadow = Paint()..color = Colors.black.withOpacity(0.15);

  @override
  void paint(Canvas canvas, Size size) {
    // sky
    final rect = Offset.zero & size;
    final sky = const LinearGradient(
      colors: [Color(0xFFBEE3FF), Color(0xFFEFF6FF)],
      begin: Alignment.topCenter, end: Alignment.bottomCenter);
    canvas.drawRect(rect, Paint()..shader = sky.createShader(rect));

    // stripes
    for (double y=30; y<size.height; y+=80) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _lane);
    }

    // obstacles
    for (final r in gs.obstacles) {
      final rr = Rect.fromLTWH(r.left, r.top, r.width, r.height.clamp(0, size.height));
      canvas.drawRRect(RRect.fromRectAndRadius(rr, const Radius.circular(8)), _obsPaint);
    }

    // coins
    for (final r in gs.items) {
      canvas.drawOval(r, _coin);
      canvas.drawCircle(r.center, r.width*0.25, _coinHi);
    }

    // 오버레이 텍스트 (게임오버/일시정지)
    if (!gs.alive || gs.paused) {
      final text = !gs.alive
          ? 'Game Over\nScore ${gs.score}\nBest ${gs.best}\n\nTap to Retry'
          : 'PAUSED';
      final style = TextStyle(
        fontSize: !gs.alive ? 22 : 26,
        color: Colors.black87,
        fontWeight: !gs.alive ? FontWeight.w600 : FontWeight.w800,
      );
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width-40);
      tp.paint(canvas, Offset((size.width-tp.width)/2, (size.height-tp.height)/2));
    }
  }

  @override
  bool shouldRepaint(covariant _GamePainter old) => true;
}