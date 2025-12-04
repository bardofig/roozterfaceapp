import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpensePieChart extends StatefulWidget {
  final Map<String, double> categoryData;

  const ExpensePieChart({super.key, required this.categoryData});

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categoryData.isEmpty) {
      return const Center(child: Text("No hay gastos registrados"));
    }

    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.brown,
    ];

    List<PieChartSectionData> showingSections() {
      int i = 0;
      return widget.categoryData.entries.map((entry) {
        final isTouched = i == touchedIndex;
        final fontSize = isTouched ? 20.0 : 14.0;
        final radius = isTouched ? 110.0 : 100.0;
        final color = colors[i % colors.length];
        final value = entry.value;
        final title = isTouched
            ? NumberFormat.compactCurrency(symbol: '\$').format(value)
            : '${(value / widget.categoryData.values.reduce((a, b) => a + b) * 100).toStringAsFixed(0)}%';

        i++;
        return PieChartSectionData(
          color: color,
          value: value,
          title: title,
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
          ),
        );
      }).toList();
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AspectRatio(
            aspectRatio: 1,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 0,
                sections: showingSections(),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.categoryData.keys.toList().asMap().entries.map((e) {
              final index = e.key;
              final category = e.value;
              final color = colors[index % colors.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(category,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
