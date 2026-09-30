import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/responsive_page.dart';
import '../v0_dashboard/v0_motion.dart';

/// Painel de dia + horários.
///
/// Dias em faixa horizontal. Slots em [Wrap] (altura real) — evita o buraco
/// vertical que o GridView+aspectRatio criava entre Manhã/Tarde/Noite no mobile.
class V0SchedulePanel extends StatelessWidget {
  const V0SchedulePanel({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.onSelectDay,
    required this.slotsByPeriod,
    required this.occupiedSlots,
    required this.pastSlots,
    required this.selectedTime,
    required this.onSelectTime,
    this.loading = false,
    this.closedMessage,
    this.onTryAnotherDay,
    this.emptyBookableHint,
  });

  final List<DateTime> days;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelectDay;
  final Map<String, List<String>> slotsByPeriod;
  final Set<String> occupiedSlots;
  final Set<String> pastSlots;
  final String? selectedTime;
  final ValueChanged<String> onSelectTime;
  final bool loading;
  final String? closedMessage;
  final VoidCallback? onTryAnotherDay;
  final String? emptyBookableHint;

  static const _labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final desktop = AppLayout.isClientDesktop(context);
    final dayStripHeight = desktop ? 80.0 : 76.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDayPicker(desktop, dayStripHeight),
        SizedBox(height: desktop ? 20 : 20),
        _buildSlotsBody(context, desktop),
      ],
    );
  }

  Widget _buildDayPicker(bool desktop, double dayStripHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Escolha o dia',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: dayStripHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, _) => SizedBox(width: desktop ? 8 : 8),
            itemBuilder: (context, index) {
              final day = days[index];
              final active = _sameDay(day, selectedDay);
              final label = _labels[day.weekday - 1];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelectDay(day),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: V0Motion.fast,
                    curve: V0Motion.easeOut,
                    width: desktop ? 66 : 64,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: active ? AppColors.primary : AppColors.border,
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: desktop ? 18 : 18,
                            fontWeight: FontWeight.w800,
                            color: active
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSlotsBody(BuildContext context, bool desktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Horários disponíveis',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (closedMessage != null)
          _HintBlock(
            message: closedMessage!,
            actionLabel: 'Ver outro dia',
            onAction: onTryAnotherDay,
          )
        else if (slotsByPeriod.isEmpty)
          _HintBlock(
            message: 'Nenhum horário disponível para este dia.',
            actionLabel: 'Tentar outro dia',
            onAction: onTryAnotherDay,
          )
        else ...[
          if (emptyBookableHint != null) ...[
            Text(
              emptyBookableHint!,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
          ],
          for (final entry in slotsByPeriod.entries)
            Builder(
              builder: (context) {
                final visible = entry.value
                    .where((slot) => !pastSlots.contains(slot))
                    .toList();
                if (visible.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.only(bottom: desktop ? 12 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(height: desktop ? 8 : 8),
                      _SlotWrap(
                        slots: visible,
                        occupiedSlots: occupiedSlots,
                        selectedTime: selectedTime,
                        onSelectTime: onSelectTime,
                        desktop: desktop,
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ],
    );
  }
}

class _HintBlock extends StatelessWidget {
  const _HintBlock({
    required this.message,
    required this.actionLabel,
    this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (onAction != null) ...[
            const SizedBox(height: 10),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ],
      ),
    );
  }
}

class _SlotWrap extends StatelessWidget {
  const _SlotWrap({
    required this.slots,
    required this.occupiedSlots,
    required this.selectedTime,
    required this.onSelectTime,
    required this.desktop,
  });

  final List<String> slots;
  final Set<String> occupiedSlots;
  final String? selectedTime;
  final ValueChanged<String> onSelectTime;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final gap = desktop ? 10.0 : 8.0;
        final cols = width >= 720
            ? 5
            : width >= 520
                ? 4
                : 3;
        final chipWidth = (width - gap * (cols - 1)) / cols;
        final chipHeight = desktop ? 40.0 : 42.0;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final slot in slots)
              SizedBox(
                width: chipWidth,
                height: chipHeight,
                child: _SlotChip(
                  label: slot,
                  unavailable: occupiedSlots.contains(slot),
                  selected: selectedTime == slot,
                  onTap: occupiedSlots.contains(slot)
                      ? null
                      : () => onSelectTime(slot),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.label,
    required this.unavailable,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool unavailable;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color background;
    Color border;
    Color text;
    if (unavailable) {
      background = AppColors.surfaceLight.withValues(alpha: 0.22);
      border = AppColors.border;
      text = AppColors.textMuted.withValues(alpha: 0.55);
    } else if (selected) {
      background = AppColors.primary;
      border = AppColors.primary;
      text = AppColors.background;
    } else {
      background = AppColors.background;
      border = AppColors.primary.withValues(alpha: 0.35);
      text = AppColors.primaryBright;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: V0Motion.fast,
          curve: V0Motion.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              decoration: unavailable ? TextDecoration.lineThrough : null,
              decorationColor: text,
            ),
          ),
        ),
      ),
    );
  }
}
