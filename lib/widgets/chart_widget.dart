import 'package:flutter/material.dart';

class ChartData {
  final DateTime date;
  final double systolic;
  final double diastolic;
  final double? glucose;

  ChartData({
    required this.date,
    this.systolic = 0,
    this.diastolic = 0,
    this.glucose,
  });
}

class ChartWidget extends StatelessWidget {
  final List<ChartData> readings;
  final String? title;

  const ChartWidget({
    super.key,
    required this.readings,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: _buildSimpleChart(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleChart(BuildContext context) {
    final theme = Theme.of(context);

    // Get the last 7 readings for display
    final displayReadings = readings.take(7).toList().reversed.toList();

    if (displayReadings.isEmpty) {
      return const Center(child: Text('No data to display'));
    }

    return Column(
      children: [
        // Chart area
        Expanded(
          child: CustomPaint(
            size: const Size(double.infinity, double.infinity),
            painter: SimpleChartPainter(
              readings: displayReadings,
              primaryColor: theme.colorScheme.primary,
              secondaryColor: theme.colorScheme.secondary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        _buildLegend(context),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (readings.first.systolic > 0) ...[
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text('Systolic'),
            ],
          ),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text('Diastolic'),
            ],
          ),
        ] else if (readings.first.glucose != null) ...[
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text('Glucose'),
            ],
          ),
        ],
      ],
    );
  }
}

class SimpleChartPainter extends CustomPainter {
  final List<ChartData> readings;
  final Color primaryColor;
  final Color secondaryColor;

  SimpleChartPainter({
    required this.readings,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (readings.isEmpty) return;

    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()..style = PaintingStyle.fill;

    // Chart bounds
    const padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    // Draw grid lines
    _drawGrid(canvas, size, padding);

    // Calculate data points
    if (readings.first.systolic > 0) {
      // Blood pressure chart
      _drawBloodPressureChart(
          canvas, size, padding, chartWidth, chartHeight, paint, pointPaint);
    } else if (readings.first.glucose != null) {
      // Blood sugar chart
      _drawBloodSugarChart(
          canvas, size, padding, chartWidth, chartHeight, paint, pointPaint);
    }
  }

  void _drawGrid(Canvas canvas, Size size, double padding) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    // Horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = padding + (size.height - padding * 2) * i / 4;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    // Vertical grid lines
    for (int i = 0; i <= 6; i++) {
      final x = padding + (size.width - padding * 2) * i / 6;
      canvas.drawLine(
        Offset(x, padding),
        Offset(x, size.height - padding),
        gridPaint,
      );
    }
  }

  void _drawBloodPressureChart(Canvas canvas, Size size, double padding,
      double chartWidth, double chartHeight, Paint paint, Paint pointPaint) {
    // Find min/max values for scaling
    final systolicValues = readings.map((r) => r.systolic).toList();
    final diastolicValues = readings.map((r) => r.diastolic).toList();

    final minValue = [
          ...systolicValues,
          ...diastolicValues,
        ].reduce((a, b) => a < b ? a : b) -
        10;

    final maxValue = [
          ...systolicValues,
          ...diastolicValues,
        ].reduce((a, b) => a > b ? a : b) +
        10;

    final valueRange = maxValue - minValue;

    // Draw systolic line
    paint.color = primaryColor;
    final systolicPath = Path();
    for (int i = 0; i < readings.length; i++) {
      final x = padding + (chartWidth * i / (readings.length - 1));
      final y = padding +
          chartHeight -
          ((readings[i].systolic - minValue) / valueRange * chartHeight);

      if (i == 0) {
        systolicPath.moveTo(x, y);
      } else {
        systolicPath.lineTo(x, y);
      }

      // Draw point
      pointPaint.color = primaryColor;
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
    canvas.drawPath(systolicPath, paint);

    // Draw diastolic line
    paint.color = secondaryColor;
    final diastolicPath = Path();
    for (int i = 0; i < readings.length; i++) {
      final x = padding + (chartWidth * i / (readings.length - 1));
      final y = padding +
          chartHeight -
          ((readings[i].diastolic - minValue) / valueRange * chartHeight);

      if (i == 0) {
        diastolicPath.moveTo(x, y);
      } else {
        diastolicPath.lineTo(x, y);
      }

      // Draw point
      pointPaint.color = secondaryColor;
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
    canvas.drawPath(diastolicPath, paint);
  }

  void _drawBloodSugarChart(Canvas canvas, Size size, double padding,
      double chartWidth, double chartHeight, Paint paint, Paint pointPaint) {
    final glucoseValues = readings.map((r) => r.glucose!).toList();
    final minValue = glucoseValues.reduce((a, b) => a < b ? a : b) - 10;
    final maxValue = glucoseValues.reduce((a, b) => a > b ? a : b) + 10;
    final valueRange = maxValue - minValue;

    // Draw glucose line
    paint.color = primaryColor;
    final glucosePath = Path();
    for (int i = 0; i < readings.length; i++) {
      final x = padding + (chartWidth * i / (readings.length - 1));
      final y = padding +
          chartHeight -
          ((readings[i].glucose! - minValue) / valueRange * chartHeight);

      if (i == 0) {
        glucosePath.moveTo(x, y);
      } else {
        glucosePath.lineTo(x, y);
      }

      // Draw point
      pointPaint.color = primaryColor;
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
    canvas.drawPath(glucosePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
