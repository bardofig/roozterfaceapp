// lib/widgets/area_column_widget.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:roozterfaceapp/models/area_model.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';
import 'package:roozterfaceapp/widgets/draggable_rooster_card.dart';

class AreaColumnWidget extends StatefulWidget {
  final String galleraId;
  final AreaModel? area;

  const AreaColumnWidget({
    super.key,
    required this.galleraId,
    this.area,
  });

  @override
  State<AreaColumnWidget> createState() => _AreaColumnWidgetState();
}

class _AreaColumnWidgetState extends State<AreaColumnWidget> {
  final RoosterService _roosterService = RoosterService();
  late Stream<List<RoosterModel>> _roostersStream;
  late Stream<QuerySnapshot> _countStream;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  @override
  void didUpdateWidget(AreaColumnWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.area?.id != widget.area?.id || oldWidget.galleraId != widget.galleraId) {
      _initStreams();
    }
  }

  void _initStreams() {
    _roostersStream = FirebaseFirestore.instance
        .collection('galleras')
        .doc(widget.galleraId)
        .collection('gallos')
        .where('areaId', isEqualTo: widget.area?.id)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => RoosterModel.fromFirestore(doc))
            .toList())
        .asBroadcastStream(); // ✅ Aseguramos broadcast para evitar errores de suscripción doble

    _countStream = FirebaseFirestore.instance
        .collection('galleras')
        .doc(widget.galleraId)
        .collection('gallos')
        .where('areaId', isEqualTo: widget.area?.id)
        .snapshots()
        .asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    final areaId = widget.area?.id;
    final areaName = widget.area?.name ?? 'Sin Área';

    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // CABECERA DE LA COLUMNA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.area != null ? Colors.blueAccent : Colors.orangeAccent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  widget.area != null ? Icons.location_on : Icons.help_outline,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    areaName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Contador (StreamBuilder local para el contador de esta columna)
                _buildCountBadge(),
              ],
            ),
          ),

          // CUERPO DE LA COLUMNA (DRAG TARGET)
          Expanded(
            child: DragTarget<RoosterModel>(
              onWillAccept: (data) => data?.areaId != areaId,
              onAccept: (rooster) async {
                await _roosterService.updateRoosterArea(
                  galleraId: widget.galleraId,
                  roosterId: rooster.id,
                  areaId: areaId,
                  areaName: areaId == null ? null : areaName,
                );
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  color: candidateData.isNotEmpty 
                      ? Colors.blue.withOpacity(0.1) 
                      : Colors.transparent,
                  child: StreamBuilder<List<RoosterModel>>(
                    stream: _roostersStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final roosters = snapshot.data!;

                      if (roosters.isEmpty) {
                        return Center(
                          child: Opacity(
                            opacity: 0.5,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.inventory_2_outlined, size: 40),
                                const SizedBox(height: 8),
                                Text(
                                  areaId == null ? 'Todo asignado' : 'Vacío',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: roosters.length,
                        itemBuilder: (context, index) {
                          return DraggableRoosterCard(rooster: roosters[index]);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: _countStream,
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
