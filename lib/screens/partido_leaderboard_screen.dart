// lib/screens/partido_leaderboard_screen.dart

import 'package:flutter/material.dart';
import 'package:roozterfaceapp/models/partido_model.dart';
import 'package:roozterfaceapp/services/partido_service.dart';

class PartidoLeaderboardScreen extends StatelessWidget {
  const PartidoLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PartidoService partidoService = PartidoService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking de Partidos'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[900]!, Colors.black],
          ),
        ),
        child: StreamBuilder<List<PartidoModel>>(
          stream: partidoService.getAllPartidosStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.amber));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Aún no hay equipos registrados.', style: TextStyle(color: Colors.white54)));
            }

            // Calculamos el ranking localmente
            final List<PartidoModel> ranking = snapshot.data!;
            ranking.sort((a, b) {
              double pctA = a.totalFights > 0 ? (a.wins / a.totalFights) : 0;
              double pctB = b.totalFights > 0 ? (b.wins / b.totalFights) : 0;
              return pctB.compareTo(pctA); // Descendente
            });

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 20),
              itemCount: ranking.length,
              itemBuilder: (context, index) {
                final partido = ranking[index];
                double winPct = partido.totalFights > 0 ? (partido.wins / partido.totalFights * 100) : 0;
                
                return _buildLeaderboardCard(context, index + 1, partido, winPct);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeaderboardCard(BuildContext context, int position, PartidoModel partido, double winPct) {
    Color positionColor = Colors.white24;
    if (position == 1) positionColor = Colors.amber;
    if (position == 2) positionColor = Colors.grey[400]!;
    if (position == 3) positionColor = Colors.brown[300]!;

    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: position <= 3 ? positionColor.withOpacity(0.5) : Colors.transparent)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(
                '#$position',
                style: TextStyle(
                  color: positionColor,
                  fontWeight: FontWeight.bold,
                  fontSize: position <= 3 ? 24 : 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white10,
              backgroundImage: partido.logoUrl != null ? NetworkImage(partido.logoUrl!) : null,
              child: partido.logoUrl == null ? const Icon(Icons.shield, color: Colors.white38) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partido.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStatTag('W: ${partido.wins}', Colors.green),
                      const SizedBox(width: 8),
                      _buildStatTag('L: ${partido.losses}', Colors.red),
                      const SizedBox(width: 8),
                      _buildStatTag('Bajas: ${partido.lostRoosters}', Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${winPct.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Text('Efectividad', style: TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
