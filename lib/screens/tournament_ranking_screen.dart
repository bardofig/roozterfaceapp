// lib/screens/tournament_ranking_screen.dart

import 'package:flutter/material.dart';
import 'package:roozterfaceapp/models/tournament_model.dart';
import 'package:roozterfaceapp/models/tournament_participant.dart';
import 'package:roozterfaceapp/services/tournament_service.dart';

class TournamentRankingScreen extends StatelessWidget {
  final TournamentModel tournament;
  final TournamentService _tournamentService = TournamentService();

  TournamentRankingScreen({super.key, required this.tournament});

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${tournament.name} - Ranking'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Lógica de Ranking'),
                  content: const Text(
                      '1. Puntos (Gana=3, Empate=1).\n'
                      '2. Tiempo de Fondo (Menor tiempo acumulado desempata).\n'
                      'Este sistema garantiza que los gallos más letales y rápidos ganen.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<TournamentParticipant>>(
        stream: _tournamentService.getParticipantsStream(tournament.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }
          
          final participants = snapshot.data ?? [];
          
          // Lógica de Ordenamiento Profesional:
          // 1. Puntos (Descendente)
          // 2. Tiempo de Fondo (Ascendente)
          participants.sort((a, b) {
            if (b.totalPoints != a.totalPoints) {
              return b.totalPoints.compareTo(a.totalPoints);
            }
            return a.totalTimeSeconds.compareTo(b.totalTimeSeconds);
          });

          if (participants.isEmpty) {
            return const Center(child: Text('Aún no hay participantes registrados.', style: TextStyle(color: Colors.white54)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final participant = participants[index];
              final isTop3 = index < 3;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isTop3 
                      ? [Colors.amber.withOpacity(0.2), Colors.transparent]
                      : [Colors.grey[900]!, Colors.transparent],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: isTop3 ? Colors.amber.withOpacity(0.5) : Colors.white10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isTop3 ? Colors.amber : Colors.grey[800],
                    child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                  title: Text(participant.partidoName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text('Tiempo de Fondo: ${_formatTime(participant.totalTimeSeconds)}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${participant.totalPoints} PTS', style: const TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.w900)),
                      const Text('PUNTUACIÓN', style: TextStyle(color: Colors.white38, fontSize: 8)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
