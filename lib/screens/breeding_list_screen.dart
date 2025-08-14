// lib/screens/breeding_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roozterfaceapp/models/breeding_event_model.dart';
import 'package:roozterfaceapp/providers/user_data_provider.dart';
import 'package:roozterfaceapp/screens/add_breeding_event_screen.dart';
import 'package:roozterfaceapp/services/breeding_service.dart';
import 'package:roozterfaceapp/widgets/breeding_event_tile.dart';

class BreedingListScreen extends StatefulWidget {
  const BreedingListScreen({super.key});

  @override
  State<BreedingListScreen> createState() => _BreedingListScreenState();
}

class _BreedingListScreenState extends State<BreedingListScreen> {
  final BreedingService _breedingService = BreedingService();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserDataProvider>(context);
    final activeGalleraId = userProvider.userProfile?.activeGalleraId;

    if (activeGalleraId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Libro de Cría')),
        body: const Center(
            child: Text('No hay una gallera activa seleccionada.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Libro de Cría'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AddBreedingEventScreen(galleraId: activeGalleraId),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Registrar Nueva Cruza',
      ),
      body: StreamBuilder<List<BreedingEventModel>>(
        stream: _breedingService.getAllBreedingEventsStream(
            galleraId: activeGalleraId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error al cargar las cruzas: ${snapshot.error}'));
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No hay cruzas registradas.\nPresiona el botón "+" para añadir la primera.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return BreedingEventTile(
                event: event,
                // Le pasamos un ID vacío ya que no estamos en el contexto de un gallo específico
                currentRoosterId: '',
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirmar Borrado'),
                      content: const Text(
                          '¿Estás seguro de que quieres borrar este registro de cruza?'),
                      actions: [
                        TextButton(
                            child: const Text('Cancelar'),
                            onPressed: () => Navigator.of(ctx).pop(false)),
                        TextButton(
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                            child: const Text('Borrar'),
                            onPressed: () => Navigator.of(ctx).pop(true)),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _breedingService.deleteBreedingEvent(
                        galleraId: activeGalleraId, eventId: event.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
