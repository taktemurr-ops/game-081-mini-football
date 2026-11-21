import 'dart:math' as math;

import 'package:studio_core/core/arcade.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/rng.dart';

/// Top-down mini football: you control a striker (virtual joystick), the
/// ball sticks to your feet while you dribble, a tap shoots at the goal.
/// Rival field players press and tackle; both teams have a keeper.
const double kPitchL = 60, kPitchR = 940, kPitchT = 140, kPitchB = 1540;
const double kGoalHalf = 120, kGoalMid = 500;
const double kBallR = 16, kManR = 28;

class SoccerLevel {
  final ArcadeMeta meta;
  final int difficulty;
  final int rivals; // field players
  final int seconds; // match length
  final int theme;
  const SoccerLevel(this.meta, this.difficulty, this.rivals, this.seconds, this.theme);
}

SoccerLevel generateSoccer(LevelSpec spec) {
  final d = spec.difficulty.clamp(1, 10);
  return SoccerLevel(ArcadeMeta.of(spec), d, d <= 3 ? 1 : (d <= 7 ? 2 : 3), 60 + d * 6, spec.theme % 4);
}

class Man {
  double x, y, vx = 0, vy = 0;
  final bool rival;
  int stun = 0;
  Man(this.x, this.y, this.rival);
}

class SoccerSim extends ArcadeSim {
  final SoccerLevel level;
  late Man me;
  final List<Man> rivals = [];
  double bx = 500, by = 840, bvx = 0, bvy = 0;
  int owner = -2; // -2 free, -1 me, 0.. rival index
  double myKeeperX = 500, cpuKeeperX = 500;
  int myGoals = 0, cpuGoals = 0;
  int matchTicks = 0, extra = 0;
  int kickoff = 0; // pause ticks after a goal
  int tackleCd = 0, shootCd = 0, rivalShootCd = 0;
  double faceX = 0, faceY = -1;
  // joystick
  double ax = -1, ay = -1;
  bool wasDown = false;
  int downTicks = 0;
  double moved = 0;
  int goals = 0, matchesWon = 0, tackles = 0, shotsOnTarget = 0, saves = 0;
  int lastEvent = 0; // 1 kick, 2 goal for, 3 goal against, 4 tackle, 5 save
  String flash = '';
  int flashTicks = 0;
  int sprint = 0;

  SoccerSim(this.level) : super(level.meta, lives: 3) {
    _kickoff(true);
  }

  int get d => level.difficulty;
  bool get matchMode => meta.goal;
  int get matchLen => level.seconds * kTicksPerSecond;

  SeededRandom get _r => SeededRandom(mixSeed([meta.seed, ticks, 77]));

  void _kickoff(bool mine) {
    me = Man(500, mine ? 900 : 1100, false);
    rivals.clear();
    final n = level.rivals;
    for (var i = 0; i < n; i++) {
      rivals.add(Man(n == 1 ? 500 : 300 + i * (400 / (n - 1)), mine ? 620 : 760, true));
    }
    bx = 500;
    by = 840;
    bvx = bvy = 0;
    owner = -2;
    myKeeperX = 500;
    cpuKeeperX = 500;
    kickoff = 40;
    ax = ay = -1;
    if (!mine && rivals.isNotEmpty) {
      rivals[0].y = 800;
      owner = 0;
    }
  }

  void _say(String s) {
    flash = s;
    flashTicks = 70;
  }

  @override
  void update(ArcadeInput input) {
    lastEvent = 0;
    if (flashTicks > 0) flashTicks--;
    if (tackleCd > 0) tackleCd--;
    if (shootCd > 0) shootCd--;
    if (rivalShootCd > 0) rivalShootCd--;
    if (sprint > 0) sprint--;
    if (kickoff > 0) {
      kickoff--;
      _readInput(input, frozen: true);
      return;
    }
    matchTicks++;
    _readInput(input);
    _rivalsAi();
    _keepers();
    _ball();
    if (matchMode) _clock();
  }

  void _clock() {
    if (matchTicks < matchLen + extra) return;
    if (myGoals > cpuGoals) {
      matchesWon++;
      score += 500;
      win();
    } else if (myGoals == cpuGoals && extra == 0) {
      extra = 25 * kTicksPerSecond; // golden goal
      _say('GOLDEN GOAL');
    } else {
      _lose();
    }
  }

  void _lose() {
    if (meta.zen) return;
    shield = 0;
    hit();
  }

  @override
  void onLifeLost() {
    if (matchMode) {
      myGoals = 0;
      cpuGoals = 0;
      matchTicks = 0;
      extra = 0;
    }
    _kickoff(true);
  }

  void _readInput(ArcadeInput i, {bool frozen = false}) {
    var dx = 0.0, dy = 0.0;
    var shoot = false;
    if (i.down && i.hasPointer) {
      if (!wasDown || ax < 0) {
        ax = i.x;
        ay = i.y;
        downTicks = 0;
        moved = 0;
      }
      downTicks++;
      final jx = i.x - ax, jy = i.y - ay;
      final len = math.sqrt(jx * jx + jy * jy);
      moved = math.max(moved, len);
      if (len > 12) {
        dx = jx / len * math.min(1, len / 70);
        dy = jy / len * math.min(1, len / 70);
      }
    } else if (wasDown) {
      // a short touch without dragging = shoot
      if (downTicks <= 14 && moved < 24) shoot = true;
      ax = ay = -1;
    }
    wasDown = i.down && i.hasPointer;
    if (i.dirX != 0 || i.dirY != 0) {
      final l = math.sqrt((i.dirX * i.dirX + i.dirY * i.dirY).toDouble());
      dx = i.dirX / l;
      dy = i.dirY / l;
    }
    if (i.tap && !i.hasPointer) shoot = true;
    if (frozen) return;
    final sp = (owner == -1 ? 6.6 : 7.4) * (sprint > 0 ? 1.35 : 1);
    me.vx = dx * sp;
    me.vy = dy * sp;
    if (me.stun > 0) {
      me.stun--;
      me.vx *= 0.3;
      me.vy *= 0.3;
    }
    me.x = clampD(me.x + me.vx, kPitchL + kManR, kPitchR - kManR);
    me.y = clampD(me.y + me.vy, kPitchT + kManR, kPitchB - kManR);
    if (dx != 0 || dy != 0) {
      faceX = dx;
      faceY = dy;
      final l = math.sqrt(faceX * faceX + faceY * faceY);
      faceX /= l;
      faceY /= l;
    }
    // pick up a free ball
    final dbx = bx - me.x, dby = by - me.y;
    if (owner != -1 && owner < 0 && dbx * dbx + dby * dby < (kManR + kBallR + 6) * (kManR + kBallR + 6) && shootCd == 0) {
      owner = -1;
    }
    // tackle a rival with the ball
    if (owner >= 0 && tackleCd == 0) {
      final r = rivals[owner];
      if ((r.x - me.x) * (r.x - me.x) + (r.y - me.y) * (r.y - me.y) < 50 * 50) {
        owner = -1;
        tackles++;
        tackleCd = 40;
        r.stun = 30;
        lastEvent = 4;
        _say('TACKLE!');
      }
    }
    if (shoot && owner == -1) _shoot();
  }

  void _shoot() {
    // aim: at the goal, away from the keeper (when in range), else forward
    double tx, ty;
    if (me.y < 900) {
      final side = cpuKeeperX > kGoalMid ? -1 : 1;
      tx = kGoalMid + side * (kGoalHalf - 26);
      ty = kPitchT - 20;
    } else {
      tx = me.x + faceX * 400;
      ty = me.y + math.min(-0.4, faceY) * 400;
    }
    final dx = tx - bx, dy = ty - by;
    final l = math.sqrt(dx * dx + dy * dy);
    final sp = 25.0;
    bvx = dx / l * sp;
    bvy = dy / l * sp;
    owner = -2;
    shootCd = 18;
    lastEvent = 1;
  }

  void _rivalShoot(Man r) {
    final rr = _r;
    final side = myKeeperX > kGoalMid ? -1 : 1;
    final accurate = rr.chance(0.55 + d * 0.035);
    final tx = kGoalMid + side * (accurate ? kGoalHalf - 30 : kGoalHalf + 40 + rr.nextDouble() * 60);
    final ty = kPitchB + 20;
    final dx = tx - bx, dy = ty - by;
    final l = math.sqrt(dx * dx + dy * dy);
    final sp = 17.0 + d * 0.8;
    bvx = dx / l * sp;
    bvy = dy / l * sp;
    owner = -2;
    rivalShootCd = 40;
    lastEvent = 1;
  }

  void _rivalsAi() {
    final speed = 4.6 + d * 0.32;
    for (var i = 0; i < rivals.length; i++) {
      final r = rivals[i];
      if (r.stun > 0) {
        r.stun--;
        continue;
      }
      double tx, ty;
      if (owner == i) {
        // dribble toward our goal, around the striker
        tx = kGoalMid + (r.x < me.x ? -140 : 140) * (((me.y - r.y).abs() < 150) ? 1 : 0.3);
        ty = kPitchB;
        if (r.y > kPitchB - 460 && rivalShootCd == 0) {
          _rivalShoot(r);
          continue;
        }
      } else if (owner == -1 || owner == -2) {
        // first rival presses the ball, others guard the lanes
        final chaser = _closestRival();
        if (i == chaser) {
          tx = bx;
          ty = by;
        } else {
          tx = (bx + kGoalMid) / 2 + (i.isEven ? -120 : 120);
          ty = math.min(by - 160, 760);
        }
      } else {
        tx = 300 + i * 200;
        ty = math.min(by + 200, kPitchB - 300);
      }
      final dx = tx - r.x, dy = ty - r.y;
      final l = math.sqrt(dx * dx + dy * dy);
      final sp = owner == i ? speed * 0.8 : speed;
      if (l > 1) {
        r.x += dx / l * math.min(sp, l);
        r.y += dy / l * math.min(sp, l);
      }
      r.x = clampD(r.x, kPitchL + kManR, kPitchR - kManR);
      r.y = clampD(r.y, kPitchT + kManR + 60, kPitchB - kManR);
      // win a free ball / tackle the striker
      final bdx = bx - r.x, bdy = by - r.y;
      if (owner == -2 && bdx * bdx + bdy * bdy < (kManR + kBallR + 4) * (kManR + kBallR + 4) && shootCd == 0) {
        owner = i;
      } else if (owner == -1 && tackleCd == 0 && me.stun == 0) {
        final mdx = me.x - r.x, mdy = me.y - r.y;
        if (mdx * mdx + mdy * mdy < 44 * 44 && _r.chance(0.035 + d * 0.006)) {
          owner = i;
          tackleCd = 50;
          me.stun = 18;
          lastEvent = 4;
          _say('LOST!');
        }
      }
    }
  }

  int _closestRival() {
    var best = 0;
    var bd = 1e18;
    for (var i = 0; i < rivals.length; i++) {
      final r = rivals[i];
      final dd = (r.x - bx) * (r.x - bx) + (r.y - by) * (r.y - by);
      if (dd < bd) {
        bd = dd;
        best = i;
      }
    }
    return best;
  }

  void _keepers() {
    final ks = 4.0 + d * 0.35;
    double target(double toward) => clampD(toward, kGoalMid - kGoalHalf + 20, kGoalMid + kGoalHalf - 20);
    // predict where the ball crosses the line if it moves toward a goal
    var tc = bx, tm = bx;
    if (bvy < -2 && owner == -2) tc = bx + bvx * ((by - kPitchT) / -bvy);
    if (bvy > 2 && owner == -2) tm = bx + bvx * ((kPitchB - by) / bvy);
    cpuKeeperX = moveToward(cpuKeeperX, target(kGoalMid + (tc - kGoalMid) * 0.85), ks);
    myKeeperX = moveToward(myKeeperX, target(kGoalMid + (tm - kGoalMid) * 0.9), 7.5);
  }

  void _ball() {
    if (owner == -1) {
      bx = me.x + faceX * (kManR + kBallR - 4);
      by = me.y + faceY * (kManR + kBallR - 4);
      bvx = me.vx;
      bvy = me.vy;
    } else if (owner >= 0) {
      final r = rivals[owner];
      bx = r.x;
      by = r.y + kManR + kBallR - 4;
      bvx = bvy = 0;
    } else {
      bx += bvx;
      by += bvy;
      bvx *= 0.975;
      bvy *= 0.975;
      if (math.sqrt(bvx * bvx + bvy * bvy) < 0.1) bvx = bvy = 0;
    }
    // side walls
    if (bx < kPitchL + kBallR) {
      bx = kPitchL + kBallR;
      bvx = bvx.abs() * 0.7;
    } else if (bx > kPitchR - kBallR) {
      bx = kPitchR - kBallR;
      bvx = -bvx.abs() * 0.7;
    }
    final inMouth = (bx - kGoalMid).abs() < kGoalHalf;
    // keepers
    if (owner == -2) {
      if (by < kPitchT + 40 && bvy < 0 && (bx - cpuKeeperX).abs() < 46) {
        bvy = bvy.abs() * 0.5;
        bvx += (bx - cpuKeeperX) * 0.1;
        lastEvent = 5;
        _say('SAVED');
      }
      if (by > kPitchB - 40 && bvy > 0 && (bx - myKeeperX).abs() < 46) {
        bvy = -bvy.abs() * 0.5;
        bvx += (bx - myKeeperX) * 0.1;
        saves++;
        lastEvent = 5;
        _say('SAVE!');
      }
    }
    if (by < kPitchT) {
      if (inMouth) {
        _goal(true);
        return;
      }
      by = kPitchT;
      bvy = bvy.abs() * 0.7;
    } else if (by > kPitchB) {
      if (inMouth) {
        _goal(false);
        return;
      }
      by = kPitchB;
      bvy = -bvy.abs() * 0.7;
    }
  }

  void _goal(bool mine) {
    if (mine) {
      myGoals++;
      goals++;
      score += 200;
      lastEvent = 2;
      _say('GOAL!');
    } else {
      cpuGoals++;
      lastEvent = 3;
      _say('GOAL ×');
      if (!matchMode && !meta.zen) {
        shield = 0;
        hit();
        if (over) return;
      }
    }
    if (matchMode && extra > 0) {
      if (myGoals != cpuGoals) {
        if (myGoals > cpuGoals) {
          matchesWon++;
          score += 500;
          win();
        } else {
          _lose();
        }
        return;
      }
    }
    // mercy rule
    if (matchMode && myGoals - cpuGoals >= 4) {
      matchesWon++;
      score += 500;
      win();
      return;
    }
    _kickoff(!mine);
  }

  @override
  bool useBooster() {
    if (over) return false;
    sprint = 600;
    return true;
  }

  @override
  double get progress => matchMode ? (matchTicks / (matchLen + extra)).clamp(0.0, 1.0) : 0;

  @override
  String get goalText {
    if (!matchMode) return '$goals';
    final left = math.max(0, (matchLen + extra - matchTicks) ~/ kTicksPerSecond);
    return '$myGoals-$cpuGoals • ${left}s';
  }

  @override
  Map<String, int> get stats => {
        'goals': goals,
        'matches_won': matchesWon,
        'tackles': tackles,
        'saves': saves,
      };

  @override
  int get stars => won ? math.min(lifeStars(this, 3), cpuGoals == 0 ? 3 : (myGoals - cpuGoals >= 2 ? 2 : 1)) : 0;
}

/// Autopilot: win the ball, dribble around rivals, shoot from range.
ArcadeInput soccerBot(ArcadeSim sim) {
  final s = sim as SoccerSim;
  const ox = 500.0, oy = 1200.0;
  if (s.kickoff > 0) return ArcadeInput.idle;
  double tx, ty;
  if (s.owner == -1) {
    // shoot when close enough and in front of the goal
    if (s.me.y < 560 && (s.me.x - kGoalMid).abs() < 260 && s.shootCd == 0) {
      // release a short touch: the stage sees down then up
      if (s.wasDown) return const ArcadeInput(down: false, x: ox, y: oy);
      return const ArcadeInput(down: true, x: ox, y: oy);
    }
    tx = kGoalMid;
    ty = kPitchT;
    // steer around the nearest rival in front
    for (final r in s.rivals) {
      final dy = s.me.y - r.y;
      if (dy > 0 && dy < 220 && (r.x - s.me.x).abs() < 110) {
        tx = s.me.x + (r.x > s.me.x ? -260 : 260);
        if (tx < kPitchL + 80) tx = s.me.x + 260;
        if (tx > kPitchR - 80) tx = s.me.x - 260;
        ty = s.me.y - 120;
      }
    }
  } else {
    tx = s.bx;
    ty = s.by;
    if (s.owner >= 0) {
      ty = s.by + 10;
    }
  }
  final dx = tx - s.me.x, dy = ty - s.me.y;
  final l = math.sqrt(dx * dx + dy * dy);
  if (l < 4) return const ArcadeInput(down: true, x: ox, y: oy);
  // first touch sets the anchor; afterwards drag from it
  if (!s.wasDown) return const ArcadeInput(down: true, x: ox, y: oy);
  return ArcadeInput(down: true, x: (ox + dx / l * 80).roundToDouble(), y: (oy + dy / l * 80).roundToDouble());
}
