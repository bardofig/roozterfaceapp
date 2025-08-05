// lib/widgets/rooster_tile.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class RoosterTile extends StatelessWidget {
  final String name;
  final String plate;
  final String status;
  final String imageUrl; // Parámetro para la URL de la imagen
  final VoidCallback onTap;

  const RoosterTile({
    super.key,
    required this.name,
    required this.plate,
    required this.status,
    required this.imageUrl,
    required this.onTap,
  });

  // Función interna para obtener el color basado en el estado del gallo
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'activo':
        return Colors.green.shade600;
      case 'en venta':
        return Colors.blue.shade600;
      case 'descansando':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[200],
            // Lógica para mostrar la imagen de la red o un icono por defecto
            child: imageUrl.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      // Widget que se muestra mientras la imagen carga
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(strokeWidth: 2.0),
                      // Widget que se muestra si hay un error al cargar la imagen
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error_outline),
                      fit: BoxFit.cover,
                      width: 50,
                      height: 50,
                    ),
                  )
                : Icon(Icons.shield_outlined, color: Colors.grey[800]),
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text('Placa: $plate'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
