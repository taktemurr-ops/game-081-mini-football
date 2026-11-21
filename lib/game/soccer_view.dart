import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:studio_core/app/arcade_stage.dart';
import 'package:studio_core/app/play_kit.dart';
import 'package:studio_core/app/services/audio.dart';
import 'package:studio_core/core/arcade.dart';
import 'soccer_engine.dart';

Paint _p(int c) => Paint()..color = Color(c);

Paint _stroke(int c, double w) => Paint()
  ..color = Color(c)
  ..style = PaintingStyle.stroke
  ..strokeWidth = w;

void _player(Canvas c, double x, double y, int shirt, double t, bool moving, {int number = 9}) {
  final step = moving ? math.sin(t * 16 + x * 0.02) * 8 : 0.0;
  c.drawOval(Rect.fromCenter(center: Offset(x + 6, y + 10), width: 64, height: 40), _p(0x44000000));
  c.drawCircle(Offset(x - 12, y + step), 10, _p(0xFF111111));
  c.drawCircle(Offset(x + 12, y - step), 10, _p(0xFF111111));
  c.drawCircle(Offset(x, y), kManR, _p(shirt));
  c.drawCircle(Offset(x, y), kManR * 0.55, _p(0xFF6B4226));
  paintText(c, '$number', Offset(x, y + 1), 18, Colors.white);
}

void paintSoccer(Canvas c, ArcadeSim sim, ArcadePalette p, double t) {
  final s = sim as SoccerSim;
  c.drawRect(const Rect.fromLTWH(0, 0, kWorldW, kWorldH), _p(0xFF1B4332));
  const pitch = Rect.fromLTRB(kPitchL, kPitchT, kPitchR, kPitchB);
  for (var i = 0; i < 10; i++) {
    c.drawRect(Rect.fromLTWH(kPitchL, kPitchT + i * 140, kPitchR - kPitchL, 140), _p(i.isEven ? 0xFF2D6A4F : 0xFF40916C));
  }
  final line = _stroke(0xDDFFFFFF, 6);
  c.drawRect(pitch, line);
  c.drawLine(const Offset(kPitchL, 840), const Offset(kPitchR, 840), line);
  c.drawCircle(const Offset(500, 840), 110, line);
  c.drawRect(const Rect.fromLTRB(kGoalMid - 260, kPitchT, kGoalMid + 260, kPitchT + 220), line);
  c.drawRect(const Rect.fromLTRB(kGoalMid - 260, kPitchB - 220, kGoalMid + 260, kPitchB), line);
  // goals
  c.drawRect(const Rect.fromLTRB(kGoalMid - kGoalHalf, kPitchT - 50, kGoalMid + kGoalHalf, kPitchT), _p(0x55FFFFFF));
  c.drawRect(const Rect.fromLTRB(kGoalMid - kGoalHalf, kPitchB, kGoalMid + kGoalHalf, kPitchB + 50), _p(0x55FFFFFF));
  c.drawRect(const Rect.fromLTRB(kGoalMid - kGoalHalf, kPitchT - 50, kGoalMid + kGoalHalf, kPitchT), _stroke(0xFFFFFFFF, 6));
  c.drawRect(const Rect.fromLTRB(kGoalMid - kGoalHalf, kPitchB, kGoalMid + kGoalHalf, kPitchB + 50), _stroke(0xFFFFFFFF, 6));
  // keepers
  _player(c, s.cpuKeeperX, kPitchT + 22, 0xFFFFB703, t, false, number: 1);
  _player(c, s.myKeeperX, kPitchB - 22, 0xFF06D6A0, t, false, number: 1);
  for (var i = 0; i < s.rivals.length; i++) {
    final r = s.rivals[i];
    _player(c, r.x, r.y, r.stun > 0 ? 0xFFADB5BD : 0xFFE63946, t, true, number: 4 + i * 3);
  }
  // highlight ring under the controlled striker
  c.drawCircle(Offset(s.me.x, s.me.y), kManR + 14, _stroke(0xCCFFD60A, 5));
  _player(c, s.me.x, s.me.y, s.sprint > 0 ? 0xFF4CC9F0 : 0xFF1D4ED8, t, s.me.vx.abs() + s.me.vy.abs() > 0.5);
  // ball
  c.drawCircle(Offset(s.bx + 4, s.by + 6), kBallR, _p(0x55000000));
  c.drawCircle(Offset(s.bx, s.by), kBallR, _p(0xFFFFFFFF));
  c.drawCircle(Offset(s.bx, s.by), kBallR * 0.4, _p(0xFF222222));
  // joystick
  if (s.ax >= 0) {
    c.drawCircle(Offset(s.ax, s.ay), 80, _stroke(0x55FFFFFF, 6));
  }
  // scoreboard
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(330, 40, 340, 80), const Radius.circular(20)), _p(0xCC000000));
  paintText(c, '${s.myGoals}  -  ${s.cpuGoals}', const Offset(500, 80), 52, Colors.white);
  if (s.flashTicks > 0) {
    paintText(c, s.flash, const Offset(500, 700), 90, Colors.white.withValues(alpha: (s.flashTicks / 70).clamp(0.0, 1.0)));
  }
}

Sfx? soccerSound(ArcadeSim sim) => switch ((sim as SoccerSim).lastEvent) {
      1 => Sfx.tap,
      2 => Sfx.win,
      3 => Sfx.error,
      4 => Sfx.place,
      5 => Sfx.clear,
      _ => null,
    };
