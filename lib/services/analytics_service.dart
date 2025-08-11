// lib/services/analytics_service.dart

import 'package:roozterfaceapp/models/fight_model.dart';

// Una clase simple para contener los resultados del análisis
class FightAnalytics {
  final int totalFights;
  final int wins;
  final int losses;
  final int draws;
  final double winRate;

  FightAnalytics({
    this.totalFights = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.winRate = 0.0,
  });
}

class AnalyticsService {
  // Calcula las estadísticas a partir de una lista de peleas
  FightAnalytics calculateFightAnalytics(List<FightModel> fights) {
    // Filtramos solo las peleas que están 'Completado'
    final completedFights = fights
        .where((f) => f.status == 'Completado')
        .toList();

    if (completedFights.isEmpty) {
      return FightAnalytics(); // Devuelve un objeto vacío si no hay peleas completadas
    }

    int wins = 0;
    int losses = 0;
    int draws = 0;

    for (var fight in completedFights) {
      switch (fight.result?.toLowerCase()) {
        case 'victoria':
          wins++;
          break;
        case 'derrota':
          losses++;
          break;
        case 'tabla':
          draws++;
          break;
      }
    }

    final totalFights = completedFights.length;
    final double winRate = totalFights > 0 ? (wins / totalFights) * 100 : 0.0;

    return FightAnalytics(
      totalFights: totalFights,
      wins: wins,
      losses: losses,
      draws: draws,
      winRate: winRate,
    );
  }
}
