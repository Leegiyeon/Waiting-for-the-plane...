import 'dart:ui';

class GameState {
  // physics
  double planeY = 0;          // -1.0(top) ~ 1.0(bottom)
  double planeVy = 0;         // velocity (logical units/s)
  double gravity = 1.2;       // fall accel
  double flapImpulse = -0.55; // tap impulse (negative=up)

  // run
  double scrollX = 0;         // world scroll
  double speed = 1.2;         // world speed (units/s)
  int score = 0;
  int best = 0;
  bool alive = false;
  bool paused = false;

  // spawn timers
  double obsTimer = 0;
  double itemTimer = 0;

  final obstacles = <Rect>[];
  final items = <Rect>[];

  void reset() {
    planeY = 0;
    planeVy = 0;
    speed = 1.2;
    score = 0;
    alive = true;
    paused = false;
    scrollX = 0;
    obstacles.clear();
    items.clear();
    obsTimer = 0;
    itemTimer = 0;
  }
}