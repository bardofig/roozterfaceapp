// lib/screens/public_showcase_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/models/user_model.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/screens/rooster_details_screen.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';
import 'package:roozterfaceapp/widgets/rooster_tile.dart';

class PublicShowcaseScreen extends StatefulWidget {
  const PublicShowcaseScreen({super.key});

  @override
  State<PublicShowcaseScreen> createState() => _PublicShowcaseScreenState();
}

class _PublicShowcaseScreenState extends State<PublicShowcaseScreen> {
  final RoosterService _roosterService = RoosterService();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserDataProvider>(context);
    final userProfile = userProvider.userProfile;
    final activeGalleraId = userProfile?.activeGalleraId;

    if (activeGalleraId == null || userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Escaparate')),
        body: const Center(
            child: Text('No hay una gallera activa seleccionada.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Escaparate Público'),
        actions: [
          // En el futuro, aquí iría el botón para compartir la URL pública.
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Lógica para compartir (ej. usando el paquete 'share_plus')
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'La funcionalidad para compartir estará disponible pronto.')),
              );
            },
            tooltip: 'Compartir mi Escaparate',
          ),
        ],
      ),
      body: StreamBuilder<List<RoosterModel>>(
        stream: _roosterService.getShowcaseRoostersStream(activeGalleraId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child:
                    Text('Error al cargar el escaparate: ${snapshot.error}'));
          }

          final showcaseRoosters = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              // Cabecera con la información del Criador
              _buildHeader(context, userProfile),
              // Mensaje si no hay gallos en el escaparate
              if (showcaseRoosters.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No tienes ejemplares en tu escaparate.\nVe a la ficha de un gallo "En Venta" y activa la opción "Mostrar en Escaparate Público".',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              // Lista de gallos en el escaparate
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final rooster = showcaseRoosters[index];
                    // Reutilizamos RoosterTile, ya que es perfecto para esto.
                    return RoosterTile(
                      rooster: rooster,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RoosterDetailsScreen(rooster: rooster),
                          ),
                        );
                      },
                    );
                  },
                  childCount: showcaseRoosters.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel userProfile) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Icon(
              Icons.storefront,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Gallera de ${userProfile.fullName}',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ejemplares disponibles para la venta. Para más información, contactar:',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.email_outlined, size: 16),
                const SizedBox(width: 8),
                Text(userProfile.email),
              ],
            ),
            if (userProfile.mobilePhone.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text(userProfile.mobilePhone),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
