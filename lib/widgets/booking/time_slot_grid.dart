import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class TimeSlotGrid extends StatelessWidget {
  const TimeSlotGrid({
    super.key,
    required this.slots,
    required this.occupiedSlots,
    this.pastSlots = const {},
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  final List<String> slots;
  final Set<String> occupiedSlots;
  final Set<String> pastSlots;
  final String? selectedSlot;
  final ValueChanged<String> onSlotSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.4,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isPast = pastSlots.contains(slot);
        final isOccupied = occupiedSlots.contains(slot);
        final isUnavailable = isPast || isOccupied;
        final isSelected = selectedSlot == slot;

        return _TimeSlotChip(
          label: slot,
          isUnavailable: isUnavailable,
          isSelected: isSelected,
          onTap: isUnavailable ? null : () => onSlotSelected(slot),
        );
      },
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  const _TimeSlotChip({
    required this.label,
    required this.isUnavailable,
    required this.isSelected,
    this.onTap,
  });

  final String label;
  final bool isUnavailable;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color background;
    Color borderColor;
    Color textColor;

    if (isUnavailable) {
      background = AppColors.surfaceLight.withValues(alpha: 0.4);
      borderColor = Colors.transparent;
      textColor = AppColors.textMuted.withValues(alpha: 0.5);
    } else if (isSelected) {
      background = AppColors.primary;
      borderColor = AppColors.primary;
      textColor = AppColors.background;
    } else {
      background = Colors.transparent;
      borderColor = AppColors.primary;
      textColor = AppColors.primaryBright;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
