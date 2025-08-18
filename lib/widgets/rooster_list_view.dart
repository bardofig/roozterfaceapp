// lib/widgets/rooster_list_view.dart

import 'package:flutter/material.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/widgets/rooster_tile.dart';

class RoosterListView extends StatelessWidget {
  final List<RoosterModel> roosters;
  final Future<bool> Function(RoosterModel) onDelete;
  final Function(RoosterModel) onTap;

  const RoosterListView({
    super.key,
    required this.roosters,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (roosters.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "No hay ejemplares en esta categoría.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }
    return ListView.builder(
      // Añadimos padding para que el último elemento no sea tapado por el FAB
      padding: const EdgeInsets.only(bottom: 80.0, top: 8.0),
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
          confirmDismiss: (direction) => onDelete(rooster),
          child: RoosterTile(
            rooster: rooster,
            onTap: () => onTap(rooster),
          ),
        );
      },
    );
  }
}
