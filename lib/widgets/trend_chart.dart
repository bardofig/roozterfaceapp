import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyData;

  const TrendChart({super.key, required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return const Center(child: Text("No hay datos suficientes"));
    }

    // Encontrar el valor máximo para escalar el gráfico
    double maxY = 0;
    for (var data in monthlyData) {
      if (data['income'] > maxY) maxY = data['income'];
      if (data['expense'] > maxY) maxY = data['expense'];
    }
    // Agregar un margen superior
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  );
                  String text;
                  switch (value.toInt()) {
                    case 1: text = 'Ene'; break;
                    case 4: text = 'Abr'; break;
                    case 7: text = 'Jul'; break;
                    case 10: text = 'Oct'; break;
                    case 12: text = 'Dic'; break;
                    default: return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(text, style: style),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxY / 4,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(
                    NumberFormat.compact().format(value),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 35,
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => Colors.blueGrey.withOpacity(0.8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.barIndex == 0 ? 'Ingreso' : 'Gasto'}: \$${NumberFormat.compact().format(spot.y)}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 1,
          maxX: 12,
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            // Línea de Ingresos (Premium Green)
            LineChartBarData(
              spots: monthlyData.map((data) {
                return FlSpot(
                    (data['month'] as int).toDouble(), (data['income'] as num).toDouble());
              }).toList(),
              isCurved: true,
              curveSmoothness: 0.35,
              gradient: const LinearGradient(colors: [Colors.greenAccent, Colors.green]),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [Colors.greenAccent.withOpacity(0.2), Colors.green.withOpacity(0.0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Línea de Gastos (Premium Red)
            LineChartBarData(
              spots: monthlyData.map((data) {
                return FlSpot(
                    (data['month'] as int).toDouble(), (data['expense'] as num).toDouble());
              }).toList(),
              isCurved: true,
              curveSmoothness: 0.35,
              gradient: const LinearGradient(colors: [Colors.redAccent, Colors.red]),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [Colors.redAccent.withOpacity(0.2), Colors.red.withOpacity(0.0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
