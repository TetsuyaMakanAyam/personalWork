import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/demo_mode_banner.dart';
import '../../core/widgets/glass_3d_card.dart';
import '../../data/models/safety_settings_model.dart';
import '../../providers/lab_providers.dart';

class SafetySettingsScreen extends ConsumerStatefulWidget {
  const SafetySettingsScreen({super.key});

  @override
  ConsumerState<SafetySettingsScreen> createState() =>
      _SafetySettingsScreenState();
}

class _SafetySettingsScreenState extends ConsumerState<SafetySettingsScreen> {
  final _tempController = TextEditingController();
  final _gasController = TextEditingController();
  final _distController = TextEditingController();

  double _maxTemp = 35.0;
  int _maxGas = 1500;
  double _maxDistance = 20.0;
  bool _autoLed = true;
  bool _autoBuzzer = true;
  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _tempController.dispose();
    _gasController.dispose();
    _distController.dispose();
    super.dispose();
  }

  void _populateFromModel(SafetySettings s) {
    _maxTemp = s.maxTemp;
    _maxGas = s.maxGas;
    _maxDistance = s.maxDistance;
    _autoLed = s.autoLed;
    _autoBuzzer = s.autoBuzzer;
    _tempController.text = _maxTemp.toStringAsFixed(1);
    _gasController.text = _maxGas.toString();
    _distController.text = _maxDistance.toStringAsFixed(1);
  }

  Future<void> _saveSettings() async {
    final parsedTemp = double.tryParse(_tempController.text.trim()) ?? _maxTemp;
    final parsedGas = int.tryParse(_gasController.text.trim()) ?? _maxGas;
    final parsedDist =
        double.tryParse(_distController.text.trim()) ?? _maxDistance;

    final candidate = SafetySettings(
      maxTemp: parsedTemp,
      maxGas: parsedGas,
      maxDistance: parsedDist,
      autoLed: _autoLed,
      autoBuzzer: _autoBuzzer,
    );

    final validationError = candidate.validate();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.criticalDanger,
          content: Text(validationError),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(activeLabRepositoryProvider)
          .updateSafetySettings(candidate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Safety thresholds validated and committed via Firebase transaction.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.criticalDanger,
            content: Text('Failed to commit settings: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(safetySettingsStreamProvider);
    settingsAsync.whenData((s) {
      if (!_isInitialized) {
        _populateFromModel(s);
        _isInitialized = true;
      }
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Safety Thresholds',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Transactional limits synced to /settings in Firebase',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _populateFromModel(SafetySettings.defaults());
                      });
                    },
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: const Text('Defaults'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const DemoModeBanner(showScenarioSelector: false),

              // 1. Max Temperature Threshold Card
              Glass3DCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.thermostat_rounded,
                          color: AppColors.primaryAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Maximum Temperature (/settings/max_temp)',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        SizedBox(
                          width: 78,
                          child: TextField(
                            controller: _tempController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelLarge,
                            decoration: InputDecoration(
                              suffixText: '°C',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (v) {
                              final d = double.tryParse(v);
                              if (d != null && d >= 15.0 && d <= 85.0) {
                                setState(() => _maxTemp = d);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _maxTemp.clamp(15.0, 85.0),
                      min: 15.0,
                      max: 85.0,
                      divisions: 140,
                      label: '${_maxTemp.toStringAsFixed(1)}°C',
                      onChanged: (val) {
                        setState(() {
                          _maxTemp = val;
                          _tempController.text = val.toStringAsFixed(1);
                        });
                      },
                    ),
                    Text(
                      'Valid range: 15.0°C – 85.0°C. Triggers thermal warning above this ceiling.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. Gas Sensor Raw ADC Threshold Card
              Glass3DCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.air_rounded,
                          color: AppColors.secondaryAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Gas ADC Threshold (/settings/max_gas)',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        SizedBox(
                          width: 86,
                          child: TextField(
                            controller: _gasController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelLarge,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n != null && n >= 200 && n <= 4095) {
                                setState(() => _maxGas = n);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _maxGas.clamp(200, 4095).toDouble(),
                      min: 200,
                      max: 4095,
                      divisions: 389,
                      activeColor: AppColors.secondaryAccent,
                      label: '$_maxGas ADC',
                      onChanged: (val) {
                        setState(() {
                          _maxGas = val.round();
                          _gasController.text = _maxGas.toString();
                        });
                      },
                    ),
                    Text(
                      'Valid range: 200 – 4095 raw 12-bit ESP32 ADC counts (uncalibrated analog voltage level).',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Proximity Distance Threshold Card (HC-SR04)
              Glass3DCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.radar_rounded,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Proximity Alert Distance (/settings/max_distance)',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        SizedBox(
                          width: 82,
                          child: TextField(
                            controller: _distController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelLarge,
                            decoration: InputDecoration(
                              suffixText: 'cm',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (v) {
                              final d = double.tryParse(v);
                              if (d != null && d >= 5.0 && d <= 300.0) {
                                setState(() => _maxDistance = d);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _maxDistance.clamp(5.0, 300.0),
                      min: 5.0,
                      max: 300.0,
                      divisions: 295,
                      activeColor: AppColors.warning,
                      label: '${_maxDistance.toStringAsFixed(1)} cm',
                      onChanged: (val) {
                        setState(() {
                          _maxDistance = val;
                          _distController.text = val.toStringAsFixed(1);
                        });
                      },
                    ),
                    Text(
                      'Triggers an object proximity alert when HC-SR04 measures an object closer than this distance (5.0 – 300.0 cm).',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. Automated Relay Response Policies
              Glass3DCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AUTOMATIC ACTUATOR RESPONSE POLICY',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primaryAccent,
                      title: const Text('Automatic Warning Light (auto_led)'),
                      subtitle: const Text(
                        'Energize Relay Module 1 beacon automatically when any threshold is breached',
                      ),
                      value: _autoLed,
                      onChanged: (v) => setState(() => _autoLed = v),
                    ),
                    const Divider(),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.criticalDanger,
                      title:
                          const Text('Automatic Warning Buzzer (auto_buzzer)'),
                      subtitle: const Text(
                        'Energize Relay Module 2 acoustic siren automatically on critical hazard',
                      ),
                      value: _autoBuzzer,
                      onChanged: (v) => setState(() => _autoBuzzer = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: AppColors.darkBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveSettings,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_rounded),
                  label: Text(
                    _isSaving
                        ? 'COMMITTING TRANSACTION...'
                        : 'SAVE & SYNC THRESHOLDS TO FIREBASE',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
