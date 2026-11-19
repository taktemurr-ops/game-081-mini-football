import 'dart:math';

enum Aim { left, center, right }
enum MatchPhase { ready, playerTurn, opponentTurn, finished }
enum Winner { player, opponent, draw }

class KickResult {
  final Aim aimed;
  final Aim keeper;
  final bool goal;
  const KickResult(this.aimed, this.keeper, this.goal);
}

/// Five-round offline penalty shootout against an AI opponent.
/// No network or real-money transactions.
class FootballEngine {
  final Random random;
  final int totalRounds;
  MatchPhase phase = MatchPhase.ready;
  Winner? winner;
  int playerGoals = 0;
  int opponentGoals = 0;
  int playerShots = 0;
  int opponentShots = 0;
  KickResult? lastPlayerKick;
  KickResult? lastOpponentKick;
  String notice = 'Choose a corner to start the penalty shootout.';

  FootballEngine({Random? random, this.totalRounds = 5})
      : assert(totalRounds > 0),
        random = random ?? Random() {
    reset();
  }

  void reset() {
    phase = MatchPhase.ready;
    winner = null;
    playerGoals = 0;
    opponentGoals = 0;
    playerShots = 0;
    opponentShots = 0;
    lastPlayerKick = null;
    lastOpponentKick = null;
    notice = 'Choose a corner and take your shot!';
  }

  void start() {
    if (phase != MatchPhase.ready) return;
    phase = MatchPhase.playerTurn;
    notice = 'Your turn. Aim and shoot.';
  }

  bool shoot(Aim aim) {
    if (phase != MatchPhase.playerTurn) return false;
    final keeper = Aim.values[random.nextInt(Aim.values.length)];
    final scored = aim != keeper;
    lastPlayerKick = KickResult(aim, keeper, scored);
    playerShots++;
    if (scored) playerGoals++;
    notice = scored ? 'GOAL! Great finish.' : 'Saved by the goalkeeper!';
    phase = MatchPhase.opponentTurn;
    return true;
  }

  bool defend(Aim dive) {
    if (phase != MatchPhase.opponentTurn) return false;
    final aimed = Aim.values[random.nextInt(Aim.values.length)];
    final scored = aimed != dive;
    lastOpponentKick = KickResult(aimed, dive, scored);
    opponentShots++;
    if (scored) opponentGoals++;
    notice = scored ? 'They scored. Stay focused.' : 'Amazing save!';
    _resolve();
    return true;
  }

  int get playerRemaining => totalRounds - playerShots;
  int get opponentRemaining => totalRounds - opponentShots;

  void _resolve() {
    // Clinch early when an opponent cannot mathematically catch up.
    if (playerGoals > opponentGoals + opponentRemaining) {
      _finish(Winner.player);
    } else if (opponentGoals > playerGoals + playerRemaining) {
      _finish(Winner.opponent);
    } else if (playerShots == totalRounds && opponentShots == totalRounds) {
      _finish(playerGoals > opponentGoals
          ? Winner.player
          : opponentGoals > playerGoals
              ? Winner.opponent
              : Winner.draw);
    } else {
      phase = MatchPhase.playerTurn;
    }
  }

  void _finish(Winner result) {
    winner = result;
    phase = MatchPhase.finished;
    notice = switch (result) {
      Winner.player => 'You win the shootout!',
      Winner.opponent => 'The opponents win. Try again!',
      Winner.draw => 'It is a draw! Play a rematch.',
    };
  }
}
