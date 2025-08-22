// lib/screens/rooster_details_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/models/breeding_event_model.dart';
import 'package:roozterfaceapp/models/fight_model.dart';
import 'package:roozterfaceapp/models/health_log_model.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/screens/add_fight_screen.dart';
import 'package:roozterfaceapp/screens/add_health_log_screen.dart';
import 'package:roozterfaceapp/screens/add_rooster_screen.dart';
import 'package:roozterfaceapp/screens/breeding_details_screen.dart';
import 'package:roozterfaceapp/screens/fight_details_screen.dart';
import 'package:roozterfaceapp/screens/health_log_details_screen.dart';
import 'package:roozterfaceapp/screens/pedigree_screen.dart';
import 'package:roozterfaceapp/services/analytics_service.dart';
import 'package:roozterfaceapp/services/breeding_service.dart';
import 'package:roozterfaceapp/services/fight_service.dart';
import 'package:roozterfaceapp/services/health_service.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';
import 'package:roozterfaceapp/widgets/breeding_event_tile.dart';
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
  final BreedingService _breedingService = BreedingService();
  final RoosterService _roosterService = RoosterService();

  late Future<HenProductionStats> _henStatsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setupTabController(widget.rooster);
        if (widget.rooster.sex == 'hembra') {
          _loadHenStats();
        }
      }
    });
  }

  void _loadHenStats() {
    final activeGalleraId =
        Provider.of<UserDataProvider>(context, listen: false)
            .userProfile
            ?.activeGalleraId;
    if (activeGalleraId != null) {
      setState(() {
        _henStatsFuture = _breedingService.getHenProductionStats(
          galleraId: activeGalleraId,
          henId: widget.rooster.id,
        );
      });
    }
  }

  void _setupTabController(RoosterModel forRooster) {
    final userProvider = Provider.of<UserDataProvider>(context, listen: false);
    final userProfile = userProvider.userProfile;
    if (userProfile == null) return;

    final isMaestroOrHigher =
        userProfile.plan == 'maestro' || userProfile.plan == 'elite';
    final isEliteUser = userProfile.plan == 'elite';
    final currentRoosterSex = forRooster.sex;

    int tabCount = 1;
    if (isMaestroOrHigher) {
      if (currentRoosterSex == 'hembra') tabCount++;
      tabCount++;
      if (currentRoosterSex == 'macho') tabCount++;
      tabCount++;
      if (currentRoosterSex == 'macho' && isEliteUser) tabCount++;
    }

    if (_tabController?.length != tabCount) {
      final initialIndex = _tabController?.index ?? 0;
      _tabController?.dispose();
      _tabController = TabController(
          length: tabCount,
          vsync: this,
          initialIndex: initialIndex < tabCount ? initialIndex : 0);
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _showSaleDialog(BuildContext context, String activeGalleraId,
      RoosterModel rooster) async {
    final formKey = GlobalKey<FormState>();
    final priceController = TextEditingController(
        text:
            rooster.salePrice?.toStringAsFixed(2).replaceAll('.00', '') ?? '');
    final buyerController = TextEditingController();
    final notesController = TextEditingController();
    DateTime saleDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Registrar Venta'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(
                            labelText: 'Precio de Venta *', prefixText: '\$'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'El precio es obligatorio';
                          if (double.tryParse(v) == null ||
                              double.parse(v) <= 0)
                            return 'Ingrese un precio válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: buyerController,
                        decoration: const InputDecoration(
                            labelText: 'Nombre del Comprador *'),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'El comprador es obligatorio'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: notesController,
                        decoration: const InputDecoration(
                            labelText: 'Notas de Venta (Opcional)'),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child: Text(
                                  'Fecha Venta: ${DateFormat('dd/MM/yyyy').format(saleDate)}')),
                          TextButton(
                            child: const Text('Cambiar'),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                  context: context,
                                  initialDate: saleDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now());
                              if (picked != null) {
                                setDialogState(() => saleDate = picked);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        await _roosterService.recordSale(
                          galleraId: activeGalleraId,
                          roosterId: rooster.id,
                          salePrice: double.parse(priceController.text),
                          saleDate: saleDate,
                          buyerName: buyerController.text.trim(),
                          saleNotes: notesController.text.trim(),
                        );
                        if (mounted) Navigator.of(ctx).pop();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  "Error al registrar venta: ${e.toString()}"),
                              backgroundColor: Colors.red));
                        }
                      }
                    }
                  },
                  child: const Text('Confirmar Venta'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _goToEditScreen(BuildContext context, RoosterModel rooster) {
    final userProvider = Provider.of<UserDataProvider>(context, listen: false);
    final userProfile = userProvider.userProfile;
    if (userProfile?.activeGalleraId == null) return;
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddRoosterScreen(
              roosterToEdit: rooster,
              currentUserPlan: userProfile!.plan,
              activeGalleraId: userProfile.activeGalleraId!),
        ));
  }

  void _goToAddFightScreen(BuildContext context, RoosterModel rooster) {
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
              roosterId: rooster.id,
              roosterName: rooster.name),
          fullscreenDialog: true,
        ));
  }

  void _goToFightDetails(
      BuildContext context, FightModel fight, RoosterModel rooster) {
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
              roosterId: rooster.id,
              roosterName: rooster.name,
              fight: fight),
        ));
  }

  void _goToAddHealthLogScreen(BuildContext context, RoosterModel rooster) {
    final activeGalleraId =
        Provider.of<UserDataProvider>(context, listen: false)
            .userProfile
            ?.activeGalleraId;
    if (activeGalleraId == null) return;
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddHealthLogScreen(
              galleraId: activeGalleraId, roosterId: rooster.id),
          fullscreenDialog: true,
        ));
  }

  void _goToHealthLogDetails(
      BuildContext context, HealthLogModel log, RoosterModel rooster) {
    final activeGalleraId =
        Provider.of<UserDataProvider>(context, listen: false)
            .userProfile
            ?.activeGalleraId;
    if (activeGalleraId == null) return;
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HealthLogDetailsScreen(
              galleraId: activeGalleraId, roosterId: rooster.id, log: log),
        ));
  }

  void _goToPedigreeScreen(BuildContext context, RoosterModel rooster) {
    final activeGalleraId =
        Provider.of<UserDataProvider>(context, listen: false)
            .userProfile
            ?.activeGalleraId;
    if (activeGalleraId == null) return;
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PedigreeScreen(
              initialRooster: rooster, galleraId: activeGalleraId),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserDataProvider>(context, listen: false);
    final userProfile = userProvider.userProfile;
    final activeGalleraId = userProfile?.activeGalleraId;

    if (userProfile == null ||
        _tabController == null ||
        activeGalleraId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('galleras')
          .doc(activeGalleraId)
          .collection('gallos')
          .doc(widget.rooster.id)
          .snapshots(),
      builder: (context, snapshot) {
        final currentRooster = snapshot.hasData && snapshot.data!.exists
            ? RoosterModel.fromFirestore(snapshot.data!)
            : widget.rooster;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _setupTabController(currentRooster);
          }
        });

        if (_tabController == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final isMaestroOrHigher =
            userProfile.plan == 'maestro' || userProfile.plan == 'elite';
        final isEliteUser = userProfile.plan == 'elite';
        final isHen = currentRooster.sex == 'hembra';
        final isRooster = currentRooster.sex == 'macho';

        List<Tab> tabs = [const Tab(text: 'General')];
        List<Widget> tabViews = [
          _buildGeneralInfoTab(
              context, isEliteUser, currentRooster, activeGalleraId)
        ];

        if (isMaestroOrHigher) {
          if (isHen) {
            tabs.add(const Tab(text: 'Producción'));
            tabViews.add(_buildProductionTab(context));
          }
          tabs.add(const Tab(text: 'Cría'));
          tabViews
              .add(_buildBreedingTab(context, activeGalleraId, currentRooster));
          if (isRooster) {
            tabs.add(const Tab(text: 'Combates'));
            tabViews
                .add(_buildFightsTab(context, activeGalleraId, currentRooster));
          }
          tabs.add(const Tab(text: 'Salud'));
          tabViews
              .add(_buildHealthTab(context, activeGalleraId, currentRooster));
          if (isRooster && isEliteUser) {
            tabs.add(const Tab(text: 'Analítica'));
            tabViews.add(
                _buildAnalyticsTab(context, activeGalleraId, currentRooster));
          }
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
                        onPressed: () =>
                            _goToEditScreen(context, currentRooster))
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Text(currentRooster.name,
                        style: const TextStyle(
                            fontSize: 16.0,
                            color: Colors.white,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black)
                            ])),
                    background: Hero(
                      tag: currentRooster.id,
                      child: currentRooster.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: currentRooster.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (c, u) =>
                                  Container(color: Colors.grey[300]),
                              errorWidget: (c, u, e) =>
                                  const Icon(Icons.broken_image))
                          : Container(
                              color: Colors.grey[300],
                              child: Center(
                                  child: Icon(
                                      currentRooster.sex == 'hembra'
                                          ? Icons.female
                                          : Icons.male,
                                      size: 150,
                                      color: Colors.grey))),
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(kToolbarHeight),
                    child: Container(
                      color: Theme.of(context).appBarTheme.backgroundColor,
                      child: TabBar(
                          controller: _tabController,
                          isScrollable: tabs.length > 4,
                          tabs: tabs),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: tabViews,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGeneralInfoTab(BuildContext context, bool isEliteUser,
      RoosterModel rooster, String activeGalleraId) {
    final DateFormat formatter = DateFormat('dd de MMMM de yyyy', 'es_ES');
    final String formattedBirthDate =
        formatter.format(rooster.birthDate.toDate());
    final String fatherDisplay =
        rooster.fatherName ?? rooster.fatherLineageText ?? 'No registrado';
    final String motherDisplay =
        rooster.motherName ?? rooster.motherLineageText ?? 'No registrado';
    // --- ¡CONDICIÓN CORREGIDA! ---
    final bool canBeSold = rooster.status.toLowerCase() == 'en venta';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canBeSold)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.monetization_on_outlined),
                  label: const Text('Registrar Venta de este Ejemplar'),
                  onPressed: () =>
                      _showSaleDialog(context, activeGalleraId, rooster),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          _buildDetailRow(context,
              icon: Icons.badge,
              label: 'Placa',
              value: rooster.plate.isNotEmpty ? rooster.plate : 'N/A'),
          const Divider(),
          _buildDetailRow(context,
              icon: Icons.cake, label: 'Nacimiento', value: formattedBirthDate),
          const Divider(),
          _buildDetailRow(context,
              icon: Icons.monitor_heart,
              label: 'Estado',
              value: rooster.status),
          const Divider(),
          _buildDetailRow(context,
              icon: Icons.scale_outlined,
              label: 'Peso',
              value: rooster.weight != null
                  ? '${rooster.weight!.toStringAsFixed(2)} kg'
                  : 'No registrado'),
          const Divider(),
          _buildDetailRow(context,
              icon: Icons.location_on_outlined,
              label: 'Ubicación',
              value: rooster.areaName?.isNotEmpty == true
                  ? rooster.areaName!
                  : 'No asignada'),
          const Divider(),
          const SizedBox(height: 16),
          Text("Características",
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _buildDetailRow(context,
              icon: Icons.shield,
              label: 'Línea / Casta',
              value: rooster.breedLine ?? 'No registrada'),
          const Divider(),
          _buildDetailRow(context,
              icon: Icons.palette,
              label: 'Color',
              value: rooster.color ?? 'No registrado'),
          const Divider(),
          _buildDetailRow(context,
              icon: Icons.content_cut,
              label: 'Tipo de Cresta',
              value: rooster.combType ?? 'No registrado'),
          const Divider(),
          _buildDetailRow(context,
              icon: Icons.square_foot,
              label: 'Color de Patas',
              value: rooster.legColor ?? 'No registrado'),
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
                    onPressed: () => _goToPedigreeScreen(context, rooster)),
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

  Widget _buildProductionTab(BuildContext context) {
    return FutureBuilder<HenProductionStats>(
      future: _henStatsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(
              child: Text("Error al cargar estadísticas: ${snapshot.error}"));
        final stats = snapshot.data ?? HenProductionStats();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatCard('Total de Nidadas', stats.totalClutches.toString(),
                  Icons.egg_alt_outlined),
              _buildStatCard('Total de Huevos', stats.totalEggs.toString(),
                  Icons.egg_outlined),
              _buildStatCard('Total de Crías', stats.totalChicks.toString(),
                  Icons.cruelty_free),
              _buildStatCard(
                  'Efectividad Promedio',
                  '${stats.averageHatchRate.toStringAsFixed(1)}%',
                  Icons.show_chart),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.secondary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyLarge),
                  Text(value,
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBreedingTab(
      BuildContext context, String activeGalleraId, RoosterModel rooster) {
    return StreamBuilder<List<BreedingEventModel>>(
      stream: _breedingService.getBreedingHistoryStream(
          galleraId: activeGalleraId, roosterId: rooster.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));
        final events = snapshot.data ?? [];
        if (events.isEmpty)
          return const Center(
              child: Text('No ha participado en ninguna cruza registrada.'));
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return BreedingEventTile(
                event: event,
                currentRoosterId: rooster.id,
                onDelete: () async {/* Lógica de borrado */});
          },
        );
      },
    );
  }

  Widget _buildFightsTab(
      BuildContext context, String activeGalleraId, RoosterModel rooster) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
                icon: const Icon(Icons.add_circle),
                label: const Text("Programar Combate"),
                onPressed: () => _goToAddFightScreen(context, rooster)),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<FightModel>>(
            stream: _fightService.getFightsStream(activeGalleraId, rooster.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty)
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text("No hay eventos registrados.")));
              final fights = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: fights.length,
                itemBuilder: (context, index) {
                  final fight = fights[index];
                  return FightTile(
                      fight: fight,
                      onTap: () => _goToFightDetails(context, fight, rooster));
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHealthTab(
      BuildContext context, String activeGalleraId, RoosterModel rooster) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
                icon: const Icon(Icons.add_circle),
                label: const Text("Añadir Registro"),
                onPressed: () => _goToAddHealthLogScreen(context, rooster)),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<HealthLogModel>>(
            stream:
                _healthService.getHealthLogsStream(activeGalleraId, rooster.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty)
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text("No hay registros de salud.")));
              final logs = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return HealthLogTile(
                      log: log,
                      onTap: () =>
                          _goToHealthLogDetails(context, log, rooster));
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab(
      BuildContext context, String activeGalleraId, RoosterModel rooster) {
    return StreamBuilder<List<FightModel>>(
      stream: _fightService.getFightsStream(activeGalleraId, rooster.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const Center(
              child: Text("No hay datos para generar analíticas."));

        final analytics =
            _analyticsService.calculateFightAnalytics(snapshot.data!);
        if (analytics.totalFights == 0)
          return const Center(
              child: Text("No hay combates completados para analizar."));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            Text("Rendimiento General",
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            SizedBox(
                height: 200,
                child: PieChart(PieChartData(
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
                ))),
            const SizedBox(height: 24),
            Card(
                child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(children: [
                _buildAnalyticsRow(
                    "Total de Combates:", analytics.totalFights.toString()),
                const Divider(),
                _buildAnalyticsRow("Porcentaje de Victorias:",
                    "${analytics.winRate.toStringAsFixed(1)}%"),
              ]),
            )),
          ]),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
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
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
              child: Text(value, textAlign: TextAlign.right, softWrap: true)),
        ],
      ),
    );
  }
}
