import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/animations/animated_gas_adc_meter.dart';
import '../../core/animations/animated_humidity_wave.dart';
import '../../core/animations/animated_proximity_radar.dart';
import '../../core/animations/animated_temperature_gauge.dart';
import '../../core/widgets/demo_mode_banner.dart';
import '../../core/widgets/glass_3d_card.dart';
import '../../data/models/lab_data_model.dart';
import '../../data/models/safety_settings_model.dart';
import '../../data/models/sensor_history_point.dart';
import '../../providers/lab_providers.dart';

class LiveMonitoringScreen extends ConsumerWidget {
  const LiveMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labData =
        ref.watch(labDataStreamProvider).valueOrNull ?? LabData.initial();
    final settings = ref.watch(safetySettingsStreamProvider).valueOrNull ??
        SafetySettings.defaults();
    final history =
        ref.watch(sensorHistoryStreamProvider).valueOrNull ?? const [];
    final isOnline = ref.watch(effectiveDeviceOnlineProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Telemetry & Analytics',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Real-time ESP32 sensor inspection, thresholds & stream charts',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              const DemoModeBanner(showScenarioSelector: true),

              // 1. Sensor Health Strip
              _SensorHealthStrip(
                isOnline: isOnline,
                sensorFault: labData.sensorFault,
              ),
              const SizedBox(height: 16),

              // 2. Large Animated Temperature & Humidity Dual Panel
              Glass3DCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DHT22 THERMAL & HUMIDITY BUS',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Text(
                          'MAX TEMP: ${settings.maxTemp.toStringAsFixed(1)}°C',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.primaryAccent,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        AnimatedTemperatureGauge(
                          temperature: labData.temperature,
                          maxThreshold: settings.maxTemp,
                          size: 160,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Relative Humidity',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              AnimatedHumidityWave(
                                humidityPercent: labData.humidity,
                                height: 120,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Real-time Temperature & Humidity Line Chart
              _TelemetryLineChartCard(
                title: 'TEMPERATURE (°C) & HUMIDITY (%) STREAM',
                subtitle:
                    'Live rolling session buffer (${history.length} samples)',
                history: history,
                thresholdValue: settings.maxTemp,
                isGasChart: false,
              ),
              const SizedBox(height: 16),

              // 4. Analog Gas ADC Visualizer + Ultrasonic Proximity Scanner
              Glass3DCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ANALOG GAS ADC & HC-SR04 PROXIMITY',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gas readings represent raw 12-bit ESP32 ADC values (0–4095), not calibrated ppm.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                          ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedGasAdcMeter(
                      gasAdcValue: labData.gasLevel,
                      maxAdcThreshold: settings.maxGas,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        AnimatedProximityRadar(
                          distanceCm: labData.distanceCm,
                          thresholdCm: settings.maxDistance,
                          size: 130,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HC-SR04 Ultrasonic Range',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Object Distance: ${labData.distanceCm.toStringAsFixed(1)} cm\n'
                                    'Alert Threshold: <= ${settings.maxDistance.toStringAsFixed(1)} cm\n'
                                    'Proximity Flag: ${labData.motionDetected ? "DETECTED" : "CLEAR"}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Real-time Gas ADC Line Chart
              _TelemetryLineChartCard(
                title: 'RAW GAS SENSOR ADC STREAM (0–4095)',
                subtitle:
                    'Threshold ceiling: ${settings.maxGas} ADC counts',
                history: history,
                thresholdValue: settings.maxGas.toDouble(),
                isGasChart: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SensorHealthStrip extends StatelessWidget {
  final bool isOnline;
  final bool sensorFault;

  const _SensorHealthStrip({
    required this.isOnline,
    required this.sensorFault,
  });

  @override
  Widget build(BuildContext context) {
    final String healthLabel = !isOnline
        ? 'TELEMETRY LINK OFFLINE'
        : (sensorFault ? 'BUS CHECKSUM FAULT' : 'ALL 4 SENSORS HEALTHY');
    final Color color = !isOnline
        ? AppColors.offlineNeutral
        : (sensorFault ? AppColors.criticalDanger : AppColors.success);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
            sensorFault
                ? Icons.warning_rounded
                : (isOnline ? Icons.check_circle_outline : Icons.portable_wifi_off),
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'SENSOR HEALTH: $healthLabel',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                  ),
            ),
          ),
          Text(
            'DHT22 • ADC • HC-SR04',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _TelemetryLineChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<SensorHistoryPoint> history;
  final double thresholdValue;
  final bool isGasChart;

  const _TelemetryLineChartCard({
    required this.title,
    required this.subtitle,
    required this.history,
    required this.thresholdValue,
    required this.isGasChart,
  });

  @override
  Widget build(BuildContext context) {
    return Glass3DCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 2),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          if (history.length < 2)
            Container(
              height: 180,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.darkBackground.withOpacity(0.45),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkGlassBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timeline_rounded,
                      color: AppColors.darkSecondaryText,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Awaiting Live Telemetry Samples',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Historical readings are never fabricated. As the ESP32 publishes updates to Firebase, real-time trend points will plot here automatically.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 190,
              child: LineChart(
                LineChartData(
                  minY: isGasChart ? 0 : 0,
                  maxY: isGasChart ? 4095 : 100,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white.withOpacity(0.06),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        getTitlesWidget: (val, meta) => Text(
                          '${val.round()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.darkSecondaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: thresholdValue,
                        color: AppColors.criticalDanger.withOpacity(0.75),
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.criticalDanger,
                          ),
                          labelResolver: (_) =>
                              'LIMIT ${thresholdValue.toStringAsFixed(0)}',
                        ),
                      ),
                    ],
                  ),
                  lineBarsData: isGasChart
                      ? [
                          LineChartBarData(
                            spots: [
                              for (int i = 0; i < history.length; i++)
                                FlSpot(
                                  i.toDouble(),
                                  history[i].gasAdc.toDouble(),
                                ),
                            ],
                            isCurved: true,
                            color: AppColors.secondaryAccent,
                            barWidth: 2.8,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.secondaryAccent.withOpacity(0.16),
                            ),
                          ),
                        ]
                      : [
                          // Temperature line
                          LineChartBarData(
                            spots: [
                              for (int i = 0; i < history.length; i++)
                                FlSpot(i.toDouble(), history[i].temperature),
                            ],
                            isCurved: true,
                            color: AppColors.primaryAccent,
                            barWidth: 2.8,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.primaryAccent.withOpacity(0.15),
                            ),
                          ),
                          // Humidity line
                          LineChartBarData(
                            spots: [
                              for (int i = 0; i < history.length; i++)
                                FlSpot(i.toDouble(), history[i].humidity),
                            ],
                            isCurved: true,
                            color: AppColors.success,
                            barWidth: 2.0,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
