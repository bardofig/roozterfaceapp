// lib/screens/team_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/models/partido_model.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/services/partido_service.dart';

class TeamDashboardScreen extends StatelessWidget {
  const TeamDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<UserDataProvider>(context).userProfile;
    final partidoService = PartidoService();

    // Verificamos activePartidoId que es el nombre correcto en UserModel
    if (userProfile == null || userProfile.activePartidoId == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.group_off_outlined, size: 80, color: Colors.white10),
              const SizedBox(height: 16),
              const Text('No perteneces a ningún equipo.', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // TODO: Ir a pantalla de creación/unión de partido
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: const Text('Unirse a un Partido', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<PartidoModel?>(
        stream: partidoService.getActivePartidoStream(userProfile.activePartidoId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }
          final partido = snapshot.data;
          if (partido == null) {
            return const Center(child: Text('Error al cargar el equipo.', style: TextStyle(color: Colors.white)));
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: Colors.grey[900],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(partido.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (partido.logoUrl != null)
                        Image.network(partido.logoUrl!, fit: BoxFit.cover)
                      else
                        Container(
                          color: Colors.grey[850],
                          child: const Icon(Icons.shield, size: 80, color: Colors.white10),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsRow(partido),
                      const SizedBox(height: 30),
                      const Text('Integrantes del Partido',
                          style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final uid = partido.members.keys.elementAt(index);
                    final role = partido.members[uid];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.white10,
                          child: Icon(Icons.person, color: Colors.white38),
                        ),
                        title: Text('Socio #${index + 1}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(role?.toUpperCase() ?? 'Miembro',
                            style: TextStyle(color: Colors.amber.withOpacity(0.7), fontSize: 12)),
                        trailing: role == 'propietario'
                            ? const Icon(Icons.star, color: Colors.amber, size: 16)
                            : null,
                      ),
                    );
                  },
                  childCount: partido.members.length,
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(PartidoModel partido) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Peleas', '${partido.totalFights}'),
        _buildStatItem('Victorias', '${partido.wins}'),
        _buildStatItem('Bajas', '${partido.lostRoosters}'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }
}
