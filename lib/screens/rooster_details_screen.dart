// lib/screens/rooster_details_screen.dart

import 'package:roozterfaceapp/widgets/optimized_cached_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart'; // ✅ AGREGADO
import 'package:roozterfaceapp/models/breeding_event_model.dart';
import 'package:roozterfaceapp/models/fight_model.dart';
import 'package:roozterfaceapp/models/health_log_model.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/providers/gallera_data_provider.dart';
import 'package:roozterfaceapp/screens/add_fight_screen.dart';
import 'package:roozterfaceapp/screens/add_health_log_screen.dart';
import 'package:roozterfaceapp/screens/add_rooster_screen.dart';
import 'package:roozterfaceapp/screens/fight_details_screen.dart';
import 'package:roozterfaceapp/screens/health_log_details_screen.dart';
import 'package:roozterfaceapp/screens/pedigree_screen.dart';
import 'package:roozterfaceapp/services/analytics_service.dart';
import 'package:roozterfaceapp/services/breeding_service.dart';
import 'package:roozterfaceapp/services/pdf_service.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';
import 'package:roozterfaceapp/services/fight_service.dart';
import 'package:roozterfaceapp/services/health_service.dart';
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
  final PdfService _pdfService = PdfService();

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

    // ✅ Bloqueos de suscripción removidos - tabs disponibles para todos
    final currentRoosterSex = forRooster.sex;
    int tabCount = 1; // General
    if (currentRoosterSex == 'hembra') tabCount++; // Producción
    tabCount++; // Cría
    if (currentRoosterSex == 'macho') tabCount++; // Combates
    tabCount++; // Salud
    tabCount++; // Peso (Nuevo)
    if (currentRoosterSex == 'macho') tabCount++; // Analítica

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

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: OptimizedCachedImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
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
                          if (v == null || v.isEmpty) {
                            return 'El precio es obligatorio';
                          }
                          if (double.tryParse(v) == null ||
                              double.parse(v) <= 0) {
                            return 'Ingrese un precio válido';
                          }
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
                      // ✅ PASO DE CONFIRMACIÓN ADICIONAL
                      final confirmAction = await showDialog<bool>(
                        context: context,
                        builder: (confirmCtx) => AlertDialog(
                          title: const Text('Confirmar Registro'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Estás por marcar este ejemplar como VENDIDO.'),
                              const SizedBox(height: 12),
                              Text('Monto: \$${double.parse(priceController.text).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Comprador: ${buyerController.text.trim()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              const Text('Esta acción registrará un ingreso en las finanzas y no se puede deshacer fácilmente.', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(confirmCtx, false), child: const Text('Corregir')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(confirmCtx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text('¡Confirmar Venta!'),
                            ),
                          ],
                        ),
                      );

                      if (confirmAction == true) {
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
                          
                          // Notificación de éxito
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text("✅ Venta registrada exitosamente."),
                              backgroundColor: Colors.green,
                            ));
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    "Error al registrar venta: ${e.toString()}"),
                                backgroundColor: Colors.red));
                          }
                        }
                      }
                    }
                  },
                  child: const Text('Siguiente'),
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

        // ✅ Bloqueos de suscripción removidos - tabs disponibles para todos
        final isHen = currentRooster.sex == 'hembra';
        final isRooster = currentRooster.sex == 'macho';

        List<Tab> tabs = [const Tab(text: 'General')];
        List<Widget> tabViews = [
          _buildGeneralInfoTab(
              context, true, currentRooster, activeGalleraId) // isEliteUser = true
        ];

        if (isHen) {
          tabs.add(const Tab(text: 'Producción'));
          tabViews.add(_buildProductionTab(context));
        }
        
        tabs.add(const Tab(text: 'Cría'));
        tabViews.add(_buildBreedingTab(context, activeGalleraId, currentRooster));
        
        if (isRooster) {
          tabs.add(const Tab(text: 'Combates'));
          tabViews.add(_buildFightsTab(context, activeGalleraId, currentRooster));
        }
        
        tabs.add(const Tab(text: 'Salud'));
        tabViews.add(_buildHealthTab(context, activeGalleraId, currentRooster));
        
        tabs.add(const Tab(text: 'Peso'));
        tabViews.add(_buildWeightTab(context, activeGalleraId, currentRooster));
        
        if (isRooster) {
          tabs.add(const Tab(text: 'Analítica'));
          tabViews.add(
              _buildAnalyticsTab(context, activeGalleraId, currentRooster));
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
                    Consumer<GalleraDataProvider>(
                      builder: (context, galleraProvider, _) {
                        final String galleraName = galleraProvider.galleraData?['name'] ?? 'Mi Gallera';
                        return _buildPdfDetailButton(currentRooster, galleraName);
                      }
                    ),
                    IconButton(
                      icon: const Icon(Icons.qr_code_2),
                      tooltip: 'Generar QR',
                      onPressed: () {
                        _showQrCode(context, currentRooster, activeGalleraId);
                      },
                    ),
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
                          ? Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                                child: OptimizedCachedImage(
                                  imageUrl: currentRooster.imageUrl,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            )
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
          _buildPhotoGallery(context, rooster),
          const SizedBox(height: 16),
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
              TextButton.icon( // ✅ Disponible para todos
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text("Error al cargar estadísticas: ${snapshot.error}"));
        }
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
    return FutureBuilder<List<BreedingEventModel>>(
      future: _breedingService.getBreedingHistory(
          galleraId: activeGalleraId, roosterId: rooster.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error al cargar historial: ${snapshot.error}'),
                TextButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.egg_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No hay registros de cría para este ejemplar',
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return BreedingEventTile(
                event: event,
                currentRoosterId: rooster.id,
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Borrar Registro'),
                      content: const Text(
                          '¿Estás seguro de que deseas eliminar este registro de cría?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Borrar'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await _breedingService.deleteBreedingEvent(
                      galleraId: activeGalleraId,
                      eventId: event.id,
                    );
                    setState(() {}); // Recargamos el FutureBuilder
                  }
                });
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text("No hay eventos registrados.")));
              }
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text("No hay registros de salud.")));
              }
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text("No hay datos para generar analíticas."));
        }

        final analytics =
            _analyticsService.calculateFightAnalytics(snapshot.data!);
        if (analytics.totalFights == 0) {
          return const Center(
              child: Text("No hay combates completados para analizar."));
        }

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

  Widget _buildPhotoGallery(BuildContext context, RoosterModel rooster) {
    final allPhotos = [
      if (rooster.imageUrl.isNotEmpty) rooster.imageUrl,
      ...(rooster.additionalPhotos ?? []),
    ];

    if (allPhotos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Galería de Fotos", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allPhotos.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showFullScreenImage(context, allPhotos[index]),
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: OptimizedCachedImage(
                      imageUrl: allPhotos[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPdfDetailButton(RoosterModel rooster, String galleraName) {
    return IconButton(
      icon: const Icon(Icons.picture_as_pdf_outlined),
      tooltip: 'Exportar Ficha PDF',
      onPressed: () async {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Generando Ficha PDF...')));
          await _pdfService.generateRoosterDetailPdf(
            rooster: rooster,
            galleraName: galleraName,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Error al generar PDF: ${e.toString()}'),
                backgroundColor: Colors.red));
          }
        }
      },
    );
  }

  void _showQrCode(
      BuildContext context, RoosterModel rooster, String? galleraId) {
    if (galleraId == null || galleraId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Error: No se pudo identificar la gallera para generar el QR."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Identificación QR: ${rooster.name}',
            textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(
                  data: '${galleraId}|${rooster.id}',
                  version: QrVersions.auto,
                  size: 200.0,
                  gapless: false,
                  errorStateBuilder: (cxt, err) {
                    return const Center(
                      child: Text(
                        "Error al generar QR",
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Placa: ${rooster.plate.isNotEmpty ? rooster.plate : 'S/P'}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Escanea este código para ver el perfil del gallo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightTab(
      BuildContext context, String galleraId, RoosterModel rooster) {
    final history = rooster.weightHistory ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPhysicalSummary(rooster),
          const SizedBox(height: 24),
          _buildSectionHeader(
            title: 'Evolución de Peso',
            icon: Icons.monitor_weight_outlined,
            action: ElevatedButton.icon(
              onPressed: () => _showAddWeightDialog(context, galleraId, rooster),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Registrar'),
            ),
          ),
          const SizedBox(height: 20),
          if (history.length < 2)
            _buildEmptyWeightsState()
          else
            _buildWeightChart(history),
          const SizedBox(height: 30),
          const Text(
            'Historial',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (history.isEmpty)
            const Center(child: Text('No hay registros de peso todavía.'))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final reversedList = history.reversed.toList();
                final record = reversedList[index];
                final date = record['date'] is Timestamp 
                    ? (record['date'] as Timestamp).toDate()
                    : DateTime.now();
                final weight = (record['weight'] as num).toDouble();
                final notes = record['notes'] as String? ?? '';

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.history, color: Colors.white, size: 20),
                    ),
                    title: Text('${weight.toStringAsFixed(2)} kg'),
                    subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(date)),
                    trailing: notes.isNotEmpty
                        ? const Icon(Icons.note_alt_outlined, size: 18)
                        : null,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPhysicalSummary(RoosterModel rooster) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Peso Actual', '${rooster.weight?.toStringAsFixed(2) ?? 'N/A'} kg', Icons.scale),
          _buildSummaryItem('Último Registro', rooster.weightHistory?.isNotEmpty == true 
              ? DateFormat('dd MMM').format((rooster.weightHistory!.last['date'] as Timestamp).toDate())
              : 'N/A', Icons.calendar_today),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildEmptyWeightsState() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 50, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            'Se necesitan al menos 2 registros\npara visualizar la gráfica.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChart(List<Map<String, dynamic>> history) {
    final sortedHistory = List<Map<String, dynamic>>.from(history);
    sortedHistory.sort((a, b) => (a['date'] as Timestamp).compareTo(b['date'] as Timestamp));

    List<FlSpot> spots = [];
    for (int i = 0; i < sortedHistory.length; i++) {
      spots.add(FlSpot(i.toDouble(), (sortedHistory[i]['weight'] as num).toDouble()));
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: 20, top: 10, bottom: 0),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < sortedHistory.length) {
                    final date = (sortedHistory[value.toInt()]['date'] as Timestamp).toDate();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(DateFormat('dd/MM').format(date), style: const TextStyle(fontSize: 10)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.2))),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blueAccent,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blueAccent.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWeightDialog(BuildContext context, String galleraId, RoosterModel rooster) {
    final weightController = TextEditingController(text: rooster.weight?.toString() ?? '');
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Pesaje'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: 'Peso actual (kg)',
                  prefixIcon: Icon(Icons.monitor_weight),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || double.tryParse(v) == null) ? 'Ingrese un peso válido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas (Opcional)',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _roosterService.addWeightRecord(
                    galleraId: galleraId,
                    roosterId: rooster.id,
                    newWeight: double.parse(weightController.text),
                    notes: notesController.text.trim(),
                  );
                  if (mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      {required String title, required IconData icon, Widget? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (action != null) action,
      ],
    );
  }
}
