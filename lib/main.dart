import 'package:flutter/material.dart';
import 'game/football_engine.dart';

void main() => runApp(const MiniFootballApp());

class MiniFootballApp extends StatelessWidget {
  const MiniFootballApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Mini Football',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green, brightness: Brightness.dark),
      useMaterial3: true,
    ),
    home: const PenaltyScreen(),
  );
}

class PenaltyScreen extends StatefulWidget {
  const PenaltyScreen({super.key});
  @override
  State<PenaltyScreen> createState() => _PenaltyScreenState();
}

class _PenaltyScreenState extends State<PenaltyScreen> {
  final FootballEngine game = FootballEngine();

  void act(Aim aim) => setState(() {
    if (game.phase == MatchPhase.playerTurn) {
      game.shoot(aim);
    } else if (game.phase == MatchPhase.opponentTurn) {
      game.defend(aim);
    }
  });

  Widget aimButton(Aim aim, IconData icon) => Expanded(child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: FilledButton.tonalIcon(
      key: ValueKey('aim-${aim.name}'),
      onPressed: game.phase == MatchPhase.playerTurn ||
              game.phase == MatchPhase.opponentTurn
          ? () => act(aim) : null,
      icon: Icon(icon, size: 19),
      label: Text(aim.name.toUpperCase(),
        style: const TextStyle(fontSize: 11)),
    ),
  ));

  @override
  Widget build(BuildContext context) {
    final isDefending = game.phase == MatchPhase.opponentTurn;
    return Scaffold(
      appBar: AppBar(
        title: const Text('MINI FOOTBALL'),
        actions: [IconButton(
          tooltip: 'Restart match',
          icon: const Icon(Icons.restart_alt),
          onPressed: () => setState(game.reset),
        )],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: ListView(padding: const EdgeInsets.all(18), children: [
          Text('PENALTY SHOOTOUT',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text('${game.playerGoals}  :  ${game.opponentGoals}',
            key: const ValueKey('score'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge),
          Text('Your kicks ${game.playerShots}/${game.totalRounds}'
              '    •    Opponent kicks ${game.opponentShots}/${game.totalRounds}',
            textAlign: TextAlign.center),
          const SizedBox(height: 16),
          AspectRatio(aspectRatio: 1.35,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF1F6A44),
                borderRadius: BorderRadius.circular(14)),
              child: Stack(children: [
                Positioned.fill(child: CustomPaint(painter: GoalPainter())),
                Align(alignment: const Alignment(0, -0.5),
                  child: Icon(isDefending ? Icons.sports_handball :
                    Icons.sports_soccer,
                    size: 65, color: Colors.white)),
                Align(alignment: const Alignment(0, 0.78),
                  child: Icon(isDefending ? Icons.sports_soccer :
                    Icons.sports_handball,
                    size: 55, color: Colors.white70)),
              ]),
            )),
          const SizedBox(height: 16),
          Semantics(liveRegion: true,
            child: Text(game.notice, textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium)),
          const SizedBox(height: 12),
          if (game.phase == MatchPhase.ready ||
              game.phase == MatchPhase.finished)
            FilledButton(
              onPressed: () => setState(() {
                if (game.phase == MatchPhase.finished) game.reset();
                game.start();
              }),
              child: Text(game.phase == MatchPhase.ready
                  ? 'Start Match' : 'Play Again'),
            ),
          if (game.phase == MatchPhase.playerTurn ||
              game.phase == MatchPhase.opponentTurn) ...[
            Text(isDefending ? 'Choose where your keeper dives'
                : 'Choose where to shoot',
              textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Row(children: [
              aimButton(Aim.left, Icons.arrow_back),
              aimButton(Aim.center, Icons.arrow_upward),
              aimButton(Aim.right, Icons.arrow_forward),
            ]),
          ],
          const SizedBox(height: 16),
          Text(game.lastPlayerKick == null ? 'Your last kick: —'
            : 'Your last kick: ${game.lastPlayerKick!.goal ? "GOAL" : "SAVED"}'),
          Text(game.lastOpponentKick == null ? 'Opponent last kick: —'
            : 'Opponent last kick: ${game.lastOpponentKick!.goal ? "GOAL" : "SAVED"}'),
          const SizedBox(height: 10),
          const Text('Take turns shooting and defending. Match ends after '
            'five rounds or when a lead cannot be overcome.',
            textAlign: TextAlign.center),
        ]),
      ))),
    );
  }
}

class GoalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final goal = Rect.fromLTWH(size.width * .12,
      size.height * .13, size.width * .76, size.height * .42);
    canvas.drawRect(goal, paint);
    final net = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    for (var i = 1; i < 8; i++) {
      final x = goal.left + goal.width * i / 8;
      canvas.drawLine(Offset(x, goal.top), Offset(x, goal.bottom), net);
    }
    for (var i = 1; i < 4; i++) {
      final y = goal.top + goal.height * i / 4;
      canvas.drawLine(Offset(goal.left, y), Offset(goal.right, y), net);
    }
    canvas.drawCircle(Offset(size.width / 2, size.height * .8), 5,
      Paint()..color = Colors.white);
  }
  @override
  bool shouldRepaint(covariant GoalPainter oldDelegate) => false;
}
