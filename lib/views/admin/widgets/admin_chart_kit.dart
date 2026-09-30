import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class AdminBarChartItem {
  const AdminBarChartItem({
    required this.label,
    required this.value,
    this.displayValue,
  });

  final String label;
  final double value;
  final String? displayValue;
}

class AdminChartPeakBadge extends StatelessWidget {
  const AdminChartPeakBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up_rounded,
            size: 14,
            color: AppColors.primary.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 4),
          Text(
            'Pico: $label',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminVerticalBarChart extends StatelessWidget {
  const AdminVerticalBarChart({
    super.key,
    required this.headline,
    required this.subtitle,
    required this.items,
    this.highlightIndex,
    this.todayIndex,
    this.barMaxWidth = 28,
    this.chartHeight = 148,
  });

  final String headline;
  final String subtitle;
  final List<AdminBarChartItem> items;
  final int? highlightIndex;
  final int? todayIndex;
  final double barMaxWidth;
  final double chartHeight;

  double get _maxValue {
    if (items.isEmpty) return 0;
    return items.fold<double>(
      0,
      (prev, item) => math.max(prev, item.value),
    );
  }

  int get _peakIndex {
    final max = _maxValue;
    if (max <= 0) return -1;
    if (highlightIndex != null) return highlightIndex!;
    return items.indexWhere((item) => item.value == max);
  }

  @override
  Widget build(BuildContext context) {
    final peakIndex = _peakIndex;
    final maxValue = _maxValue;
    final hasData = maxValue > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (hasData && peakIndex >= 0)
              AdminChartPeakBadge(label: items[peakIndex].label),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: chartHeight + 36,
          child: CustomPaint(
            painter: AdminChartGridPainter(hasData: hasData),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _VerticalBarColumn(
                      item: items[i],
                      maxValue: maxValue,
                      chartHeight: chartHeight,
                      barMaxWidth: barMaxWidth,
                      isToday: todayIndex == i,
                      isPeak: i == peakIndex,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VerticalBarColumn extends StatelessWidget {
  const _VerticalBarColumn({
    required this.item,
    required this.maxValue,
    required this.chartHeight,
    required this.barMaxWidth,
    required this.isToday,
    required this.isPeak,
  });

  final AdminBarChartItem item;
  final double maxValue;
  final double chartHeight;
  final double barMaxWidth;
  final bool isToday;
  final bool isPeak;

  @override
  Widget build(BuildContext context) {
    final hasValue = item.value > 0;
    final ratio = maxValue <= 0 ? 0.0 : item.value / maxValue;
    final barHeight = hasValue ? math.max(8.0, ratio * chartHeight) : 0.0;
    final valueLabel = item.displayValue ??
        (item.value % 1 == 0
            ? item.value.toStringAsFixed(0)
            : item.value.toStringAsFixed(1));

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (hasValue)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              valueLabel,
              style: TextStyle(
                color: isPeak ? AppColors.primary : AppColors.textMuted,
                fontSize: 10,
                fontWeight: isPeak ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          )
        else
          const SizedBox(height: 16),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: barHeight),
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
          builder: (context, height, _) {
            if (!hasValue) {
              return Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: const BoxDecoration(
                  color: AppColors.border,
                  shape: BoxShape.circle,
                ),
              );
            }

            return Container(
              width: barMaxWidth,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: isPeak
                    ? AppColors.primaryGradient
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.45),
                          AppColors.primary.withValues(alpha: 0.18),
                        ],
                      ),
                boxShadow: isPeak
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
                border: isToday
                    ? Border.all(
                        color: AppColors.primary.withValues(alpha: 0.55),
                        width: 1.2,
                      )
                    : null,
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Text(
          item.label,
          style: TextStyle(
            color: isToday || isPeak
                ? AppColors.textPrimary
                : AppColors.textMuted,
            fontSize: 11,
            fontWeight: isToday || isPeak ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        if (isToday)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          )
        else
          const SizedBox(height: 8),
      ],
    );
  }
}

class AdminHorizontalBarChart extends StatelessWidget {
  const AdminHorizontalBarChart({
    super.key,
    required this.headline,
    required this.subtitle,
    required this.items,
    this.valueSuffix = '',
  });

  final String headline;
  final String subtitle;
  final List<AdminBarChartItem> items;
  final String valueSuffix;

  int get _peakIndex {
    if (items.isEmpty) return -1;
    var max = -1.0;
    var index = -1;
    for (var i = 0; i < items.length; i++) {
      if (items[i].value > max) {
        max = items[i].value;
        index = i;
      }
    }
    return max <= 0 ? -1 : index;
  }

  @override
  Widget build(BuildContext context) {
    final peakIndex = _peakIndex;
    final maxValue = peakIndex < 0 ? 0.0 : items[peakIndex].value;
    final hasData = maxValue > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (hasData && peakIndex >= 0)
              AdminChartPeakBadge(label: items[peakIndex].label),
          ],
        ),
        const SizedBox(height: 16),
        if (!hasData)
          const Text(
            'Sem dados de volume neste período.',
            style: TextStyle(color: AppColors.textMuted),
          )
        else
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HorizontalBarRow(
                item: items[i],
                maxValue: maxValue,
                isPeak: i == peakIndex,
                valueSuffix: valueSuffix,
              ),
            ),
      ],
    );
  }
}

class _HorizontalBarRow extends StatelessWidget {
  const _HorizontalBarRow({
    required this.item,
    required this.maxValue,
    required this.isPeak,
    required this.valueSuffix,
  });

  final AdminBarChartItem item;
  final double maxValue;
  final bool isPeak;
  final String valueSuffix;

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue <= 0 ? 0.0 : item.value / maxValue;
    final countLabel = item.displayValue ?? item.value.toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(
                item.label,
                style: TextStyle(
                  color: isPeak ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final targetWidth = constraints.maxWidth * ratio;
                  return Stack(
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: targetWidth),
                        duration: const Duration(milliseconds: 520),
                        curve: Curves.easeOutCubic,
                        builder: (context, width, _) {
                          return Container(
                            height: 10,
                            width: math.max(width, isPeak ? 10 : 0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: isPeak
                                  ? AppColors.primaryGradient
                                  : LinearGradient(
                                      colors: [
                                        AppColors.primary
                                            .withValues(alpha: 0.5),
                                        AppColors.primary
                                            .withValues(alpha: 0.22),
                                      ],
                                    ),
                              boxShadow: isPeak
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.28),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 88,
              child: Text(
                '$countLabel$valueSuffix',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: isPeak ? AppColors.primary : AppColors.textMuted,
                  fontWeight: isPeak ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AdminChartGridPainter extends CustomPainter {
  const AdminChartGridPainter({required this.hasData});

  final bool hasData;

  @override
  void paint(Canvas canvas, Size size) {
    if (!hasData) return;

    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.65)
      ..strokeWidth = 1;

    const lines = 4;
    final chartBottom = size.height - 36;
    const chartTop = 16.0;

    for (var i = 1; i <= lines; i++) {
      final y = chartTop + (chartBottom - chartTop) * (i / lines);
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 6.0;
    final distance = (end - start).distance;
    if (distance <= 0) return;
    final direction = (end - start) / distance;
    var drawn = 0.0;

    while (drawn < distance) {
      final next = math.min(drawn + dashWidth, distance);
      canvas.drawLine(
        start + direction * drawn,
        start + direction * next,
        paint,
      );
      drawn += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant AdminChartGridPainter oldDelegate) =>
      oldDelegate.hasData != hasData;
}
