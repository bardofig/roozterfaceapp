// lib/services/pdf_service.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/screens/pedigree_screen.dart';

class PdfService {
  Future<void> generateAndOpenPedigreePdf(PedigreeNode rootNode) async {
    final pdf = pw.Document();

    // Cargamos la fuente que sí incluye los símbolos.
    final fontData =
        await rootBundle.load("assets/fonts/NotoEmoji-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter.landscape,
        theme: pw.ThemeData.withFont(
            base: ttf), // Aplicamos la fuente a toda la página
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Árbol Genealógico de ${rootNode.rooster.name}',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 20)),
                    pw.Text('Generado con RoozterFace',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey)),
                  ],
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Expanded(
                child: pw.Center(
                  child: _buildPdfChart(rootNode),
                ),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
        "${output.path}/pedigri_${rootNode.rooster.name.replaceAll(' ', '_')}.pdf");
    await file.writeAsBytes(await pdf.save());

    await OpenFilex.open(file.path);
  }

  // Esta lógica de layout con Row/Column anidados es la correcta.
  pw.Widget _buildPdfChart(PedigreeNode node) {
    if (node.rooster.name.contains('No Registrad') &&
        node.father == null &&
        node.mother == null) {
      return _buildPdfCard(node.rooster);
    }

    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (node.father != null && node.mother != null)
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              _buildPdfChart(node.father!),
              pw.SizedBox(height: 20),
              _buildPdfChart(node.mother!),
            ],
          ),

        if (node.father != null && node.mother != null)
          _ParentConnector(), // Volvemos a usar el conector con CustomPaint

        _buildPdfCard(node.rooster),
      ],
    );
  }

  pw.Widget _buildPdfCard(RoosterModel rooster) {
    final bool isMale = rooster.sex == 'macho';
    final bool isExternal =
        rooster.plate == 'Externo' || rooster.plate == 'Externa';
    final bool isPlaceholder = rooster.name.contains('No Registrad');
    final PdfColor borderColor = isExternal
        ? PdfColors.grey500
        : (isMale ? PdfColors.blue300 : PdfColors.pink300);
    final double cardHeight = isPlaceholder ? 60 : 70;

    // Asignamos el símbolo correcto. La fuente NotoEmoji se encargará de renderizarlo.
    final String genderSymbol = isMale ? "♂" : "♀";
    final String iconSymbol = isExternal ? "🔗" : genderSymbol;

    if (isPlaceholder) {
      return pw.Container(
          width: 140,
          height: cardHeight,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey400)),
          child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(genderSymbol,
                    style: const pw.TextStyle(
                        fontSize: 18, color: PdfColors.grey600)),
                pw.SizedBox(height: 4),
                pw.Text(rooster.name,
                    style: pw.TextStyle(
                        color: PdfColors.grey700,
                        fontStyle: pw.FontStyle.italic),
                    textAlign: pw.TextAlign.center),
              ]));
    }

    return pw.Container(
      width: 140,
      height: cardHeight,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: borderColor, width: 2),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(iconSymbol,
              style: pw.TextStyle(
                  fontSize: 18,
                  color: isExternal ? PdfColors.grey700 : borderColor)),
          pw.SizedBox(height: 4),
          pw.Text(
            rooster.name,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
            maxLines: 2,
          ),
          if (rooster.plate.isNotEmpty)
            pw.Text(rooster.plate,
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        ],
      ),
    );
  }
}

// --- WIDGET CONECTOR REESCRITO DESDE CERO, USANDO LA API DE DIBUJO CORRECTA Y VERIFICADA ---
class _ParentConnector extends pw.StatelessWidget {
  @override
  pw.Widget build(pw.Context context) {
    const double cardHeight = 70;
    const double spacing = 20;
    const double totalHeight = (cardHeight * 2) + spacing;

    return pw.SizedBox(
      width: 40,
      height: totalHeight,
      child: pw.CustomPaint(
        painter: (canvas, size) {
          // 1. Establecer el estilo de la línea
          canvas.setStrokeColor(PdfColors.grey400);
          canvas.setLineWidth(1.5);

          // Puntos clave
          final childPointY = size.y / 2;
          const fatherPointY = cardHeight / 2;
          const motherPointY = totalHeight - (cardHeight / 2);
          final midPointX = size.x - 20;

          // 2. Dibujar las líneas una por una

          // Línea horizontal principal (del hijo al punto medio de los padres)
          canvas.moveTo(midPointX, childPointY);
          canvas.lineTo(size.x, childPointY);

          // Línea vertical que une el espacio entre padres
          canvas.moveTo(midPointX, fatherPointY);
          canvas.lineTo(midPointX, motherPointY);

          // Línea horizontal del padre (desde el borde de su columna hasta la línea vertical)
          canvas.moveTo(0, fatherPointY);
          canvas.lineTo(midPointX, fatherPointY);

          // Línea horizontal de la madre (desde el borde de su columna hasta la línea vertical)
          canvas.moveTo(0, motherPointY);
          canvas.lineTo(midPointX, motherPointY);

          // 3. Ejecutar el dibujado
          canvas.strokePath();
        },
      ),
    );
  }
}
