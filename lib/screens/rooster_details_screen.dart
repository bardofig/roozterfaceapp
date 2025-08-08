// lib/screens/rooster_details_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:roozterfaceapp/models/fight_model.dart';
import 'package:roozterfaceapp/models/health_log_model.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/models/user_model.dart';
import 'package:roozterfaceapp/screens/add_fight_screen.dart';
import 'package:roozterfaceapp/screens/add_health_log_screen.dart';
import 'package:roozterfaceapp/screens/add_rooster_screen.dart';
import 'package:roozterfaceapp/screens/health_log_details_screen.dart';
import 'package:roozterfaceapp/services/fight_service.dart';
import 'package:roozterfaceapp/services/health_service.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';
import 'package:roozterfaceapp/widgets/fight_tile.dart';
import 'package:roozterfaceapp/widgets/health_log_tile.dart';

class RoosterDetailsScreen extends StatefulWidget {
  final RoosterModel rooster;
  const RoosterDetailsScreen({super.key, required this.rooster});
  @override
  State<RoosterDetailsScreen> createState() => _RoosterDetailsScreenState();
}

class _RoosterDetailsScreenState extends State<RoosterDetailsScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final RoosterService _roosterService = RoosterService();
  final FightService _fightService = FightService();
  final HealthService _healthService = HealthService();

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _goToEditScreen(String currentUserPlan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRoosterScreen(
          roosterToEdit: widget.rooster,
          currentUserPlan: currentUserPlan,
        ),
      ),
    );
  }

  void _goToAddFightScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFightScreen(roosterId: widget.rooster.id),
        fullscreenDialog: true,
      ),
    );
  }

  void _goToEditFightScreen(FightModel fight) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddFightScreen(roosterId: widget.rooster.id, fightToEdit: fight),
        fullscreenDialog: true,
      ),
    );
  }

  void _goToAddHealthLogScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddHealthLogScreen(roosterId: widget.rooster.id),
        fullscreenDialog: true,
      ),
    );
  }

  void _goToHealthLogDetails(HealthLogModel log) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            HealthLogDetailsScreen(roosterId: widget.rooster.id, log: log),
      ),
    );
  }

  Future<bool> _deleteFight(FightModel fight) async {
    try {
      await _fightService.deleteFight(
        roosterId: widget.rooster.id,
        fightId: fight.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento de combate borrado.')),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al borrar: ${e.toString()}')),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: _roosterService.getUserProfileStream(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final userProfile = UserModel.fromFirestore(userSnapshot.data!);
          final bool isMaestroOrHigher = userProfile.plan != 'iniciacion';
          final int tabCount = isMaestroOrHigher ? 3 : 1;
          if (_tabController == null || _tabController!.length != tabCount) {
            _tabController?.dispose();
            _tabController = TabController(length: tabCount, vsync: this);
          }
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 250.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.grey[900],
                  foregroundColor: Colors.white,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _goToEditScreen(userProfile.plan),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Text(
                      widget.rooster.name,
                      style: const TextStyle(fontSize: 16.0),
                    ),
                    background: widget.rooster.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.rooster.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (c, u) =>
                                Container(color: Colors.grey[300]),
                            errorWidget: (c, u, e) =>
                                const Icon(Icons.broken_image),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(
                                Icons.shield_outlined,
                                size: 100,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                  ),
                  bottom: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[400],
                    tabs: [
                      const Tab(
                        icon: Icon(Icons.info_outline),
                        text: 'General',
                      ),
                      if (isMaestroOrHigher)
                        const Tab(
                          icon: Icon(Icons.sports_kabaddi),
                          text: 'Combates',
                        ),
                      if (isMaestroOrHigher)
                        const Tab(
                          icon: Icon(Icons.health_and_safety),
                          text: 'Salud',
                        ),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralInfoTab(),
                if (isMaestroOrHigher) _buildFightsTab(),
                if (isMaestroOrHigher) _buildHealthTab(),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- ¡PESTAÑA GENERAL ACTUALIZADA! ---
  Widget _buildGeneralInfoTab() {
    final DateFormat formatter = DateFormat('dd de MMMM de yyyy', 'es_ES');
    final String formattedBirthDate = formatter.format(
      widget.rooster.birthDate.toDate(),
    );
    final String fatherDisplay =
        widget.rooster.fatherName ??
        widget.rooster.fatherLineageText ??
        'No registrado';
    final String motherDisplay =
        widget.rooster.motherName ??
        widget.rooster.motherLineageText ??
        'No registrada';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Sección de Datos Básicos ---
          _buildDetailRow(
            icon: Icons.badge,
            label: 'Placa',
            value: widget.rooster.plate.isNotEmpty
                ? widget.rooster.plate
                : 'N/A',
          ),
          const Divider(),
          _buildDetailRow(
            icon: Icons.cake,
            label: 'Nacimiento',
            value: formattedBirthDate,
          ),
          const Divider(),
          _buildDetailRow(
            icon: Icons.monitor_heart,
            label: 'Estado',
            value: widget.rooster.status,
          ),
          const Divider(),

          // --- Sección de Características Físicas ---
          const SizedBox(height: 16),
          Text(
            "Características",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            icon: Icons.shield,
            label: 'Línea / Casta',
            value: widget.rooster.breedLine ?? 'No registrada',
          ),
          const Divider(),
          _buildDetailRow(
            icon: Icons.palette,
            label: 'Color',
            value: widget.rooster.color ?? 'No registrado',
          ),
          const Divider(),
          _buildDetailRow(
            icon: Icons.content_cut,
            label: 'Tipo de Cresta',
            value: widget.rooster.combType ?? 'No registrado',
          ),
          const Divider(),
          _buildDetailRow(
            icon: Icons.square_foot,
            label: 'Color de Patas',
            value: widget.rooster.legColor ?? 'No registrado',
          ),
          const Divider(),

          // --- Sección de Linaje (Ahora separada) ---
          const SizedBox(height: 16),
          Text("Linaje", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _buildDetailRow(
            icon: Icons.male,
            label: 'Línea Paterna',
            value: fatherDisplay,
          ),
          const Divider(),
          _buildDetailRow(
            icon: Icons.female,
            label: 'Línea Materna',
            value: motherDisplay,
          ),
        ],
      ),
    );
  }

  Widget _buildFightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.add_circle, color: Colors.black),
              label: const Text(
                "Programar Combate",
                style: TextStyle(color: Colors.black),
              ),
              onPressed: _goToAddFightScreen,
            ),
          ),
          StreamBuilder<List<FightModel>>(
            stream: _fightService.getFightsStream(widget.rooster.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text("No hay eventos registrados."),
                );
              }
              final fights = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: fights.length,
                itemBuilder: (context, index) {
                  final fight = fights[index];
                  return Dismissible(
                    key: Key(fight.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text("Confirmar Borrado"),
                          content: const Text(
                            "¿Estás seguro de que quieres borrar este evento de combate?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(c).pop(false),
                              child: const Text("Cancelar"),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              onPressed: () => Navigator.of(c).pop(true),
                              child: const Text("Borrar"),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true) return false;
                      return await _deleteFight(fight);
                    },
                    child: FightTile(
                      fight: fight,
                      onTap: () => _goToEditFightScreen(fight),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.add_circle, color: Colors.black),
              label: const Text(
                "Añadir Registro",
                style: TextStyle(color: Colors.black),
              ),
              onPressed: _goToAddHealthLogScreen,
            ),
          ),
          StreamBuilder<List<HealthLogModel>>(
            stream: _healthService.getHealthLogsStream(widget.rooster.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text("No hay registros de salud."),
                );
              }
              final logs = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return HealthLogTile(
                    log: log,
                    onTap: () => _goToHealthLogDetails(log),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 16),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value, textAlign: TextAlign.right, softWrap: true),
          ),
        ],
      ),
    );
  }
}
