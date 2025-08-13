import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PersonalityRadarChart extends StatelessWidget {
  final Map<String, double> scores;

  const PersonalityRadarChart({super.key, required this.scores});

  @override
  Widget build(BuildContext context) {
    final traits = scores.keys.toList();
    final values = scores.values.toList();

    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            dataEntries: List.generate(
              traits.length,
              (index) => RadarEntry(value: values[index]),
            ),
            fillColor: Colors.blue.withOpacity(0.3),
            borderColor: Colors.blue.shade600,
            borderWidth: 2,
          ),
        ],
        titleTextStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
        titlePositionPercentageOffset: 0.2,
        getTitle: (index, angle) {
          return RadarChartTitle(
            text: traits[index],
            angle: angle,
            positionPercentageOffset: 0.1,
          );
        },
        tickCount: 5,
        ticksTextStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 10,
          color: Colors.grey.shade600,
        ),
        borderData: FlBorderData(show: true),
        radarTouchData: RadarTouchData(enabled: true),
      ),
    );
  }
}
