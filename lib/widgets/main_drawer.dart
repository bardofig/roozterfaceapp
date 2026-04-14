// lib/widgets/main_drawer.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/models/partido_model.dart';
import 'package:roozterfaceapp/models/user_model.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/screens/area_management_screen.dart';
import 'package:roozterfaceapp/screens/breeding_list_screen.dart';
import 'package:roozterfaceapp/screens/create_partido_screen.dart';
import 'package:roozterfaceapp/screens/expenses_screen.dart';
import 'package:roozterfaceapp/screens/financial_dashboard_screen.dart';
import 'package:roozterfaceapp/screens/gallera_management_screen.dart';
import 'package:roozterfaceapp/screens/gallera_switcher_screen.dart';
import 'package:roozterfaceapp/screens/help_center_screen.dart';
import 'package:roozterfaceapp/screens/marketplace_screen.dart';
import 'package:roozterfaceapp/screens/partido_leaderboard_screen.dart';
import 'package:roozterfaceapp/screens/partido_management_screen.dart';
import 'package:roozterfaceapp/screens/profile_screen.dart';
import 'package:roozterfaceapp/screens/public_showcase_screen.dart';
import 'package:roozterfaceapp/screens/sales_history_screen.dart';
import 'package:roozterfaceapp/screens/subscription_screen.dart';
import 'package:roozterfaceapp/screens/tournament_list_screen.dart';
import 'package:roozterfaceapp/services/auth_service.dart';
import 'package:roozterfaceapp/services/partido_service.dart';
import 'package:roozterfaceapp/theme/theme_provider.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  void _signOut(BuildContext context) {
    AuthService().signOut();
    Navigator.pop(context);
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<UserDataProvider>(context).userProfile;
    if (userProfile == null) return const Drawer();

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context, userProfile),
          _buildDrawerSectionHeader(context, 'Mercado'),
          _buildDrawerItem(context,
              icon: Icons.shopping_basket_outlined,
              title: 'Mercado de Ejemplares',
              onTap: () => _navigateTo(context, const MarketplaceScreen())),
          _buildDrawerItem(context,
              icon: Icons.storefront_outlined,
              title: 'Mi Escaparate Público',
              onTap: () => _navigateTo(context, const PublicShowcaseScreen())),
          _buildDrawerSectionHeader(context, 'Mi Gallera'),
          _buildDrawerItem(context,
              icon: Icons.swap_horiz,
              title: 'Cambiar Gallera',
              onTap: () => _navigateTo(context, const GalleraSwitcherScreen())),
          _buildDrawerItem(context,
              icon: Icons.groups_outlined,
              title: 'Gestionar Miembros',
              onTap: () => _navigateTo(context, const GalleraManagementScreen())),
          _buildDrawerItem(context,
              icon: Icons.map_outlined,
              title: 'Gestionar Áreas',
              onTap: () => _navigateTo(context, const AreaManagementScreen())),
          _buildDrawerItem(context,
              icon: Icons.auto_stories,
              title: 'Libro de Cría',
              onTap: () => _navigateTo(context, const BreedingListScreen())),
          _buildDrawerItem(context,
              icon: Icons.emoji_events_outlined,
              title: 'Ranking de Partidos',
              onTap: () => _navigateTo(context, const PartidoLeaderboardScreen())),
          _buildDrawerItem(context,
              icon: Icons.shield_outlined,
              title: userProfile.activePartidoId == null ? 'Registrar mi Partido' : 'Mi Partido / Equipo',
              onTap: () {
                if (userProfile.activePartidoId == null) {
                  _navigateTo(context, const CreatePartidoScreen());
                } else {
                  _navigateTo(context, PartidoManagementScreen(partidoId: userProfile.activePartidoId!));
                }
              }),
          _buildDrawerSectionHeader(context, 'Registros y Finanzas'),
          _buildDrawerItem(context,
              icon: Icons.analytics_outlined,
              title: 'Panel Financiero',
              onTap: () => _navigateTo(context, FinancialDashboardScreen())),
          _buildDrawerItem(context,
              icon: Icons.monetization_on_outlined,
              title: 'Registro de Ventas',
              onTap: () => _navigateTo(context, SalesHistoryScreen())),
          _buildDrawerItem(context,
              icon: Icons.request_quote_outlined,
              title: 'Registro de Gastos',
              onTap: () => _navigateTo(context, ExpensesScreen())),
          _buildDrawerItem(context,
              icon: Icons.emoji_events_outlined,
              title: 'Torneos y Derbys',
              onTap: () => _navigateTo(context, const TournamentListScreen())),
          _buildDrawerSectionHeader(context, 'Cuenta y Ajustes'),
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
              value: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
              onChanged: (value) {
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red.shade400),
            title: Text('Cerrar Sesión', style: TextStyle(color: Colors.red.shade400)),
            onTap: () => _signOut(context),
          ),
          const Divider(),
          _buildDrawerItem(context,
              icon: Icons.help_center_outlined,
              title: 'Centro de Ayuda',
              onTap: () => _navigateTo(context, const HelpCenterScreen())),
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
                      child: Image.asset('assets/images/Icono-Roozterface.png',
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
                            shadows: [Shadow(blurRadius: 3, color: Colors.black)])),
                    const SizedBox(height: 4),
                    Text(userProfile.email,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            shadows: [Shadow(blurRadius: 2, color: Colors.black)])),
                    if (userProfile.activePartidoId != null) ...[
                      const SizedBox(height: 8),
                      StreamBuilder<PartidoModel?>(
                        stream: PartidoService().getActivePartidoStream(userProfile.activePartidoId!),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data == null) return const SizedBox();
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'PARTIDO: ${snapshot.data!.name.toUpperCase()}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ],
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
      decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.05)),
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
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
