// lib/screens/tournament_hub_screen.dart

import 'package:flutter/material.dart';
import 'package:roozterfaceapp/models/tournament_model.dart';
import 'package:roozterfaceapp/models/tournament_participant.dart';
import 'package:roozterfaceapp/services/tournament_service.dart';

class TournamentHubScreen extends StatefulWidget {
  final TournamentModel tournament;
  const TournamentHubScreen({super.key, required this.tournament});

  @override
  State<TournamentHubScreen> createState() => _TournamentHubScreenState();
}

class _TournamentHubScreenState extends State<TournamentHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TournamentService _tournamentService = TournamentService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.tournament.name),
        backgroundColor: Colors.grey[900],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(text: 'PESAJE', icon: Icon(Icons.scale)),
            Tab(text: 'COTEJO', icon: Icon(Icons.compare_arrows)),
            Tab(text: 'RANKING', icon: Icon(Icons.emoji_events)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPesajeTab(),
          _buildCotejoTab(),
          _buildRankingTab(),
        ],
      ),
    );
  }

  Widget _buildPesajeTab() {
    return StreamBuilder<List<TournamentParticipant>>(
      stream: _tournamentService.getParticipantsStream(widget.tournament.id),
      builder: (context, snapshot) {
        final participants = snapshot.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: participants.length,
          itemBuilder: (context, index) {
            final p = participants[index];
            return Card(
              color: Colors.white10,
              child: ExpansionTile(
                title: Text(p.partidoName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('${p.birds.length} Aves', style: const TextStyle(color: Colors.white54)),
                children: p.birds.map((b) => ListTile(
                  title: Text('Anillo: ${b.ringNumber}', style: const TextStyle(color: Colors.white70)),
                  trailing: Text('${b.weight}g', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                )).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCotejoTab() {
    return const Center(child: Text('Funcionalidad de Cotejo en Desarrollo', style: TextStyle(color: Colors.white38)));
  }

  Widget _buildRankingTab() {
    // Reutilizamos el ranking existente
    return const Center(child: Text('Consulta el Ranking en la pantalla principal del torneo', style: TextStyle(color: Colors.white38)));
  }
}
