import 'package:flutter/material.dart';

import 'package:studio_core/app/arcade_stage.dart';
import 'package:studio_core/app/game_api.dart';
import 'package:studio_core/core/game_rules.dart';
import 'soccer_engine.dart';
import 'soccer_view.dart';
import 'rules.dart';

final gameConfig = GameConfig(
  gameId: 'game-081-mini-football',
  title: const ['Mini Futbol', 'Mini Football', 'Mini-Fußball', 'Mini Fútbol', 'Mini Football'],
  tagline: const ['Çalım at, şut çek, maçı kazan!', 'Dribble, shoot and win the match!', 'Dribbeln, schießen, gewinnen!', '¡Regatea, chuta y gana!', 'Dribblez, tirez, gagnez !'],
  seedColor: const Color(0xFF2D6A4F),
  icon: Icons.sports_soccer,
  rules: FootballRules(),
  buildPlay: (ctx) => ArcadeStage(
    ctx: ctx,
    create: () => SoccerSim((ctx.generated as GeneratedLevel<SoccerLevel>).puzzle),
    paint: paintSoccer,
    sound: soccerSound,
    boosterIcon: Icons.bolt,
    boosterLabel: (l) => l == 'tr' ? 'Sprint' : 'Sprint',
    howTo: const ['Basılı tutup kaydır: oyuncunu yönet (sanal joystick). Kısa dokun: şut. Rakibe yaklaş: top kap.', 'Hold and slide to run (virtual joystick). Quick tap: shoot. Run into a rival to tackle.', 'Halten und ziehen: laufen. Kurz tippen: Schuss.', 'Mantén y desliza: correr. Toque corto: chutar.', 'Maintenez et glissez : courir. Touche courte : tirer.'],
  ),
  tutorial: const [
    TutorialStep(Icons.open_with, ['Basılı tutup kaydırarak topla birlikte koş.', 'Hold and slide to run with the ball.', 'Mit dem Ball laufen.', 'Corre con el balón.', 'Courez avec le ballon.']),
    TutorialStep(Icons.sports_soccer, ['Ceza sahasına yaklaşınca kısa dokun: şut!', 'Near the box, tap quickly to shoot!', 'Kurz tippen: Schuss!', 'Toca rápido: ¡chut!', 'Touchez vite : tir !']),
    TutorialStep(Icons.shield, ['Rakip topu aldıysa ona yaklaş ve geri kap.', 'If a rival has the ball, run into him to win it back.', 'Ball zurückerobern.', 'Recupera el balón.', 'Récupérez le ballon.']),
  ],
);
