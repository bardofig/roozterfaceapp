// lib/screens/home_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/models/user_model.dart';
import 'package:roozterfaceapp/providers/rooster_list_provider.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/screens/add_rooster_screen.dart';
import 'package:roozterfaceapp/screens/breeding_list_screen.dart';
import 'package:roozterfaceapp/screens/chat_list_screen.dart';
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
import 'package:roozterfaceapp/widgets/rooster_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final RoosterService _roosterService = RoosterService();
  final InvitationService _invitationService = InvitationService();
  final ChatService _chatService = ChatService();

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
        fullscreenDialog: true,
      ),
    );
  }

  void goToRoosterDetails(BuildContext context, RoosterModel rooster) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoosterDetailsScreen(
          rooster: rooster,
        ),
      ),
    );
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Límite Alcanzado"),
          content: const Text(
            "Has alcanzado el límite de 15 gallos para el Plan Iniciación. ¡Mejora tu plan para añadir más!",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Entendido"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
              child: const Text("Mejorar Plan"),
            ),
          ],
        );
      },
    );
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
        galleraId: activeGalleraId,
        rooster: rooster,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${rooster.name}" ha sido borrado.')),
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

  Future<bool> _confirmDelete(
      BuildContext context, RoosterModel rooster) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmar Borrado"),
          content: Text(
              "¿Estás seguro de que quieres borrar a \"${rooster.name}\"?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancelar"),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Borrar"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      return await _deleteRooster(context, rooster);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserDataProvider, RoosterListProvider>(
      builder: (context, userProvider, roosterProvider, child) {
        if (userProvider.isLoading || roosterProvider.isLoading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (userProvider.userProfile == null) {
          return const Scaffold(
              body: Center(child: Text("Cargando perfil...")));
        }

        final userProfile = userProvider.userProfile!;
        final activeGalleraId = userProfile.activeGalleraId;
        final roosters = roosterProvider.roosters;
        final isPlanIniciacion = userProfile.plan == 'iniciacion';
        final canAddRooster = !isPlanIniciacion || roosters.length < 15;

        if (activeGalleraId == null || activeGalleraId.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mis Gallos')),
            drawer: _buildDrawer(context, userProfile),
            body: _buildWelcomeMessage(),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mis Gallos'),
            actions: [
              _buildInvitationsButton(),
              _buildChatButton(),
            ],
          ),
          drawer: _buildDrawer(context, userProfile),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (canAddRooster) {
                addRooster(context);
              } else {
                _showLimitDialog();
              }
            },
            backgroundColor: canAddRooster
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            child:
                Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
          ),
          body: _buildBody(context, roosters),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, List<RoosterModel> roosters) {
    if (roosters.isEmpty) {
      return const Center(
        child: Text(
          "No tienes gallos registrados.\n¡Añade el primero!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: roosters.length,
      itemBuilder: (context, index) {
        final rooster = roosters[index];
        return Dismissible(
          key: Key(rooster.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) => _confirmDelete(context, rooster),
          child: RoosterTile(
            rooster: rooster,
            onTap: () => goToRoosterDetails(context, rooster),
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
          if (pendingInvites.isNotEmpty) {
            hasInvites = true;
          }
        }
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Mis Invitaciones',
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const InvitationsScreen()));
              },
            ),
            if (hasInvites)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildChatButton() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getChatListStream(),
      builder: (context, snapshot) {
        bool hasUnread = false;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final currentUser =
              Provider.of<UserDataProvider>(context, listen: false).userProfile;
          if (currentUser != null) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final Timestamp? lastMessageTimestamp =
                  data['lastMessageTimestamp'];
              final String lastSenderId = data['lastMessageSenderId'] ?? '';
              final Map<String, dynamic> lastReadByMap =
                  data['lastMessageReadBy'] ?? {};
              final Timestamp? myLastReadTimestamp =
                  lastReadByMap[currentUser.uid];

              if (lastSenderId != currentUser.uid &&
                  lastMessageTimestamp != null) {
                if (myLastReadTimestamp == null ||
                    lastMessageTimestamp.compareTo(myLastReadTimestamp) > 0) {
                  hasUnread = true;
                  break;
                }
              }
            }
          }
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: 'Mis Conversaciones',
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ChatListScreen()));
              },
            ),
            if (hasUnread)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Bienvenido a tu Gallera Digital.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Parece que no tienes una gallera activa o no perteneces a ninguna.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.swap_horiz),
              label: const Text("Seleccionar o Crear Gallera"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GalleraSwitcherScreen(),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, UserModel userProfile) {
    final bool isMaestroOrHigher =
        userProfile.plan == 'maestro' || userProfile.plan == 'elite';
    final bool isEliteUser = userProfile.plan == 'elite';
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 220,
            child: DrawerHeader(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Transform.flip(
                        flipX: true,
                        child: Image.asset(
                          'assets/images/gallosinfondo.png',
                          fit: BoxFit.cover,
                          color: Colors.black.withOpacity(0.5),
                          colorBlendMode: BlendMode.darken,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12.0,
                      left: 12.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userProfile.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(blurRadius: 3, color: Colors.black)
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userProfile.email,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              shadows: [
                                Shadow(blurRadius: 2, color: Colors.black)
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Cambiar Gallera'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GalleraSwitcherScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('Mi Perfil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.shopping_basket_outlined),
            title: const Text('Mercado de Ejemplares'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MarketplaceScreen(),
                ),
              );
            },
          ),
          const Divider(),
          if (isMaestroOrHigher)
            ListTile(
              leading: const Icon(Icons.auto_stories),
              title: const Text('Libro de Cría'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BreedingListScreen(),
                  ),
                );
              },
            ),
          if (isMaestroOrHigher)
            ListTile(
              leading: const Icon(Icons.monetization_on_outlined),
              title: const Text('Registro de Ventas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SalesHistoryScreen(),
                  ),
                );
              },
            ),
          if (isEliteUser)
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Mi Escaparate Público'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PublicShowcaseScreen(),
                  ),
                );
              },
            ),
          if (isEliteUser)
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Gestionar Gallera'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GalleraManagementScreen(),
                  ),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('Planes y Suscripción'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Provider.of<ThemeProvider>(context).isDarkMode
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
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
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red.shade400),
            title: Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red.shade400),
            ),
            onTap: () {
              Navigator.pop(context);
              signOut();
            },
          ),
        ],
      ),
    );
  }
}
