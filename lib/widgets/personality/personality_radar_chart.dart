import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PersonalityRadarChart extends StatelessWidget {
  final Map<String, double> scores;

  const PersonalityRadarChart({super.key, required this.scores});

  @override
  Widget build(BuildContext context) {
    // Ensure stable alignment between labels and values
    final entries = scores.entries.toList();
    if (entries.length < 3) {
      return Center(
        child: Text(
          'Not enough data to display chart',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      );
    }

    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            dataEntries: List.generate(
              entries.length,
              (index) => RadarEntry(value: entries[index].value),
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
            text: entries[index].key,
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
