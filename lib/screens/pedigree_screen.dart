// lib/screens/pedigree_screen.dart

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';

class PedigreeScreen extends StatefulWidget {
  final RoosterModel initialRooster;
  final String galleraId;

  const PedigreeScreen({
    super.key,
    required this.initialRooster,
    required this.galleraId,
  });

  @override
  State<PedigreeScreen> createState() => _PedigreeScreenState();
}

class _PedigreeScreenState extends State<PedigreeScreen> {
  final RoosterService _roosterService = RoosterService();
  late BuchheimWalkerConfiguration _builderConfig;

  @override
  void initState() {
    super.initState();
    _builderConfig = BuchheimWalkerConfiguration()
      ..siblingSeparation = (50)
      ..levelSeparation = (80)
      ..subtreeSeparation = (50)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_RIGHT_LEFT);
  }

  Widget _buildNodeWidget(RoosterModel rooster) {
    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minWidth: 100),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rooster.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (rooster.plate.isNotEmpty)
            Text(
              'Placa: ${rooster.plate}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Árbol Genealógico de ${widget.initialRooster.name}'),
      ),
      body: FutureBuilder<Graph>(
        future: _buildPedigreeGraph(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Error al generar el árbol: ${snapshot.error}"),
            );
          }
          if (!snapshot.hasData || snapshot.data!.nodeCount() <= 1) {
            return const Center(
              child: Text(
                "No hay datos de linaje registrados para generar el árbol.",
              ),
            );
          }

          return InteractiveViewer(
            constrained: false,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.1,
            maxScale: 2.0,
            child: GraphView(
              graph: snapshot.data!,
              algorithm: BuchheimWalkerAlgorithm(
                _builderConfig,
                TreeEdgeRenderer(_builderConfig),
              ),
              paint: Paint()
                ..color =
                    Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey
                ..strokeWidth = 1
                ..style = PaintingStyle.stroke,
              builder: (Node node) {
                var roosterId = node.key!.value as String;
                return FutureBuilder<RoosterModel?>(
                  future: _roosterService.getRoosterById(
                    widget.galleraId,
                    roosterId,
                  ),
                  builder: (context, roosterSnapshot) {
                    if (roosterSnapshot.hasData &&
                        roosterSnapshot.data != null) {
                      return _buildNodeWidget(roosterSnapshot.data!);
                    }
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('...'),
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

  Future<Graph> _buildPedigreeGraph() async {
    final graph = Graph();
    final nodes = <String, Node>{};

    Future<void> addParents(
      RoosterModel currentRooster,
      int maxDepth, {
      int currentDepth = 0,
    }) async {
      if (currentDepth >= maxDepth) return;

      nodes.putIfAbsent(currentRooster.id, () => Node.Id(currentRooster.id));

      if (currentRooster.fatherId != null) {
        final father = await _roosterService.getRoosterById(
          widget.galleraId,
          currentRooster.fatherId!,
        );
        if (father != null) {
          nodes.putIfAbsent(father.id, () => Node.Id(father.id));
          graph.addEdge(
            nodes[currentRooster.id]!,
            nodes[father.id]!,
            paint: Paint()
              ..color = Colors.blue
              ..strokeWidth = 2,
          );
          await addParents(father, maxDepth, currentDepth: currentDepth + 1);
        }
      }

      if (currentRooster.motherId != null) {
        final mother = await _roosterService.getRoosterById(
          widget.galleraId,
          currentRooster.motherId!,
        );
        if (mother != null) {
          nodes.putIfAbsent(mother.id, () => Node.Id(mother.id));
          graph.addEdge(
            nodes[currentRooster.id]!,
            nodes[mother.id]!,
            paint: Paint()
              ..color = Colors.pink
              ..strokeWidth = 2,
          );
          await addParents(mother, maxDepth, currentDepth: currentDepth + 1);
        }
      }
    }

    await addParents(widget.initialRooster, 3);
    return graph;
  }
}
