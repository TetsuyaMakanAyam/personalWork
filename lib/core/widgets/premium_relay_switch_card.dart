import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import 'glass_3d_card.dart';

class PremiumRelaySwitchCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool requestedState;
  final bool? confirmedHardwareState;
  final bool isLoading;
  final bool isAutomaticMode;
  final Color activeColor;
  final ValueChanged<bool> onToggleRequested;

  const PremiumRelaySwitchCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.requestedState,
    required this.confirmedHardwareState,
    required this.isLoading,
    required this.isAutomaticMode,
    required this.activeColor,
    required this.onToggleRequested,
  });

  @override
  Widget build(BuildContext context) {
    final bool isHardwareConfirmedOn = confirmedHardwareState == true;
    final bool isAwaitingHardwareAck =
        confirmedHardwareState == null || confirmedHardwareState != requestedState;

    return Glass3DCard(
      accentGlowColor: requestedState ? activeColor : null,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: requestedState
                      ? activeColor.withOpacity(0.2)
                      : AppColors.darkBackground.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: requestedState
                        ? activeColor.withOpacity(0.65)
                        : AppColors.darkGlassBorder,
                  ),
                  boxShadow: requestedState
                      ? [
                          BoxShadow(
                            color: activeColor.withOpacity(0.32),
                            blurRadius: 14,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  color: requestedState ? activeColor : AppColors.darkSecondaryText,
                  size: 22,
                ),
              ),
              const Spacer(),
              _SpringRelayToggle(
                value: requestedState,
                isLoading: isLoading,
                activeColor: activeColor,
                onChanged: onToggleRequested,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 12),
          // Hardware Confirmation Badge (Never conflates Firebase write with physical relay state)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.darkBackground.withOpacity(0.55),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isAwaitingHardwareAck
                    ? AppColors.warning.withOpacity(0.45)
                    : (isHardwareConfirmedOn
                        ? AppColors.success.withOpacity(0.45)
                        : AppColors.darkGlassBorder),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isAwaitingHardwareAck
                      ? Icons.sync_rounded
                      : Icons.verified_outlined,
                  size: 13,
                  color: isAwaitingHardwareAck
                      ? AppColors.warning
                      : (isHardwareConfirmedOn
                          ? AppColors.success
                          : AppColors.darkSecondaryText),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    confirmedHardwareState == null
                        ? 'Req: ${requestedState ? "ON" : "OFF"} • Awaiting ESP32 ACK'
                        : (isAwaitingHardwareAck
                            ? 'Command Sent (${requestedState ? "ON" : "OFF"}) • Syncing Relay...'
                            : 'ESP32 Relay Confirmed: ${isHardwareConfirmedOn ? "ENERGIZED" : "STANDBY"}'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 9.8,
                          color: isAwaitingHardwareAck
                              ? AppColors.warning
                              : (isHardwareConfirmedOn
                                  ? AppColors.success
                                  : AppColors.darkSecondaryText),
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpringRelayToggle extends StatelessWidget {
  final bool value;
  final bool isLoading;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _SpringRelayToggle({
    required this.value,
    required this.isLoading,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        width: 58,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: value
              ? activeColor.withOpacity(0.28)
              : const Color(0xFF0D1422),
          border: Border.all(
            color: value ? activeColor : AppColors.darkGlassBorder,
            width: 1.4,
          ),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.35),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? activeColor : AppColors.darkSecondaryText,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.darkBackground,
                          ),
                        ),
                      )
                    : Icon(
                        value ? Icons.power_settings_new : Icons.circle_outlined,
                        size: 13,
                        color: AppColors.darkBackground,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
