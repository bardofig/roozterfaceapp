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

  final Map<String, RoosterModel> _roosterDataMap = {};

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
              child: Text("No hay datos de linaje para generar el árbol."),
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
                final roosterData = _roosterDataMap[roosterId];
                if (roosterData != null) {
                  return _buildNodeWidget(roosterData);
                }
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Error'),
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
    final allAncestorIds = <String>{};

    Future<void> collectAncestorIds(
      RoosterModel currentRooster,
      int maxDepth, {
      int currentDepth = 0,
    }) async {
      if (currentDepth >= maxDepth ||
          allAncestorIds.contains(currentRooster.id))
        return;
      allAncestorIds.add(currentRooster.id);

      if (currentRooster.fatherId != null) {
        final father = await _roosterService.getRoosterById(
          widget.galleraId,
          currentRooster.fatherId!,
        );
        if (father != null) {
          await collectAncestorIds(
            father,
            maxDepth,
            currentDepth: currentDepth + 1,
          );
        }
      }
      if (currentRooster.motherId != null) {
        final mother = await _roosterService.getRoosterById(
          widget.galleraId,
          currentRooster.motherId!,
        );
        if (mother != null) {
          await collectAncestorIds(
            mother,
            maxDepth,
            currentDepth: currentDepth + 1,
          );
        }
      }
    }

    await collectAncestorIds(widget.initialRooster, 3);

    if (allAncestorIds.isNotEmpty) {
      final roosters = await _roosterService.getRoostersByIds(
        widget.galleraId,
        allAncestorIds.toList(),
      );
      for (var rooster in roosters) {
        _roosterDataMap[rooster.id] = rooster;
      }
    }

    void buildGraphFromData(
      RoosterModel currentRooster,
      int maxDepth, {
      int currentDepth = 0,
    }) {
      if (currentDepth >= maxDepth || nodes.containsKey(currentRooster.id))
        return;
      nodes.putIfAbsent(currentRooster.id, () => Node.Id(currentRooster.id));

      if (currentRooster.fatherId != null &&
          _roosterDataMap.containsKey(currentRooster.fatherId)) {
        final father = _roosterDataMap[currentRooster.fatherId]!;
        buildGraphFromData(father, maxDepth, currentDepth: currentDepth + 1);
        graph.addEdge(
          nodes[currentRooster.id]!,
          nodes[father.id]!,
          paint: Paint()
            ..color = Colors.blue
            ..strokeWidth = 2,
        );
      }

      if (currentRooster.motherId != null &&
          _roosterDataMap.containsKey(currentRooster.motherId)) {
        final mother = _roosterDataMap[currentRooster.motherId]!;
        buildGraphFromData(mother, maxDepth, currentDepth: currentDepth + 1);
        // --- CORRECCIÓN CRÍTICA DEL TYPO ---
        graph.addEdge(
          nodes[currentRooster.id]!, // La variable correcta
          nodes[mother.id]!,
          paint: Paint()
            ..color = Colors.pink
            ..strokeWidth = 2,
        );
      }
    }

    // Aseguramos que el gallo inicial esté en el mapa antes de empezar a construir
    if (_roosterDataMap.containsKey(widget.initialRooster.id)) {
      buildGraphFromData(widget.initialRooster, 3);
    }

    return graph;
  }
}
