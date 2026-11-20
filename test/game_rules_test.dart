import 'package:flutter_test/flutter_test.dart';
import 'package:game_081_mini_football/core/arcade.dart';
import 'package:game_081_mini_football/core/level_plan.dart';
import 'package:game_081_mini_football/game/rules.dart';
import 'package:game_081_mini_football/game/soccer_engine.dart';

void main() {
  final rules = FootballRules();
  final planner = LevelPlanner(gameId: rules.gameId, optionalMechanics: rules.optionalMechanics);

  SoccerSim fresh([int n = 1]) => SoccerSim(rules.build(planner.spec(n)).puzzle);

  test('dribbling keeps the ball, a short tap in range scores', () {
    final s = fresh();
    s.rivals.clear();
    s.kickoff = 0;
    s.me.x = 500;
    s.me.y = 500;
    s.bx = 500;
    s.by = 460;
    s.tick(const ArcadeInput(down: true, x: 500, y: 1200));
    s.tick(const ArcadeInput(down: true, x: 500, y: 1100));
    expect(s.owner, -1);
    s.tick(const ArcadeInput(down: false, x: 500, y: 1100));
    s.tick(const ArcadeInput(down: true, x: 500, y: 1200));
    s.tick(const ArcadeInput(down: false, x: 500, y: 1200));
    expect(s.owner, -2);
    for (var i = 0; i < 60 && s.myGoals == 0; i++) {
      s.cpuKeeperX = 500;
      s.tick(ArcadeInput.idle);
    }
    expect(s.myGoals, 1);
  });

  test('being ahead when time is up wins the match', () {
    final s = fresh();
    s.myGoals = 2;
    s.matchTicks = s.matchLen - 1;
    s.kickoff = 0;
    s.rivals.clear();
    s.tick(ArcadeInput.idle);
    s.tick(ArcadeInput.idle);
    expect(s.won, isTrue);
  });

  test('autopilot wins the first matches', () {
    for (var n = 1; n <= 5; n++) {
      final s = fresh(n);
      expect(runBot(s, rules.bot, 60 * 60 * 6).won, isTrue, reason: 'level $n');
    }
  });
}
