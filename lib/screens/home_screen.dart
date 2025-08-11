// lib/screens/home_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/models/user_model.dart';
import 'package:roozterfaceapp/screens/add_rooster_screen.dart';
import 'package:roozterfaceapp/screens/gallera_management_screen.dart';
import 'package:roozterfaceapp/screens/gallera_switcher_screen.dart';
import 'package:roozterfaceapp/screens/profile_screen.dart';
import 'package:roozterfaceapp/screens/rooster_details_screen.dart';
import 'package:roozterfaceapp/screens/subscription_screen.dart';
import 'package:roozterfaceapp/services/auth_service.dart';
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

  void signOut() {
    _authService.signOut();
  }

  void addRooster(String currentUserPlan, String activeGalleraId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRoosterScreen(
          currentUserPlan: currentUserPlan,
          activeGalleraId: activeGalleraId,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void goToRoosterDetails(RoosterModel rooster, String activeGalleraId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoosterDetailsScreen(
          rooster: rooster,
          activeGalleraId: activeGalleraId,
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
    RoosterModel rooster,
    String activeGalleraId,
  ) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot?>(
        stream: _roosterService.getUserProfileStream(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (!userSnapshot.hasData ||
              userSnapshot.data == null ||
              !userSnapshot.data!.exists) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final userProfile = UserModel.fromFirestore(userSnapshot.data!);
          final String? activeGalleraId = userProfile.activeGalleraId;
          final isPlanIniciacion = userProfile.plan == 'iniciacion';
          final bool isEliteUser = userProfile.plan == 'elite';

          return Scaffold(
            appBar: AppBar(title: const Text('Mis Gallos')),
            drawer: _buildDrawer(userProfile, isEliteUser),
            // El FAB ahora está aquí, fuera del StreamBuilder de gallos
            floatingActionButton: activeGalleraId != null
                ? StreamBuilder<List<RoosterModel>>(
                    stream: _roosterService.getRoostersStream(activeGalleraId),
                    builder: (context, roosterSnapshot) {
                      final roosterCount = roosterSnapshot.data?.length ?? 0;
                      final canAddRooster =
                          !isPlanIniciacion || roosterCount < 15;
                      return FloatingActionButton(
                        onPressed: () {
                          if (canAddRooster) {
                            addRooster(userProfile.plan, activeGalleraId);
                          } else {
                            _showLimitDialog();
                          }
                        },
                        backgroundColor: canAddRooster
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        child: Icon(
                          Icons.add,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      );
                    },
                  )
                : null,
            body: activeGalleraId == null || activeGalleraId.isEmpty
                ? const Center(child: Text("No tienes una gallera asignada."))
                : StreamBuilder<List<RoosterModel>>(
                    stream: _roosterService.getRoostersStream(activeGalleraId),
                    builder: (context, roosterSnapshot) {
                      if (roosterSnapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error al cargar gallos: ${roosterSnapshot.error}",
                          ),
                        );
                      }
                      if (!roosterSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final roosters = roosterSnapshot.data!;

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
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              bool? confirm = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Confirmar Borrado"),
                                    content: Text(
                                      "¿Estás seguro de que quieres borrar a \"${rooster.name}\"?",
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text("Cancelar"),
                                      ),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text("Borrar"),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (confirm != true) return false;
                              return await _deleteRooster(
                                rooster,
                                activeGalleraId,
                              );
                            },
                            child: RoosterTile(
                              name: rooster.name,
                              plate: rooster.plate,
                              status: rooster.status,
                              imageUrl: rooster.imageUrl,
                              onTap: () =>
                                  goToRoosterDetails(rooster, activeGalleraId),
                            ),
                          );
                        },
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(UserModel userProfile, bool isEliteUser) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 220,
            child: DrawerHeader(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
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
                                Shadow(blurRadius: 3, color: Colors.black),
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
                                Shadow(blurRadius: 2, color: Colors.black),
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
          if (isEliteUser)
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Gestionar Gallera'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GalleraManagementScreen(),
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
              value: Provider.of<ThemeProvider>(
                context,
                listen: false,
              ).isDarkMode,
              onChanged: (value) {
                Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                ).toggleTheme();
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
