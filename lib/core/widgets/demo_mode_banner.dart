import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../data/repositories/demo_lab_repository.dart';
import '../../providers/lab_providers.dart';

class DemoModeBanner extends ConsumerWidget {
  final bool showScenarioSelector;

  const DemoModeBanner({
    super.key,
    this.showScenarioSelector = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(telemetryModeProvider);
    final activePreset = ref.watch(demoScenarioPresetProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mode.isDemo
            ? AppColors.secondaryAccent.withOpacity(0.14)
            : AppColors.primaryAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: mode.isDemo
              ? AppColors.secondaryAccent.withOpacity(0.55)
              : AppColors.primaryAccent.withOpacity(0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: mode.isDemo
                      ? AppColors.secondaryAccent
                      : AppColors.primaryAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mode.isDemo ? 'DEMO MODE • SIMULATED' : 'LIVE FIREBASE RTDB',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.darkBackground,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mode.isDemo
                      ? 'Isolated local telemetry simulator (no production overwrites)'
                      : 'smart-laboratory-62d87 (asia-southeast1)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: mode.isDemo
                      ? AppColors.primaryAccent
                      : AppColors.secondaryAccent,
                ),
                onPressed: () {
                  ref.read(telemetryModeProvider.notifier).state = mode.isDemo
                      ? AppTelemetryMode.firebaseLive
                      : AppTelemetryMode.demoSimulation;
                },
                icon: Icon(
                  mode.isDemo ? Icons.cloud_sync_outlined : Icons.science_outlined,
                  size: 16,
                ),
                label: Text(
                  mode.isDemo ? 'Switch Live' : 'Switch Demo',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (mode.isDemo && showScenarioSelector) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 30,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: DemoScenarioPreset.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final preset = DemoScenarioPreset.values[index];
                  final isSelected = preset == activePreset;
                  return ChoiceChip(
                    label: Text(
                      preset.title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.darkBackground
                            : AppColors.darkMainText,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primaryAccent,
                    backgroundColor: AppColors.darkSecondarySurface,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) {
                      ref.read(demoScenarioPresetProvider.notifier).state =
                          preset;
                      ref
                          .read(demoRepositoryInstanceProvider)
                          .setScenarioPreset(preset);
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
