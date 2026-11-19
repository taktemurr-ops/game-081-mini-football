import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_081_mini_football/game/football_engine.dart';

void main() {
  group('FootballEngine', () {
    test('starts ready and refuses premature actions', () {
      final game = FootballEngine(random: Random(1));
      expect(game.phase, MatchPhase.ready);
      expect(game.shoot(Aim.left), false);
      expect(game.defend(Aim.right), false);
      expect(game.playerShots, 0);
      game.start();
      expect(game.phase, MatchPhase.playerTurn);
    });
    test('each successful turn alternates shooting and saving', () {
      final game = FootballEngine(random: Random(2))..start();
      expect(game.shoot(Aim.center), true);
      expect(game.phase, MatchPhase.opponentTurn);
      expect(game.playerShots, 1);
      expect(game.shoot(Aim.left), false);
      expect(game.defend(Aim.right), true);
      expect(game.opponentShots, 1);
      expect(game.phase, MatchPhase.playerTurn);
    });
    test('keeper in same lane saves a kick', () {
      final game = FootballEngine(random: Random(3))..start();
      // Read the RNG sequence from a separately seeded generator.
      final lane = Aim.values[Random(3).nextInt(3)];
      expect(game.shoot(lane), true);
      expect(game.lastPlayerKick!.goal, false);
      expect(game.playerGoals, 0);
    });
    test('different keeper lane yields a goal', () {
      final game = FootballEngine(random: Random(4))..start();
      final keeper = Aim.values[Random(4).nextInt(3)];
      final aim = Aim.values[(keeper.index + 1) % 3];
      expect(game.shoot(aim), true);
      expect(game.lastPlayerKick!.goal, true);
      expect(game.playerGoals, 1);
    });
    test('five rounds produce a result and lock inputs', () {
      final game = FootballEngine(random: Random(5), totalRounds: 5)..start();
      for (var i = 0; i < 5 && game.phase != MatchPhase.finished; i++) {
        expect(game.shoot(Aim.left), true);
        expect(game.defend(Aim.right), true);
      }
      expect(game.phase, MatchPhase.finished);
      expect(game.winner, isNotNull);
      expect(game.shoot(Aim.center), false);
    });
    test('reset clears score and starts again', () {
      final game = FootballEngine(random: Random(6))..start();
      game.shoot(Aim.right);
      game.defend(Aim.left);
      game.reset();
      expect(game.playerGoals, 0);
      expect(game.opponentGoals, 0);
      expect(game.playerShots, 0);
      expect(game.lastPlayerKick, null);
      expect(game.phase, MatchPhase.ready);
    });
  });
}
