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
import 'package:roozterfaceapp/screens/rooster_details_screen.dart';
import 'package:roozterfaceapp/screens/sales_history_screen.dart';
import 'package:roozterfaceapp/screens/subscription_screen.dart';
import 'package:roozterfaceapp/services/auth_service.dart';
import 'package:roozterfaceapp/services/chat_service.dart';
import 'package:roozterfaceapp/services/invitation_service.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';
import 'package:roozterfaceapp/theme/theme_provider.dart';
import 'package:roozterfaceapp/widgets/rooster_list_view.dart';

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

  // --- El resto de los métodos de ayuda permanecen idénticos ---
  // (signOut, addRooster, goToRoosterDetails, _showLimitDialog, etc.)

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

  void _showLimitDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Límite Alcanzado"),
              content: const Text(
                  "Has alcanzado el límite de 15 gallos. ¡Mejora tu plan para añadir más!"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Entendido")),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const SubscriptionScreen()));
                    },
                    child: const Text("Mejorar Plan")),
              ],
            ));
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
    return Consumer2<UserDataProvider, RoosterListProvider>(
      builder: (context, userProvider, roosterProvider, child) {
        final userProfile = userProvider.userProfile!;
        final activeGalleraId = userProfile.activeGalleraId;

        if (activeGalleraId != roosterProvider.currentGalleraId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context
                  .read<RoosterListProvider>()
                  .fetchRoosters(activeGalleraId);
            }
          });
        }

        // Caso: El usuario no tiene gallera activa. Este sí necesita su propio Scaffold.
        if (activeGalleraId == null || activeGalleraId.isEmpty) {
          return Scaffold(
            appBar: AppBar(
                title: const Text('Mis Ejemplares'),
                actions: [_buildInvitationsButton(), _buildChatButton()]),
            drawer: _buildDrawer(context, userProfile),
            body: _buildWelcomeMessage(),
          );
        }

        final allRoosters = roosterProvider.roosters;
        final isPlanIniciacion = userProfile.plan == 'iniciacion';
        final canAddRooster = !isPlanIniciacion || allRoosters.length < 15;

        // --- ARQUITECTURA DEL CAPARAZÓN ÚNICO ---
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mis Ejemplares'),
            actions: [_buildInvitationsButton(), _buildChatButton()],
            // El TabBar se construye aquí incondicionalmente, solo mostrará
            // los números correctos cuando los datos estén listos.
            bottom: roosterProvider.isLoading
                ? null
                : TabBar(
                    controller: _tabController,
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
          drawer: _buildDrawer(context, userProfile),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (canAddRooster)
                addRooster(context);
              else
                _showLimitDialog();
            },
            backgroundColor: canAddRooster
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            child:
                Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
          ),
          // --- El CONTENIDO del body es lo ÚNICO que cambia ---
          body: roosterProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    RoosterListView(
                        roosters: allRoosters,
                        onDelete: (r) => _confirmDelete(context, r),
                        onTap: (r) => goToRoosterDetails(context, r)),
                    RoosterListView(
                        roosters:
                            allRoosters.where((r) => r.sex == 'macho').toList(),
                        onDelete: (r) => _confirmDelete(context, r),
                        onTap: (r) => goToRoosterDetails(context, r)),
                    RoosterListView(
                        roosters: allRoosters
                            .where((r) => r.sex == 'hembra')
                            .toList(),
                        onDelete: (r) => _confirmDelete(context, r),
                        onTap: (r) => goToRoosterDetails(context, r)),
                  ],
                ),
        );
      },
    );
  }

  // --- El resto de los métodos de construcción de la UI (_buildDrawer, etc.) permanecen idénticos ---

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
                      decoration: BoxDecoration(
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
                      decoration: BoxDecoration(
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

  Widget _buildDrawer(BuildContext context, UserModel userProfile) {
    final bool isMaestroOrHigher =
        userProfile.plan == 'maestro' || userProfile.plan == 'elite';
    final bool isEliteUser = userProfile.plan == 'elite';
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context, userProfile),
          _buildDrawerSectionHeader(context, 'Mercado'),
          _buildDrawerItem(context,
              icon: Icons.shopping_basket_outlined,
              title: 'Mercado de Ejemplares',
              onTap: () => _navigateTo(context, const MarketplaceScreen())),
          if (isEliteUser)
            _buildDrawerItem(context,
                icon: Icons.storefront_outlined,
                title: 'Mi Escaparate Público',
                onTap: () =>
                    _navigateTo(context, const PublicShowcaseScreen())),
          _buildDrawerSectionHeader(context, 'Mi Gallera'),
          _buildDrawerItem(context,
              icon: Icons.swap_horiz,
              title: 'Cambiar Gallera',
              onTap: () => _navigateTo(context, const GalleraSwitcherScreen())),
          if (isEliteUser)
            _buildDrawerItem(context,
                icon: Icons.groups_outlined,
                title: 'Gestionar Miembros',
                onTap: () =>
                    _navigateTo(context, const GalleraManagementScreen())),
          if (isEliteUser)
            _buildDrawerItem(context,
                icon: Icons.map_outlined,
                title: 'Gestionar Áreas',
                onTap: () =>
                    _navigateTo(context, const AreaManagementScreen())),
          if (isMaestroOrHigher)
            _buildDrawerItem(context,
                icon: Icons.auto_stories,
                title: 'Libro de Cría',
                onTap: () => _navigateTo(context, const BreedingListScreen())),
          if (isMaestroOrHigher) ...[
            _buildDrawerSectionHeader(context, 'Registros y Finanzas'),
            _buildDrawerItem(context,
                icon: Icons.analytics_outlined,
                title: 'Panel Financiero',
                onTap: () =>
                    _navigateTo(context, const FinancialDashboardScreen())),
            _buildDrawerItem(context,
                icon: Icons.monetization_on_outlined,
                title: 'Registro de Ventas',
                onTap: () => _navigateTo(context, const SalesHistoryScreen())),
            _buildDrawerItem(context,
                icon: Icons.request_quote_outlined,
                title: 'Registro de Gastos',
                onTap: () => _navigateTo(context, const ExpensesScreen())),
          ],
          _buildDrawerSectionHeader(context, 'Cuenta'),
          _buildDrawerItem(context,
              icon: Icons.account_circle_outlined,
              title: 'Mi Perfil',
              onTap: () => _navigateTo(context, const ProfileScreen())),
          _buildDrawerItem(context,
              icon: Icons.workspace_premium_outlined,
              title: 'Planes y Suscripción',
              onTap: () => _navigateTo(context, const SubscriptionScreen())),
          const Divider(height: 24, thickness: 0.5),
          ListTile(
            leading: Icon(Provider.of<ThemeProvider>(context).isDarkMode
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined),
            title: const Text('Tema Oscuro'),
            trailing: Switch(
              value:
                  Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
              onChanged: (value) {
                Provider.of<ThemeProvider>(context, listen: false)
                    .toggleTheme();
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red.shade400),
            title: Text('Cerrar Sesión',
                style: TextStyle(color: Colors.red.shade400)),
            onTap: () {
              Navigator.pop(context);
              signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, UserModel userProfile) {
    return SizedBox(
      height: 220,
      child: DrawerHeader(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Stack(
            children: [
              Positioned.fill(
                  child: Transform.flip(
                      flipX: true,
                      child: Image.asset('assets/images/gallosinfondo.png',
                          fit: BoxFit.cover,
                          color: Colors.black.withOpacity(0.5),
                          colorBlendMode: BlendMode.darken))),
              Positioned(
                bottom: 12.0,
                left: 12.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userProfile.fullName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 3, color: Colors.black)
                            ])),
                    const SizedBox(height: 4),
                    Text(userProfile.email,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            shadows: [
                              Shadow(blurRadius: 2, color: Colors.black)
                            ])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      margin: const EdgeInsets.only(top: 12.0),
      decoration:
          BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.05)),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}
