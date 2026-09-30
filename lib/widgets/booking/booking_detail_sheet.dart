import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/supabase_service.dart';
import '../../models/booking.dart';
import '../../models/booking_status.dart';
import '../customer/atelier_shell.dart';
import '../customer/customer_dialog.dart';
import '../screen_background.dart';

class BookingDetailSheet extends StatefulWidget {
  const BookingDetailSheet({
    super.key,
    required this.booking,
    required this.onChanged,
    required this.onReschedule,
  });

  final Booking booking;
  final VoidCallback onChanged;
  final VoidCallback onReschedule;

  static Future<void> show(
    BuildContext context, {
    required Booking booking,
    required VoidCallback onChanged,
    required VoidCallback onReschedule,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingDetailSheet(
        booking: booking,
        onChanged: onChanged,
        onReschedule: onReschedule,
      ),
    );
  }

  @override
  State<BookingDetailSheet> createState() => _BookingDetailSheetState();
}

class _BookingDetailSheetState extends State<BookingDetailSheet> {
  bool _isCancelling = false;

  bool get _isUpcoming =>
      widget.booking.status != BookingStatus.cancelled &&
      widget.booking.dateTime.isAfter(DateTime.now());

  Future<void> _cancel() async {
    final confirmed = await showCustomerDialog(
      context: context,
      title: 'Cancelar agendamento',
      message:
          'Seu horário de ${widget.booking.serviceName} com '
          '${widget.booking.barberName} em ${formatDate(widget.booking.dateTime)} '
          'às ${formatTime(widget.booking.dateTime)} será liberado.',
      cancelLabel: 'Manter horário',
      confirmLabel: 'Cancelar agendamento',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      await SupabaseService.cancelUserBooking(widget.booking.id);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onChanged();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Agendamento cancelado.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_friendlyError(error)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.contains('PostgrestException')) {
      final match = RegExp(r'message: ([^,}]+)').firstMatch(message);
      if (match != null) return match.group(1)!.trim();
    }
    return message.isEmpty
        ? 'Não foi possível cancelar. Tente novamente.'
        : message;
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.border),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  booking.serviceName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'com ${booking.barberName}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.calendar_month_rounded,
                  label: 'Data e hora',
                  value:
                      '${formatDate(booking.dateTime)} · ${formatTime(booking.dateTime)}',
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  icon: Icons.payments_outlined,
                  label: 'Valor',
                  value: booking.coveredByPlan
                      ? 'R\$ 0,00 · Coberto pelo VIP'
                      : formatCurrency(booking.price),
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  icon: Icons.info_outline_rounded,
                  label: 'Status',
                  value: booking.status.label,
                ),
                if (_isUpcoming) ...[
                  const SizedBox(height: 24),
                  AtelierGoldButton(
                    expand: true,
                    label: 'Reagendar',
                    leading: const Icon(
                      Icons.event_repeat_rounded,
                      size: 18,
                      color: AppColors.background,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onReschedule();
                    },
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _isCancelling ? null : _cancel,
                    child: _isCancelling
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Cancelar agendamento',
                            style: TextStyle(color: AppColors.error),
                          ),
                  ),
                ],
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryBright),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
