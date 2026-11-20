import '../core/arcade.dart';
import '../core/level_plan.dart';
import '../core/missions.dart';
import '../core/stats.dart';
import 'soccer_engine.dart';

class FootballRules extends ArcadeRules<SoccerLevel> {
  @override
  String get gameId => 'game-081-mini-football';

  @override
  List<String> get optionalMechanics => const [];

  @override
  List<GameStat> get gameStats => const [
        GameStat('goals', 'Atılan gol', 'Goals scored', scale: 200),
        GameStat('matches_won', 'Kazanılan maç', 'Matches won', scale: 40),
        GameStat('tackles', 'Top kapma', 'Tackles', scale: 300),
        GameStat('saves', 'Kurtarış', 'Saves', scale: 100),
      ];

  @override
  List<MissionTemplate> get missionTemplates => const [
        MissionTemplate('goals', 'goals', [50, 100, 200]),
        MissionTemplate('matches_won', 'matches_won', [5, 10, 20], coinReward: 80),
      ];

  @override
  SoccerLevel generate(LevelSpec spec) => generateSoccer(spec);

  @override
  ArcadeMeta metaOf(SoccerLevel l) => l.meta;

  @override
  ArcadeSim createSim(SoccerLevel l) => SoccerSim(l);

  @override
  ArcadeInput bot(ArcadeSim sim) => soccerBot(sim);
}

ArcadeRules createRules() => FootballRules();
