// lib/screens/rooster_details_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/models/fight_model.dart';
import 'package:roozterfaceapp/models/health_log_model.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/screens/add_fight_screen.dart';
import 'package:roozterfaceapp/screens/add_health_log_screen.dart';
import 'package:roozterfaceapp/screens/add_rooster_screen.dart';
import 'package:roozterfaceapp/screens/fight_details_screen.dart';
import 'package:roozterfaceapp/screens/health_log_details_screen.dart';
import 'package:roozterfaceapp/screens/pedigree_screen.dart';
import 'package:roozterfaceapp/services/analytics_service.dart';
import 'package:roozterfaceapp/services/fight_service.dart';
import 'package:roozterfaceapp/services/health_service.dart';
import 'package:roozterfaceapp/widgets/fight_tile.dart';
import 'package:roozterfaceapp/widgets/health_log_tile.dart';

class RoosterDetailsScreen extends StatefulWidget {
  final RoosterModel rooster;

  const RoosterDetailsScreen({
    super.key,
    required this.rooster,
  });

  @override
  State<RoosterDetailsScreen> createState() => _RoosterDetailsScreenState();
}

class _RoosterDetailsScreenState extends State<RoosterDetailsScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final FightService _fightService = FightService();
  final HealthService _healthService = HealthService();
  final AnalyticsService _analyticsService = AnalyticsService();

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<bool> _deleteFight(BuildContext context, FightModel fight) async {
    final activeGalleraId =
        Provider.of<UserDataProvider>(context, listen: false)
            .userProfile
            ?.activeGalleraId;
    if (activeGalleraId == null) return false;

    try {
      await _fightService.deleteFight(
        galleraId: activeGalleraId,
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

  void _goToEditScreen(BuildContext context) {
    final userProvider = Provider.of<UserDataProvider>(context, listen: false);
    final userProfile = userProvider.userProfile;
    if (userProfile?.activeGalleraId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRoosterScreen(
          roosterToEdit: widget.rooster,
          currentUserPlan: userProfile!.plan,
          activeGalleraId: userProfile.activeGalleraId!,
        ),
      ),
    );
  }

  void _goToAddFightScreen(BuildContext context) {
    final activeGalleraId =
        Provider.of<UserDataProvider>(context, listen: false)
            .userProfile
            ?.activeGalleraId;
    if (activeGalleraId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFightScreen(
          galleraId: activeGalleraId,
          roosterId: widget.rooster.id,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _goToFightDetails(BuildContext context, FightModel fight) {
    final activeGalleraId =
        Provider.of<UserDataProvider>(context, listen: false)
            .userProfile
            ?.activeGalleraId;
    if (activeGalleraId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FightDetailsScreen(
          galleraId: activeGalleraId,
          roosterId: widget.rooster.id,
          fight: fight,
        ),
      ),
    );
  }

  void _goToAddHealthLogScreen(BuildContext context) {
    final activeGalleraId =
        Provider.of<UserDataProvider>(context, listen: false)
            .userProfile
            ?.activeGalleraId;
    if (activeGalleraId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddHealthLogScreen(
          galleraId: activeGalleraId,
          roosterId: widget.rooster.id,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _goToHealthLogDetails(BuildContext context, HealthLogModel log) {
    final activeGalleraId =
        Provider.of<UserDataProvider>(context, listen: false)
            .userProfile
            ?.activeGalleraId;
    if (activeGalleraId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthLogDetailsScreen(
          galleraId: activeGalleraId,
          roosterId: widget.rooster.id,
          log: log,
        ),
      ),
    );
  }

  void _goToPedigreeScreen(BuildContext context) {
    final activeGalleraId =
        Provider.of<UserDataProvider>(context, listen: false)
            .userProfile
            ?.activeGalleraId;
    if (activeGalleraId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PedigreeScreen(
          initialRooster: widget.rooster,
          galleraId: activeGalleraId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserDataProvider>(context);
    final userProfile = userProvider.userProfile;

    if (userProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isMaestroOrHigher =
        userProfile.plan == 'maestro' || userProfile.plan == 'elite';
    final bool isEliteUser = userProfile.plan == 'elite';
    final String activeGalleraId = userProfile.activeGalleraId ?? '';

    int tabCount = 1; // General
    if (isMaestroOrHigher) tabCount++; // Combates
    if (isMaestroOrHigher) tabCount++; // Salud
    if (isEliteUser) tabCount++; // Analítica

    if (_tabController == null || _tabController!.length != tabCount) {
      _tabController?.dispose();
      _tabController = TabController(length: tabCount, vsync: this);
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _goToEditScreen(context),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  widget.rooster.name,
                  style: const TextStyle(
                    fontSize: 16.0,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
                background: Hero(
                  tag: widget.rooster.id,
                  child: widget.rooster.imageUrl.isNotEmpty
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
                              child: Icon(Icons.shield_outlined,
                                  size: 100, color: Colors.grey)),
                        ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: Container(
                  color: Theme.of(context).appBarTheme.backgroundColor,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: tabCount > 2,
                    tabs: [
                      const Tab(text: 'General'),
                      if (isMaestroOrHigher) const Tab(text: 'Combates'),
                      if (isMaestroOrHigher) const Tab(text: 'Salud'),
                      if (isEliteUser) const Tab(text: 'Analítica'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildGeneralInfoTab(context, isEliteUser),
            if (isMaestroOrHigher) _buildFightsTab(context, activeGalleraId),
            if (isMaestroOrHigher) _buildHealthTab(context, activeGalleraId),
            if (isEliteUser) _buildAnalyticsTab(context, activeGalleraId),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralInfoTab(BuildContext context, bool isEliteUser) {
    final DateFormat formatter = DateFormat('dd de MMMM de yyyy', 'es_ES');
    final String formattedBirthDate =
        formatter.format(widget.rooster.birthDate.toDate());
    final String fatherDisplay = widget.rooster.fatherName ??
        widget.rooster.fatherLineageText ??
        'No registrado';
    final String motherDisplay = widget.rooster.motherName ??
        widget.rooster.motherLineageText ??
        'No registrada';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(context,
              icon: Icons.badge,
              label: 'Placa',
              value: widget.rooster.plate.isNotEmpty
                  ? widget.rooster.plate
                  : 'N/A'),
          const Divider(),
          _buildDetailRow(context,
              icon: Icons.cake, label: 'Nacimiento', value: formattedBirthDate),
          const Divider(),
          _buildDetailRow(context,
              icon: Icons.monitor_heart,
              label: 'Estado',
              value: widget.rooster.status),
          const Divider(),
          const SizedBox(height: 16),
          Text("Características",
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _buildDetailRow(context,
              icon: Icons.shield,
              label: 'Línea / Casta',
              value: widget.rooster.breedLine ?? 'No registrada'),
          const Divider(),
          _buildDetailRow(context,
              icon: Icons.palette,
              label: 'Color',
              value: widget.rooster.color ?? 'No registrado'),
          const Divider(),
          _buildDetailRow(context,
              icon: Icons.content_cut,
              label: 'Tipo de Cresta',
              value: widget.rooster.combType ?? 'No registrado'),
          const Divider(),
          _buildDetailRow(context,
              icon: Icons.square_foot,
              label: 'Color de Patas',
              value: widget.rooster.legColor ?? 'No registrado'),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Linaje", style: Theme.of(context).textTheme.titleLarge),
              if (isEliteUser)
                TextButton.icon(
                  icon: const Icon(Icons.account_tree),
                  label: const Text("Ver Árbol"),
                  onPressed: () => _goToPedigreeScreen(context),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDetailRow(context,
              icon: Icons.male, label: 'Línea Paterna', value: fatherDisplay),
          const Divider(),
          _buildDetailRow(context,
              icon: Icons.female, label: 'Línea Materna', value: motherDisplay),
        ],
      ),
    );
  }

  Widget _buildFightsTab(BuildContext context, String activeGalleraId) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.add_circle),
              label: const Text("Programar Combate"),
              onPressed: () => _goToAddFightScreen(context),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<FightModel>>(
            stream: _fightService.getFightsStream(
                activeGalleraId, widget.rooster.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text("No hay eventos registrados."));
              }
              final fights = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(8),
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
                        child: const Icon(Icons.delete, color: Colors.white)),
                    confirmDismiss: (direction) async {
                      bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text("Confirmar Borrado"),
                          content: const Text(
                              "¿Estás seguro de que quieres borrar este evento de combate?"),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.of(c).pop(false),
                                child: const Text("Cancelar")),
                            TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                onPressed: () => Navigator.of(c).pop(true),
                                child: const Text("Borrar")),
                          ],
                        ),
                      );
                      if (confirm != true) return false;
                      return await _deleteFight(context, fight);
                    },
                    child: FightTile(
                        fight: fight,
                        onTap: () => _goToFightDetails(context, fight)),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHealthTab(BuildContext context, String activeGalleraId) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.add_circle),
              label: const Text("Añadir Registro"),
              onPressed: () => _goToAddHealthLogScreen(context),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<HealthLogModel>>(
            stream: _healthService.getHealthLogsStream(
                activeGalleraId, widget.rooster.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text("No hay registros de salud."));
              }
              final logs = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return HealthLogTile(
                      log: log,
                      onTap: () => _goToHealthLogDetails(context, log));
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab(BuildContext context, String activeGalleraId) {
    return StreamBuilder<List<FightModel>>(
      stream: _fightService.getFightsStream(activeGalleraId, widget.rooster.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text("No hay datos de combate para generar analíticas."));
        }

        final analytics =
            _analyticsService.calculateFightAnalytics(snapshot.data!);
        if (analytics.totalFights == 0) {
          return const Center(
              child: Text("Aún no hay combates completados para analizar."));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text("Rendimiento General",
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: [
                      if (analytics.wins > 0)
                        PieChartSectionData(
                            value: analytics.wins.toDouble(),
                            title: '${analytics.wins}V',
                            color: Colors.green,
                            radius: 80,
                            titleStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      if (analytics.losses > 0)
                        PieChartSectionData(
                            value: analytics.losses.toDouble(),
                            title: '${analytics.losses}D',
                            color: Colors.red,
                            radius: 80,
                            titleStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      if (analytics.draws > 0)
                        PieChartSectionData(
                            value: analytics.draws.toDouble(),
                            title: '${analytics.draws}T',
                            color: Colors.orange,
                            radius: 80,
                            titleStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                    ],
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildAnalyticsRow("Total de Combates:",
                          analytics.totalFights.toString()),
                      const Divider(),
                      _buildAnalyticsRow("Porcentaje de Victorias:",
                          "${analytics.winRate.toStringAsFixed(1)}%"),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context,
      {required IconData icon, required String label, required String value}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.secondary, size: 20),
          const SizedBox(width: 16),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
              child: Text(value, textAlign: TextAlign.right, softWrap: true)),
        ],
      ),
    );
  }
}
