// lib/services/pdf_service.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:roozterfaceapp/models/rooster_model.dart';
import 'package:roozterfaceapp/screens/pedigree_screen.dart';
import 'package:roozterfaceapp/services/financial_service.dart'; // ✅ NUEVO
import 'package:intl/intl.dart';

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

  Future<void> generateInventoryPdf({
    required List<RoosterModel> roosters,
    required String galleraName,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildInventoryHeader(galleraName, formatter.format(now)),
        footer: (context) => _buildInventoryFooter(context),
        build: (context) => [
          _buildInventorySummary(roosters),
          pw.SizedBox(height: 20),
          _buildInventoryTable(roosters),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/inventario_${now.millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());

    await OpenFilex.open(file.path);
  }

  pw.Widget _buildInventoryHeader(String galleraName, String date) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Reporte de Inventario",
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  galleraName,
                  style: const pw.TextStyle(fontSize: 18),
                ),
              ],
            ),
            pw.Text(date),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _buildInventoryFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  pw.Widget _buildInventorySummary(List<RoosterModel> roosters) {
    final total = roosters.length;
    final males = roosters.where((r) => r.sex == 'macho').length;
    final females = roosters.where((r) => r.sex == 'hembra').length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Total", total.toString()),
          _buildStatItem("Machos", males.toString()),
          _buildStatItem("Hembras", females.toString()),
        ],
      ),
    );
  }

  pw.Widget _buildStatItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  pw.Widget _buildInventoryTable(List<RoosterModel> roosters) {
    final headers = ['Placa', 'Nombre', 'Sexo', 'Línea', 'Estado', 'Peso'];

    final data = roosters.map((r) {
      return [
        r.plate.isNotEmpty ? r.plate : '-',
        r.name,
        r.sex == 'macho' ? 'M' : 'H',
        r.breedLine ?? '-',
        r.status,
        r.weight != null ? "${r.weight!.toStringAsFixed(2)}kg" : '-',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
                        3: pw.Alignment.centerLeft,
                        4: pw.Alignment.centerLeft,
                        5: pw.Alignment.centerRight,
                      },
    );
  }

  Future<void> generateRoosterDetailPdf({
    required RoosterModel rooster,
    required String galleraName,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formatter = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildInventoryHeader(galleraName, formatter.format(now)),
              pw.Center(
                child: pw.Text(
                  rooster.name,
                  style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoLine("Placa:", rooster.plate),
                        _buildInfoLine("Sexo:", rooster.sex),
                        _buildInfoLine("Nacimiento:", rooster.birthDate != null ? formatter.format(rooster.birthDate.toDate()) : 'N/A'),
                        _buildInfoLine("Estado:", rooster.status),
                        _buildInfoLine("Peso:", rooster.weight != null ? "${rooster.weight!.toStringAsFixed(2)}kg" : 'N/A'),
                        _buildInfoLine("Ubicación:", rooster.areaName ?? 'N/A'),
                        pw.SizedBox(height: 20),
                        pw.Text("Características", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                        _buildInfoLine("Línea:", rooster.breedLine ?? 'N/A'),
                        _buildInfoLine("Color:", rooster.color ?? 'N/A'),
                        _buildInfoLine("Cresta:", rooster.combType ?? 'N/A'),
                        _buildInfoLine("Patas:", rooster.legColor ?? 'N/A'),
                        pw.SizedBox(height: 20),
                        pw.Text("Linaje", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                        _buildInfoLine("Padre:", rooster.fatherName ?? rooster.fatherLineageText ?? 'N/A'),
                        _buildInfoLine("Madre:", rooster.motherName ?? rooster.motherLineageText ?? 'N/A'),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text("RoozterFace", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey)),
                          pw.SizedBox(height: 10),
                          pw.Text("FICHA TÉCNICA", style: const pw.TextStyle(fontSize: 10)),
                          pw.Divider(),
                          pw.SizedBox(height: 10),
                          pw.Text("Escanee para ver en la App", style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
                          // Aquí iría un QR si tuviéramos la librería, pero por ahora un placeholder elegante
                          pw.Container(
                            height: 60,
                            width: 60,
                            color: PdfColors.grey200,
                            child: pw.Center(child: pw.Text("RF", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text("Generado por RoozterFace - La mejor gestión para tu gallera", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/ficha_${rooster.name.replaceAll(' ', '_')}.pdf");
    await file.writeAsBytes(await pdf.save());

    await OpenFilex.open(file.path);
  }

  pw.Widget _buildInfoLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text("$label ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
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

  Future<void> generateFinancialReportPdf({
    required FinancialSummary summary,
    required List<Map<String, dynamic>> monthlyData,
    required Map<String, double> categoryBreakdown,
    required String galleraName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    final formatter = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildInventoryHeader(galleraName, "Reporte Financiero"),
        footer: (context) => _buildInventoryFooter(context),
        build: (context) => [
          pw.Text("Periodo: ${formatter.format(startDate)} al ${formatter.format(endDate)}",
              style: pw.TextStyle(color: PdfColors.grey700, fontSize: 12)),
          pw.SizedBox(height: 20),
          
          pw.Text("Resumen General", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Column(
              children: [
                _buildFinanceRow("Ingresos Totales", summary.totalIncome, PdfColors.green),
                _buildFinanceRow("Gastos Totales", summary.totalExpenses, PdfColors.red),
                pw.Divider(),
                _buildFinanceRow("Balance Neto", summary.netBalance, 
                    summary.netBalance >= 0 ? PdfColors.blue700 : PdfColors.red700, isBold: true),
              ],
            ),
          ),
          pw.SizedBox(height: 30),

          pw.Text("Distribución de Gastos", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          if (categoryBreakdown.isEmpty)
            pw.Text("No hay gastos registrados en este periodo.")
          else
            pw.TableHelper.fromTextArray(
              headers: ['Categoría', 'Monto'],
              data: categoryBreakdown.entries.map((e) => [
                e.key,
                NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(e.value)
              ]).toList(),
              border: null,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
              },
            ),

          pw.SizedBox(height: 30),
          pw.Text("Este reporte administrativo es generado por RoozterFace para fines de auditoría.", 
                 style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/reporte_financiero_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());

    await OpenFilex.open(file.path);
  }

  pw.Widget _buildFinanceRow(String label, double amount, PdfColor color, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(
            NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(amount),
            style: pw.TextStyle(
              color: color,
              fontWeight: pw.FontWeight.bold,
              fontSize: isBold ? 14 : 12,
            ),
          ),
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
