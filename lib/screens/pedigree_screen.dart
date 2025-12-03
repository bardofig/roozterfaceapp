// lib/screens/pedigree_screen.dart

import 'package:flutter/material.dart';
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/services/pdf_service.dart';
import 'package:roozterfaceapp/services/rooster_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:collection';

// --- CONSTANTES DE DISEÑO ---
const double kCardHeight = 90.0;
const double kCardWidth = 160.0;
const double kCardVerticalMargin = 4.0;
const double kCardHorizontalMargin = 8.0;
const double kSiblingSpacing = 20.0;
const double kGenerationSpacing = 60.0;

// --- MODELO DE DATOS INTERNO ---

class PedigreeNode {
  final RoosterModel rooster;
  final String uniquePathId;
  PedigreeNode? father;
  PedigreeNode? mother;

  PedigreeNode(this.rooster, this.uniquePathId);
}

// --- PANTALLA PRINCIPAL ---

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
  final PdfService _pdfService = PdfService();
  bool _isLoading = true;
  PedigreeNode? _rootNode;

  final TransformationController _transformationController =
      TransformationController();
  final Map<String, GlobalKey> _cardKeys = {};
  final GlobalKey _painterKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _transformationController.value = Matrix4.identity()
      ..translate(20.0, 300.0) // Ajuste para mejor centrado inicial
      ..scale(0.8);
    _loadPedigree();
  }

  Future<void> _loadPedigree() async {
    final Map<String, RoosterModel> cache = {};

    Future<PedigreeNode?> buildTree(
        RoosterModel currentRooster, String currentPathId,
        {int depth = 0}) async {
      if (depth >= 4) return PedigreeNode(currentRooster, currentPathId);

      _cardKeys.putIfAbsent(currentPathId, () => GlobalKey());
      final node = PedigreeNode(currentRooster, currentPathId);
      cache[currentRooster.id] = currentRooster;

      RoosterModel? fatherData;
      if (currentRooster.fatherId != null &&
          currentRooster.fatherId!.isNotEmpty) {
        fatherData = cache[currentRooster.fatherId] ??
            await _roosterService.getRoosterById(
                widget.galleraId, currentRooster.fatherId!);
      } else if (currentRooster.fatherLineageText != null &&
          currentRooster.fatherLineageText!.isNotEmpty) {
        fatherData = RoosterModel(
            id: 'ext_father_${currentRooster.id}',
            name: currentRooster.fatherLineageText!,
            plate: 'Externo',
            status: '',
            birthDate: Timestamp.now(),
            sex: 'macho');
      }

      if (fatherData != null) {
        node.father = await buildTree(fatherData, "${currentPathId}_father",
            depth: depth + 1);
      }

      RoosterModel? motherData;
      if (currentRooster.motherId != null &&
          currentRooster.motherId!.isNotEmpty) {
        motherData = cache[currentRooster.motherId] ??
            await _roosterService.getRoosterById(
                widget.galleraId, currentRooster.motherId!);
      } else if (currentRooster.motherLineageText != null &&
          currentRooster.motherLineageText!.isNotEmpty) {
        motherData = RoosterModel(
            id: 'ext_mother_${currentRooster.id}',
            name: currentRooster.motherLineageText!,
            plate: 'Externa',
            status: '',
            birthDate: Timestamp.now(),
            sex: 'hembra');
      }

      if (motherData != null) {
        node.mother = await buildTree(motherData, "${currentPathId}_mother",
            depth: depth + 1);
      }
      return node;
    }

    final root =
        await buildTree(widget.initialRooster, widget.initialRooster.id);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _rootNode = root;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _exportToPdf() async {
    if (_rootNode == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Generando PDF...')));
    try {
      await _pdfService.generateAndOpenPedigreePdf(_rootNode!);
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Árbol Genealógico de ${widget.initialRooster.name}'),
        actions: [
          if (!_isLoading && _rootNode != null)
            IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: _exportToPdf,
                tooltip: 'Exportar a PDF')
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rootNode == null
              ? const Center(child: Text("No se pudo cargar la genealogía."))
              : InteractiveViewer(
                  transformationController: _transformationController,
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(500.0),
                  minScale: 0.1,
                  maxScale: 2.5,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Stack(
                      // **CORRECCIÓN #1**: Se elimina `fit: StackFit.expand`.
                      // La Stack ahora tomará el tamaño de su hijo `_PedigreeChart`.
                      children: [
                        CustomPaint(
                          key: _painterKey,
                          painter: PedigreeLinesPainter(
                              rootNode: _rootNode!,
                              cardKeys: _cardKeys,
                              painterKey: _painterKey),
                          child: const SizedBox
                              .shrink(), // El painter no necesita tamaño, solo un child
                        ),
                        _PedigreeChart(
                          node: _rootNode!,
                          keys: _cardKeys,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

// --- WIDGET DE RENDERIZADO DEL ÁRBOL (CORREGIDO Y SIMPLIFICADO) ---

class _PedigreeChart extends StatelessWidget {
  final PedigreeNode node;
  final Map<String, GlobalKey> keys;

  const _PedigreeChart({required this.node, required this.keys});

  @override
  Widget build(BuildContext context) {
    final hasFather = node.father != null;
    final hasMother = node.mother != null;

    final keyForCard = keys[node.uniquePathId]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RoosterCard(
          rooster: node.rooster,
          key: keyForCard,
        ),
        if (hasFather || hasMother)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: kGenerationSpacing),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasFather)
                    _PedigreeChart(node: node.father!, keys: keys)
                  else if (hasMother)
                    // **CORRECCIÓN #2**: Usamos un SizedBox para balancear el layout.
                    // Es la herramienta correcta, simple y eficiente.
                    const SizedBox(
                        width: kCardWidth + kCardHorizontalMargin * 2,
                        height: kCardHeight + kCardVerticalMargin * 2),
                  if (hasFather && hasMother)
                    const SizedBox(height: kSiblingSpacing),
                  if (hasMother)
                    _PedigreeChart(node: node.mother!, keys: keys)
                  else if (hasFather)
                    const SizedBox(
                        width: kCardWidth + kCardHorizontalMargin * 2,
                        height: kCardHeight + kCardVerticalMargin * 2),
                ],
              ),
            ],
          )
      ],
    );
  }
}

// --- PINTOR DE LÍNEAS DE CONEXIÓN (Sin cambios) ---

class PedigreeLinesPainter extends CustomPainter {
  final PedigreeNode rootNode;
  final Map<String, GlobalKey> cardKeys;
  final GlobalKey painterKey;

  PedigreeLinesPainter(
      {required this.rootNode,
      required this.cardKeys,
      required this.painterKey});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.5;
    final painterBox =
        painterKey.currentContext?.findRenderObject() as RenderBox?;
    if (painterBox == null) return;

    final Queue<PedigreeNode> queue = Queue()..add(rootNode);
    while (queue.isNotEmpty) {
      final currentNode = queue.removeFirst();
      _drawConnectionToParent(canvas, paint, painterBox, currentNode,
          isFather: true);
      _drawConnectionToParent(canvas, paint, painterBox, currentNode,
          isFather: false);
      if (currentNode.father != null) queue.add(currentNode.father!);
      if (currentNode.mother != null) queue.add(currentNode.mother!);
    }
  }

  void _drawConnectionToParent(
      Canvas canvas, Paint paint, RenderBox painterBox, PedigreeNode childNode,
      {required bool isFather}) {
    final parentNode = isFather ? childNode.father : childNode.mother;
    if (parentNode == null) return;
    final childKey = cardKeys[childNode.uniquePathId];
    final parentKey = cardKeys[parentNode.uniquePathId];
    if (childKey == null || parentKey == null) return;
    final childBox = childKey.currentContext?.findRenderObject() as RenderBox?;
    final parentBox =
        parentKey.currentContext?.findRenderObject() as RenderBox?;
    if (childBox == null || parentBox == null) return;
    final childPos = childBox.localToGlobal(Offset.zero, ancestor: painterBox);
    final parentPos =
        parentBox.localToGlobal(Offset.zero, ancestor: painterBox);
    final childAnchor =
        Offset(childPos.dx, childPos.dy + childBox.size.height / 2);
    final parentAnchor = Offset(parentPos.dx + parentBox.size.width,
        parentPos.dy + parentBox.size.height / 2);
    final midPointX = parentAnchor.dx + (childAnchor.dx - parentAnchor.dx) / 2;
    canvas.drawLine(parentAnchor, Offset(midPointX, parentAnchor.dy), paint);
    canvas.drawLine(Offset(midPointX, parentAnchor.dy),
        Offset(midPointX, childAnchor.dy), paint);
    canvas.drawLine(Offset(midPointX, childAnchor.dy), childAnchor, paint);
  }

  @override
  bool shouldRepaint(covariant PedigreeLinesPainter oldDelegate) =>
      oldDelegate.rootNode != rootNode || oldDelegate.cardKeys != cardKeys;
}

// --- WIDGET DE TARJETA (SIMPLIFICADO) ---

class RoosterCard extends StatelessWidget {
  final RoosterModel rooster;
  const RoosterCard({super.key, required this.rooster});

  @override
  Widget build(BuildContext context) {
    bool isMale = rooster.sex == 'macho';
    bool isExternal = rooster.plate == 'Externo' || rooster.plate == 'Externa';
    bool isPlaceholder = rooster.name.contains('No Registrad');

    Widget content;
    BoxDecoration decoration;

    if (rooster.name.isEmpty) {
      // Lógica para el placeholder de espaciado
      return const SizedBox(width: kCardWidth, height: kCardHeight);
    }

    if (isPlaceholder) {
      decoration = BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300));
      content = Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(isMale ? Icons.male : Icons.female,
            size: 20, color: Colors.grey.shade500),
        const SizedBox(height: 4),
        Text(rooster.name,
            style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic),
            textAlign: TextAlign.center),
      ]);
    } else {
      decoration = BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isExternal
                ? Colors.grey.shade500
                : (isMale ? Colors.blue.shade300 : Colors.pink.shade300),
            width: isExternal ? 1.5 : 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      );
      content = Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(isExternal ? Icons.link_off : (isMale ? Icons.male : Icons.female),
            size: 20,
            color: isExternal
                ? Colors.grey.shade600
                : (isMale ? Colors.blue : Colors.pink)),
        const SizedBox(height: 4),
        Text(rooster.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        if (rooster.plate.isNotEmpty)
          Text(rooster.plate,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]);
    }

    return Container(
      width: kCardWidth,
      height: kCardHeight,
      margin: const EdgeInsets.symmetric(
          vertical: kCardVerticalMargin, horizontal: kCardHorizontalMargin),
      padding: const EdgeInsets.all(8),
      decoration: decoration,
      child: content,
    );
  }
}
