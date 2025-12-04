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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
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
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  );
                  String text;
                  switch (value.toInt()) {
                    case 1: text = 'ENE'; break;
                    case 3: text = 'MAR'; break;
                    case 5: text = 'MAY'; break;
                    case 7: text = 'JUL'; break;
                    case 9: text = 'SEP'; break;
                    case 11: text = 'NOV'; break;
                    default: return Container();
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(text, style: style),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxY / 5,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact().format(value),
                    style: const TextStyle(
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d).withOpacity(0.2)),
          ),
          minX: 1,
          maxX: 12,
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            // Línea de Ingresos (Verde)
            LineChartBarData(
              spots: monthlyData.map((data) {
                return FlSpot(
                    (data['month'] as int).toDouble(), data['income'] as double);
              }).toList(),
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.1),
              ),
            ),
            // Línea de Gastos (Rojo)
            LineChartBarData(
              spots: monthlyData.map((data) {
                return FlSpot(
                    (data['month'] as int).toDouble(), data['expense'] as double);
              }).toList(),
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.red.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
