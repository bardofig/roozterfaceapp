// lib/screens/home_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/models/user_model.dart';
import 'package:roozterfaceapp/providers/rooster_list_provider.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/screens/add_rooster_screen.dart';
import 'package:roozterfaceapp/screens/area_management_screen.dart';
import 'package:roozterfaceapp/screens/breeding_list_screen.dart';
import 'package:roozterfaceapp/screens/chat_list_screen.dart';
import 'package:roozterfaceapp/screens/expenses_screen.dart';
import 'package:roozterfaceapp/screens/financial_dashboard_screen.dart';
import 'package:roozterfaceapp/screens/gallera_management_screen.dart';
import 'package:roozterfaceapp/screens/gallera_switcher_screen.dart';
import 'package:roozterfaceapp/screens/invitations_screen.dart';
import 'package:roozterfaceapp/screens/marketplace_screen.dart';
import 'package:roozterfaceapp/screens/profile_screen.dart';
import 'package:roozterfaceapp/screens/public_showcase_screen.dart';
import 'package:roozterfaceapp/screens/qr_scanner_screen.dart';
import 'package:roozterfaceapp/screens/rooster_details_screen.dart';
import 'package:roozterfaceapp/screens/subscription_screen.dart';
import 'package:roozterfaceapp/screens/create_partido_screen.dart';
import 'package:roozterfaceapp/screens/partido_management_screen.dart';
import 'package:roozterfaceapp/screens/partido_leaderboard_screen.dart'; // ✅ NUEVO
import 'package:roozterfaceapp/screens/help_center_screen.dart'; // ✅ NUEVO
import 'package:roozterfaceapp/screens/sales_history_screen.dart'; // ✅ RESTAURADO
import 'package:roozterfaceapp/screens/tournament_list_screen.dart'; // ✅ NUEVO
import 'package:roozterfaceapp/services/auth_service.dart';
import 'package:roozterfaceapp/services/partido_service.dart';
import 'package:roozterfaceapp/models/partido_model.dart';
import 'package:roozterfaceapp/services/chat_service.dart';
import 'package:roozterfaceapp/services/chat_service.dart';
import 'package:roozterfaceapp/services/invitation_service.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';
import 'package:roozterfaceapp/theme/theme_provider.dart';
import 'package:roozterfaceapp/widgets/rooster_list_view.dart';
import 'package:roozterfaceapp/widgets/dashboard_summary.dart';
import 'package:roozterfaceapp/services/pdf_service.dart';
import 'package:roozterfaceapp/providers/gallera_data_provider.dart';
import 'package:roozterfaceapp/widgets/main_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final RoosterService _roosterService = RoosterService();
  final InvitationService _invitationService = InvitationService();
  final ChatService _chatService = ChatService();
  final PdfService _pdfService = PdfService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void signOut() {
    _authService.signOut();
  }

  void addRooster(BuildContext context) {
    final userProvider = Provider.of<UserDataProvider>(context, listen: false);
    final userProfile = userProvider.userProfile;
    if (userProfile == null || userProfile.activeGalleraId == null) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AddRoosterScreen(
                  currentUserPlan: userProfile.plan,
                  activeGalleraId: userProfile.activeGalleraId!,
                ),
            fullscreenDialog: true));
  }

  void goToRoosterDetails(BuildContext context, RoosterModel rooster) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => RoosterDetailsScreen(rooster: rooster)));
  }



  Future<bool> _deleteRooster(
      BuildContext context, RoosterModel rooster) async {
    final activeGalleraId =
        Provider.of<UserDataProvider>(context, listen: false)
            .userProfile
            ?.activeGalleraId;
    if (activeGalleraId == null) return false;
    try {
      await _roosterService.deleteRooster(
          galleraId: activeGalleraId, rooster: rooster);
      
      if (mounted) {
        // Actualizar la lista localmente
        Provider.of<RoosterListProvider>(context, listen: false)
            .removeRoosterLocally(rooster.id!);

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${rooster.name}" ha sido borrado.')));
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al borrar: ${e.toString()}')));
      }
      return false;
    }
  }

  Future<bool> _confirmDelete(
      BuildContext context, RoosterModel rooster) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: const Text("Confirmar Borrado"),
              content: Text(
                  "¿Estás seguro de que quieres borrar a \"${rooster.name}\"?"),
              actions: <Widget>[
                TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("Cancelar")),
                TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("Borrar")),
              ],
            ));
    return (confirm == true) ? await _deleteRooster(context, rooster) : false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<UserDataProvider, RoosterListProvider, GalleraDataProvider>(
      builder: (context, userProvider, roosterProvider, galleraProvider, child) {
        final userProfile = userProvider.userProfile!;
        final activeGalleraId = userProfile.activeGalleraId;
        final String galleraName = galleraProvider.galleraData?['name'] ?? 'Mi Gallera';

        if (activeGalleraId == null || activeGalleraId.isEmpty) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            drawer: const MainDrawer(),
            appBar: AppBar(
                title: const Text('Mi Gallera'),
                backgroundColor: Colors.transparent,
                actions: [
                  IconButton(icon: const Icon(Icons.help_outline), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen()))),
                  _buildInvitationsButton(), 
                  _buildChatButton()
                ]),
            body: _buildWelcomeMessage(),
          );
        }

        final allRoosters = roosterProvider.roosters;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          drawer: const MainDrawer(),
          appBar: AppBar(
            title: Text(galleraName),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(icon: const Icon(Icons.help_outline), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen()))),
              _buildPdfExportButton(allRoosters, galleraName),
              _buildInvitationsButton(),
              _buildChatButton()
            ],
            bottom: roosterProvider.isLoading
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(4.0),
                    child: LinearProgressIndicator(color: Colors.amber),
                  )
                : TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.amber,
                    labelColor: Colors.amber,
                    unselectedLabelColor: Colors.white38,
                    tabs: [
                      Tab(text: 'Todos (${allRoosters.length})'),
                      Tab(
                          text:
                              'Gallos (${allRoosters.where((r) => r.sex == 'macho').length})'),
                      Tab(
                          text:
                              'Gallinas (${allRoosters.where((r) => r.sex == 'hembra').length})'),
                    ],
                  ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => addRooster(context), // ✅ Sin validación de límite
            backgroundColor: Theme.of(context).colorScheme.primary,
            child:
                Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
          ),
          body: roosterProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    DashboardSummary(roosters: allRoosters),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          RoosterListView(
                            roosters: allRoosters,
                            onDelete: (r) => _confirmDelete(context, r),
                            onTap: (r) => goToRoosterDetails(context, r),
                            onLoadMore: roosterProvider.loadMore,
                            isLoadingMore: roosterProvider.isLoadingMore,
                          ),
                          RoosterListView(
                            roosters: allRoosters
                                .where((r) => r.sex == 'macho')
                                .toList(),
                            onDelete: (r) => _confirmDelete(context, r),
                            onTap: (r) => goToRoosterDetails(context, r),
                            onLoadMore: roosterProvider.loadMore,
                            isLoadingMore: roosterProvider.isLoadingMore,
                          ),
                          RoosterListView(
                            roosters: allRoosters
                                .where((r) => r.sex == 'hembra')
                                .toList(),
                            onDelete: (r) => _confirmDelete(context, r),
                            onTap: (r) => goToRoosterDetails(context, r),
                            onLoadMore: roosterProvider.loadMore,
                            isLoadingMore: roosterProvider.isLoadingMore,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildInvitationsButton() {
    return StreamBuilder<DocumentSnapshot?>(
        stream: _invitationService.getInvitationsStream(),
        builder: (context, snapshot) {
          bool hasInvites = false;
          if (snapshot.hasData &&
              snapshot.data != null &&
              snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final Map<String, dynamic> pendingInvites =
                data['pending_invitations'] ?? {};
            if (pendingInvites.isNotEmpty) hasInvites = true;
          }
          return Stack(alignment: Alignment.center, children: [
            IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Mis Invitaciones',
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const InvitationsScreen()))),
            if (hasInvites)
              Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle))),
          ]);
        });
  }

  Widget _buildChatButton() {
    return StreamBuilder<QuerySnapshot>(
        stream: _chatService.getChatListStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const IconButton(
              icon: Icon(Icons.cloud_off, color: Colors.yellow),
              tooltip: 'Error al cargar chats',
              onPressed: null,
            );
          }

          bool hasUnread = false;
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            final currentUser =
                Provider.of<UserDataProvider>(context, listen: false)
                    .userProfile;
            if (currentUser != null) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['lastMessageSenderId'] != currentUser.uid) {
                  final lastMessageTimestamp =
                      data['lastMessageTimestamp'] as Timestamp?;
                  final myLastReadTimestamp = (data['lastMessageReadBy'] ??
                      {})[currentUser.uid] as Timestamp?;
                  if (lastMessageTimestamp != null &&
                      (myLastReadTimestamp == null ||
                          lastMessageTimestamp.compareTo(myLastReadTimestamp) >
                              0)) {
                    hasUnread = true;
                    break;
                  }
                }
              }
            }
          }
          return Stack(alignment: Alignment.center, children: [
            IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                tooltip: 'Mis Conversaciones',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ChatListScreen()))),
            if (hasUnread)
              Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle))),
          ]);
        });
  }

  Widget _buildWelcomeMessage() {
    return Center(
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text("Bienvenido a tu Gallera Digital.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Parece que no tienes una gallera activa.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text("Seleccionar Gallera"),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const GalleraSwitcherScreen()))),
            ])));
  }


  Widget _buildPdfExportButton(List<RoosterModel> roosters, String galleraName) {
    return IconButton(
      icon: const Icon(Icons.picture_as_pdf_outlined),
      tooltip: 'Exportar PDF',
      onPressed: roosters.isEmpty
          ? null
          : () async {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generando PDF...')));
                await _pdfService.generateInventoryPdf(
                  roosters: roosters,
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
}
