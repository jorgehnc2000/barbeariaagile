import { useEffect, useMemo, useState } from 'react';
import {
  Scissors,
  Brush,
  Sparkles,
  Eye,
  Palette,
  Droplet,
  Star,
  Clock,
  Check,
  CalendarPlus,
  ChevronLeft,
  ChevronRight,
  CalendarDays,
  User,
  PartyPopper,
} from 'lucide-react';
import type { LucideIcon } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { Button } from '@/components/ui/Button';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { AmbientGlow } from '@/components/ui/AmbientGlow';
import { useShop } from '@/data/shop';
import { getNextFourteenDays, isPastSlot } from '@/data/dates';
import {
  formatCurrency,
  formatDayShort,
  formatDayNumber,
  formatMonthShort,
  isToday,
} from '@/utils/format';
import type { Service, Barber, ViewId } from '@/types';

const iconMap: Record<string, LucideIcon> = {
  scissors: Scissors,
  brush: Brush,
  sparkles: Sparkles,
  eye: Eye,
  palette: Palette,
  droplet: Droplet,
};

interface BookingViewProps {
  onNavigate: (view: ViewId) => void;
}

type Step = 0 | 1 | 2 | 3;
const stepLabels = ['Serviço', 'Barbeiro', 'Data & Hora', 'Confirme'];

export function BookingView({ onNavigate }: BookingViewProps) {
  const { services, barbers, timeSlots, occupiedTimes, loadOccupied, createBooking } = useShop();
  const [step, setStep] = useState<Step>(0);
  const [selectedService, setSelectedService] = useState<Service | null>(null);
  const [selectedBarber, setSelectedBarber] = useState<Barber | null>(null);
  const [selectedDate, setSelectedDate] = useState<Date | null>(null);
  const [selectedTime, setSelectedTime] = useState<string | null>(null);
  const [confirmed, setConfirmed] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [confirmError, setConfirmError] = useState<string | null>(null);

  useEffect(() => {
    if (!selectedBarber || !selectedDate) return;
    void loadOccupied(selectedBarber.id, selectedDate);
  }, [selectedBarber, selectedDate, loadOccupied]);

  const days = useMemo(() => getNextFourteenDays(), []);
  const totalPrice = selectedService?.price ?? 0;

  const canAdvance =
    (step === 0 && selectedService) ||
    (step === 1 && selectedBarber) ||
    (step === 2 && selectedDate && selectedTime) ||
    step === 3;

  function next() {
    if (step < 3) setStep((s) => (s + 1) as Step);
    else handleConfirm();
  }
  function back() {
    if (step > 0) setStep((s) => (s - 1) as Step);
    else onNavigate('home');
  }

  async function handleConfirm() {
    if (!selectedService || !selectedBarber || !selectedDate || !selectedTime || submitting) return;
    const [hour, minute] = selectedTime.split(':').map(Number);
    const startAt = new Date(
      selectedDate.getFullYear(),
      selectedDate.getMonth(),
      selectedDate.getDate(),
      hour,
      minute,
      0,
      0,
    );
    setSubmitting(true);
    setConfirmError(null);
    try {
      await createBooking({
        barberId: selectedBarber.id,
        serviceId: selectedService.id,
        startAt,
        durationMin: selectedService.durationMin,
      });
      setConfirmed(true);
      setTimeout(() => onNavigate('home'), 2200);
    } catch (cause) {
      setConfirmError(cause instanceof Error ? cause.message : 'Não foi possível agendar.');
    } finally {
      setSubmitting(false);
    }
  }

  if (confirmed) {
    return (
      <ConfirmedState
        service={selectedService!}
        barber={selectedBarber!}
        date={selectedDate!}
        time={selectedTime!}
      />
    );
  }

  return (
    <div className="space-y-6 pb-44 lg:pb-36">
      {/* Header */}
      <header className="flex items-center gap-3">
        <button
          onClick={back}
          className="grid h-10 w-10 place-items-center rounded-xl border border-zinc-800 bg-ink-850 text-zinc-300 transition-colors hover:border-gold-500/40 hover:text-gold-400"
        >
          <ChevronLeft size={20} />
        </button>
        <div>
          <h1 className="font-display text-2xl font-bold tracking-tight text-white lg:text-3xl">
            Agendar
          </h1>
          <p className="text-sm text-zinc-400">Sua jornada de estilo em poucos toques.</p>
        </div>
      </header>

      {/* Step progress */}
      <div className="flex items-center gap-2">
        {stepLabels.map((label, idx) => {
          const done = idx < step;
          const active = idx === step;
          return (
            <div key={label} className="flex flex-1 flex-col gap-1.5">
              <div className="flex items-center gap-2">
                <motion.div
                  animate={{
                    backgroundColor: done || active ? '#eab308' : '#27272a',
                    color: done || active ? '#09090b' : '#71717a',
                  }}
                  className="grid h-7 w-7 shrink-0 place-items-center rounded-full text-xs font-bold"
                >
                  {done ? <Check size={14} strokeWidth={3} /> : idx + 1}
                </motion.div>
                <div className="h-1 flex-1 overflow-hidden rounded-full bg-zinc-800">
                  <motion.div
                    initial={false}
                    animate={{ width: done ? '100%' : active ? '50%' : '0%' }}
                    transition={{ duration: 0.4, ease: 'easeOut' }}
                    className="h-full rounded-full bg-gradient-gold"
                  />
                </div>
              </div>
              <span
                className={[
                  'text-[10px] font-medium transition-colors',
                  active ? 'text-gold-400' : done ? 'text-zinc-400' : 'text-zinc-600',
                ].join(' ')}
              >
                {label}
              </span>
            </div>
          );
        })}
      </div>

      {/* Step content */}
      <AnimatePresence mode="wait">
        {/* Step 0 — Service */}
        {step === 0 && (
          <motion.div
            key="step-0"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            transition={{ duration: 0.3 }}
            className="grid items-stretch gap-3 sm:grid-cols-2"
          >
            {services.map((svc) => {
              const Icon = iconMap[svc.icon] ?? Scissors;
              const active = selectedService?.id === svc.id;
              return (
                <button key={svc.id} onClick={() => setSelectedService(svc)} className="flex h-full w-full text-left">
                  <Card
                    interactive
                    className={[
                      'flex h-full w-full items-center gap-4 p-4 transition-colors',
                      active ? 'border-gold-500/60 bg-gold-500/[0.06]' : '',
                    ].join(' ')}
                  >
                    <span
                      className={[
                        'grid h-12 w-12 shrink-0 place-items-center rounded-xl transition-colors',
                        active ? 'bg-gradient-gold text-zinc-950' : 'bg-zinc-800 text-gold-400',
                      ].join(' ')}
                    >
                      <Icon size={22} strokeWidth={2} />
                    </span>
                    <div className="flex min-h-[4.25rem] min-w-0 flex-1 flex-col justify-center text-left">
                      <h3 className="truncate font-semibold text-white">{svc.name}</h3>
                      <p className="min-h-4 truncate text-xs text-zinc-400">{svc.description || '\u00a0'}</p>
                      <div className="mt-1.5 flex items-center gap-3">
                        <span className="shrink-0 text-sm font-bold text-gold-400">
                          {formatCurrency(svc.price)}
                        </span>
                        <span className="flex shrink-0 items-center gap-1 text-xs text-zinc-500">
                          <Clock size={12} /> {svc.durationMin} min
                        </span>
                      </div>
                    </div>
                    {active && (
                      <motion.span
                        initial={{ scale: 0 }}
                        animate={{ scale: 1 }}
                        className="grid h-6 w-6 place-items-center rounded-full bg-gold-500 text-zinc-950"
                      >
                        <Check size={14} strokeWidth={3} />
                      </motion.span>
                    )}
                  </Card>
                </button>
              );
            })}
          </motion.div>
        )}

        {/* Step 1 — Barber */}
        {step === 1 && (
          <motion.div
            key="step-1"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            transition={{ duration: 0.3 }}
            className="grid gap-3 sm:grid-cols-2"
          >
            {barbers.map((brb) => {
              const active = selectedBarber?.id === brb.id;
              return (
                <button key={brb.id} onClick={() => setSelectedBarber(brb)}>
                  <Card
                    interactive
                    className={[
                      'flex items-center gap-4 p-4 transition-colors',
                      active ? 'border-gold-500/60 bg-gold-500/[0.06]' : '',
                    ].join(' ')}
                  >
                    <img
                      src={brb.avatarUrl}
                      alt={brb.name}
                      className={[
                        'h-14 w-14 rounded-xl object-cover transition-all',
                        active ? 'ring-2 ring-gold-500' : 'ring-1 ring-zinc-700',
                      ].join(' ')}
                    />
                    <div className="flex-1 text-left">
                      <h3 className="font-semibold text-white">{brb.name}</h3>
                      <p className="text-xs text-zinc-400">{brb.role}</p>
                      <div className="mt-1.5 flex flex-wrap items-center gap-1.5">
                        <span className="flex items-center gap-1">
                          <Star size={13} className="fill-gold-400 text-gold-400" />
                          <span className="text-sm font-medium text-gold-400">{brb.rating}</span>
                          <span className="text-xs text-zinc-500">({brb.reviews})</span>
                        </span>
                        {brb.specialties.map((sp) => (
                          <span
                            key={sp}
                            className="rounded-md bg-zinc-800/80 px-2 py-0.5 text-[10px] text-zinc-400"
                          >
                            {sp}
                          </span>
                        ))}
                      </div>
                    </div>
                    {active && (
                      <motion.span
                        initial={{ scale: 0 }}
                        animate={{ scale: 1 }}
                        className="grid h-6 w-6 place-items-center rounded-full bg-gold-500 text-zinc-950"
                      >
                        <Check size={14} strokeWidth={3} />
                      </motion.span>
                    )}
                  </Card>
                </button>
              );
            })}
          </motion.div>
        )}

        {/* Step 2 — Date & Time */}
        {step === 2 && (
          <motion.div
            key="step-2"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            transition={{ duration: 0.3 }}
            className="space-y-6"
          >
            <div>
              <div className="mb-3 flex items-center gap-2">
                <CalendarDays size={18} className="text-gold-400" />
                <h2 className="font-display text-lg font-semibold text-white">Escolha o dia</h2>
              </div>
              <div className="no-scrollbar -mx-1 flex gap-2.5 overflow-x-auto px-1 pb-2">
                {days.map((day) => {
                  const active = selectedDate && day.toDateString() === selectedDate.toDateString();
                  const today = isToday(day);
                  return (
                    <button
                      key={day.toISOString()}
                      onClick={() => setSelectedDate(day)}
                      className={[
                        'flex min-w-[70px] flex-col items-center gap-1 rounded-2xl border px-3 py-3.5 transition-all',
                        active
                          ? 'border-gold-500 bg-gold-500/10'
                          : 'border-zinc-800 bg-ink-850 hover:border-zinc-700',
                      ].join(' ')}
                    >
                      <span
                        className={[
                          'text-[11px] uppercase tracking-wide',
                          active ? 'text-gold-400' : 'text-zinc-500',
                        ].join(' ')}
                      >
                        {formatDayShort(day)}
                      </span>
                      <span
                        className={[
                          'font-display text-xl font-bold',
                          active ? 'text-gold-400' : 'text-white',
                        ].join(' ')}
                      >
                        {formatDayNumber(day)}
                      </span>
                      <span
                        className={[
                          'text-[10px]',
                          today ? 'font-bold text-gold-400' : active ? 'text-gold-500/70' : 'text-zinc-600',
                        ].join(' ')}
                      >
                        {today ? 'Hoje' : formatMonthShort(day)}
                      </span>
                    </button>
                  );
                })}
              </div>
            </div>

            <div>
              <div className="mb-3 flex items-center gap-2">
                <Clock size={18} className="text-gold-400" />
                <h2 className="font-display text-lg font-semibold text-white">Horários disponíveis</h2>
              </div>
              {!selectedDate ? (
                <Card className="p-8 text-center">
                  <p className="text-sm text-zinc-400">Selecione um dia para ver os horários.</p>
                </Card>
              ) : (
                <div className="grid grid-cols-3 gap-2.5 sm:grid-cols-4 lg:grid-cols-6">
                  {timeSlots.map((time) => {
                    const available =
                      Boolean(selectedDate) &&
                      !occupiedTimes.has(time) &&
                      !isPastSlot(selectedDate!, time);
                    const active = selectedTime === time;
                    return (
                      <button
                        key={time}
                        disabled={!available}
                        onClick={() => setSelectedTime(time)}
                        className={[
                          'rounded-xl border py-3 text-sm font-medium transition-all',
                          !available
                            ? 'cursor-not-allowed border-zinc-800/40 bg-ink-900/40 text-zinc-600 line-through'
                            : active
                              ? 'border-gold-500 bg-gradient-gold text-zinc-950 shadow-gold'
                              : 'border-zinc-800 bg-ink-850 text-zinc-200 hover:border-gold-500/40 hover:text-gold-400',
                        ].join(' ')}
                      >
                        {time}
                      </button>
                    );
                  })}
                </div>
              )}
            </div>
          </motion.div>
        )}

        {/* Step 3 — Confirm */}
        {step === 3 && (
          <motion.div
            key="step-3"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            transition={{ duration: 0.3 }}
          >
            <Card glow className="overflow-hidden p-6">
              <div className="mb-4 flex items-center gap-2">
                <Check size={18} className="text-gold-400" />
                <h2 className="font-display text-lg font-semibold text-white">Revise seu agendamento</h2>
              </div>
              <div className="space-y-4">
                <ConfirmRow icon={<Scissors size={16} />} label="Serviço" value={selectedService?.name ?? '—'} />
                <ConfirmRow
                  icon={<User size={16} />}
                  label="Barbeiro"
                  value={selectedBarber?.name ?? '—'}
                />
                <ConfirmRow
                  icon={<CalendarDays size={16} />}
                  label="Data"
                  value={
                    selectedDate
                      ? `${formatDayShort(selectedDate)}, ${formatDayNumber(selectedDate)} ${formatMonthShort(selectedDate)}`
                      : '—'
                  }
                />
                <ConfirmRow icon={<Clock size={16} />} label="Hora" value={selectedTime ?? '—'} />
                <div className="flex items-center justify-between border-t border-zinc-800/60 pt-4">
                  <span className="text-sm text-zinc-400">Total</span>
                  <span className="font-display text-2xl font-bold text-gradient-gold">
                    {formatCurrency(totalPrice)}
                  </span>
                </div>
              </div>
            </Card>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Fixed action bar */}
      <div className="fixed bottom-20 left-0 right-0 z-40 lg:bottom-0">
        <div className="mx-auto max-w-5xl px-4 lg:px-8">
          {confirmError && (
            <p className="mb-3 rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-200">
              {confirmError}
            </p>
          )}
          <div className="glass-strong mb-4 rounded-2xl border border-zinc-800/50 p-4 shadow-2xl lg:mb-6">
            <div className="flex items-center justify-between gap-4">
              <div className="min-w-0">
                <p className="text-[10px] uppercase tracking-wide text-zinc-500">
                  {step < 3 ? 'Selecionado' : 'Total'}
                </p>
                <p className="truncate text-sm font-medium text-zinc-200">
                  {step === 0 && (selectedService?.name ?? 'Escolha um serviço')}
                  {step === 1 && (selectedBarber?.name ?? 'Escolha um barbeiro')}
                  {step === 2 &&
                    (selectedDate
                      ? `${formatDayShort(selectedDate)}, ${formatDayNumber(selectedDate)} ${formatMonthShort(selectedDate)}${selectedTime ? ` · ${selectedTime}` : ''}`
                      : 'Escolha data e hora')}
                  {step === 3 && selectedService?.name}
                </p>
              </div>
              <div className="flex shrink-0 items-center gap-3">
                {step < 3 && (
                  <span className="hidden text-right sm:block">
                    <span className="block text-[10px] uppercase tracking-wide text-zinc-500">Valor</span>
                    <span className="font-display text-lg font-bold text-gold-400">
                      {formatCurrency(totalPrice)}
                    </span>
                  </span>
                )}
                <Button
                  onClick={next}
                  disabled={!canAdvance || submitting}
                  rightIcon={step < 3 ? <ChevronRight size={18} /> : undefined}
                  className="shrink-0"
                >
                  {submitting ? 'Confirmando…' : step < 3 ? 'Continuar' : 'Confirmar Agendamento'}
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function ConfirmRow({
  icon,
  label,
  value,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
}) {
  return (
    <div className="flex items-center justify-between">
      <span className="flex items-center gap-2.5 text-sm text-zinc-400">
        <span className="grid h-8 w-8 place-items-center rounded-lg bg-zinc-800/80 text-gold-400">
          {icon}
        </span>
        {label}
      </span>
      <span className="text-sm font-medium text-zinc-100">{value}</span>
    </div>
  );
}

function ConfirmedState({
  service,
  barber,
  date,
  time,
}: {
  service: Service;
  barber: Barber;
  date: Date;
  time: string;
}) {
  return (
    <div className="relative flex min-h-[65vh] flex-col items-center justify-center overflow-hidden text-center">
      <AmbientGlow className="top-1/4 h-64 w-64" />
      <motion.div
        initial={{ scale: 0, rotate: -30 }}
        animate={{ scale: 1, rotate: 0 }}
        transition={{ type: 'spring', stiffness: 260, damping: 18 }}
        className="relative grid h-24 w-24 place-items-center rounded-full bg-gradient-gold shadow-gold-lg"
      >
        <PartyPopper size={44} className="text-zinc-950" strokeWidth={2.5} />
      </motion.div>
      <motion.h2
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
        className="mt-6 font-display text-2xl font-bold tracking-tight text-white"
      >
        Agendamento Confirmado!
      </motion.h2>
      <motion.p
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.3 }}
        className="mt-2 text-sm text-zinc-400"
      >
        {service.name} com {barber.name}
      </motion.p>
      <motion.p
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.35 }}
        className="text-sm text-zinc-400"
      >
        {formatDayShort(date)}, {formatDayNumber(date)} {formatMonthShort(date)} às {time}
      </motion.p>
      <motion.div
        initial={{ opacity: 0, scale: 0.8 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ delay: 0.45 }}
        className="mt-4"
      >
        <Badge variant="gold" icon={<Check size={12} />}>
          {formatCurrency(service.price)}
        </Badge>
      </motion.div>
    </div>
  );
}
