import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SensorChart extends StatefulWidget {
  final List<double> data;
  final Color color;

  const SensorChart({super.key, required this.data, required this.color});

  @override
  State<SensorChart> createState() => _SensorChartState();
}

class _SensorChartState extends State<SensorChart> {
  final List<double> xData = [];
  final List<double> yData = [];
  final List<double> zData = [];

  @override
  void didUpdateWidget(covariant SensorChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.length == 3) {
      xData.add(widget.data[0]);
      yData.add(widget.data[1]);
      zData.add(widget.data[2]);

      if (xData.length > 30) {
        xData.removeAt(0);
        yData.removeAt(0);
        zData.removeAt(0);
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            _buildLine(xData, Colors.red),
            _buildLine(yData, Colors.green),
            _buildLine(zData, Colors.blue),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildLine(List<double> values, Color color) {
    return LineChartBarData(
      spots: List.generate(
        values.length,
        (index) => FlSpot(index.toDouble(), values[index]),
      ),
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: const FlDotData(show: false),
    );
  }
}
