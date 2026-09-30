import { useRef, useState } from 'react';
import {
  CalendarClock,
  Clock,
  Crown,
  ChevronRight,
  Sparkles,
  Flame,
  MapPin,
  ArrowRight,
  Star,
  Quote,
  Scissors,
  Brush,
  Eye,
  Palette,
  Droplet,
  Zap,
} from 'lucide-react';
import type { LucideIcon } from 'lucide-react';
import { motion, useScroll, useTransform, useMotionValue, useSpring } from 'framer-motion';
import { Button } from '@/components/ui/Button';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { AmbientGlow } from '@/components/ui/AmbientGlow';
import { Logo } from '@/components/Logo';
import { useCountdown } from '@/hooks/useCountdown';
import { useShop } from '@/data/shop';
import { formatCurrency } from '@/utils/format';
import type { ViewId } from '@/types';

interface HomeViewProps {
  onNavigate: (view: ViewId) => void;
}

const HERO_IMAGE =
  'https://images.pexels.com/photos/3993293/pexels-photo-3993293.jpeg?auto=compress&cs=tinysrgb&w=1200';
const GROOMING_IMAGE =
  'https://images.pexels.com/photos/3998417/pexels-photo-3998417.jpeg?auto=compress&cs=tinysrgb&w=900';
const TOOLS_IMAGE =
  'https://images.pexels.com/photos/7518712/pexels-photo-7518712.jpeg?auto=compress&cs=tinysrgb&w=900';

const serviceIcons: Record<string, LucideIcon> = {
  scissors: Scissors,
  brush: Brush,
  sparkles: Sparkles,
  eye: Eye,
  palette: Palette,
  droplet: Droplet,
};

export function HomeView({ onNavigate }: HomeViewProps) {
  const { currentUser, upcomingAppointment, barbers, services, pendingReview, submitReview, requestAuth } =
    useShop();
  const greeting = getGreeting();
  const nextAt = upcomingAppointment?.startsAt
    ? new Date(upcomingAppointment.startsAt)
    : new Date();
  const heroRef = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: heroRef,
    offset: ['start start', 'end start'],
  });
  const heroScale = useTransform(scrollYProgress, [0, 1], [1, 1.2]);
  const heroOpacity = useTransform(scrollYProgress, [0, 0.85], [1, 0]);
  const heroTextY = useTransform(scrollYProgress, [0, 1], [0, -80]);
  const countdown = useCountdown(nextAt);

  const loyaltyProgress = Math.min(
    100,
    (currentUser.loyaltyPoints / currentUser.nextRewardAt) * 100,
  );

  return (
    <div className="space-y-10">
      {/* Mobile top bar */}
      <header className="flex items-center justify-between lg:hidden">
        <Logo size="sm" />
        <button type="button" className="relative" onClick={requestAuth}>
          <img
            src={currentUser.avatarUrl}
            alt={currentUser.name}
            className="h-10 w-10 rounded-full border-2 border-gold-500/40 object-cover"
          />
          <span className="absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full border-2 border-ink-950 bg-emerald-500" />
        </button>
      </header>

      {pendingReview && (
        <ReviewPrompt
          serviceName={pendingReview.serviceName}
          barberName={pendingReview.barberName}
          onRate={(rating) => void submitReview(rating)}
        />
      )}

      {/* ===== IMMERSIVE HERO ===== */}
      <section ref={heroRef} className="relative -mx-4 h-[90vh] overflow-hidden lg:-mx-8 lg:h-screen">
        <motion.div style={{ scale: heroScale }} className="absolute inset-0">
          <img src={HERO_IMAGE} alt="Barbearia Moura's" className="h-full w-full object-cover" />
          <div className="absolute inset-0 bg-gradient-to-t from-ink-950 via-ink-950/60 to-ink-950/20" />
          <div className="absolute inset-0 bg-gradient-to-r from-ink-950/70 via-transparent to-transparent" />
        </motion.div>

        <motion.div
          style={{ opacity: heroOpacity, y: heroTextY }}
          className="relative flex h-full flex-col justify-end px-4 pb-12 lg:px-8 lg:pb-20"
        >
          <motion.div
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, ease: [0.22, 1, 0.36, 1] }}
          >
            <div className="flex items-center gap-2.5">
              <span className="flex h-2 w-2 items-center justify-center">
                <span className="h-2 w-2 animate-glow-pulse rounded-full bg-gold-400" />
              </span>
              <p className="text-xs font-medium uppercase tracking-[0.28em] text-gold-400/90">
                {greeting}, {currentUser.firstName}
              </p>
            </div>

            <h1 className="mt-5 max-w-2xl font-display text-[3rem] font-extrabold leading-[0.92] tracking-tightest text-white lg:text-[5.5rem]">
              Pronto para
              <br />
              <span className="text-gradient-gold">o ritual?</span>
            </h1>

            <p className="mt-6 max-w-md text-sm leading-relaxed text-zinc-300/90 lg:text-lg">
              Sua cadeira está reservada. Agende em segundos e eleve cada detalhe do seu visual.
            </p>

            <div className="mt-9 flex flex-col gap-4 sm:flex-row sm:items-center">
              <Button
                size="lg"
                leftIcon={<CalendarClock size={20} />}
                rightIcon={<ArrowRight size={18} />}
                onClick={() => onNavigate('booking')}
              >
                Agendar Meu Horário
              </Button>
              <button
                onClick={() => onNavigate('vip')}
                className="group inline-flex items-center gap-2 px-2 py-2 text-sm font-medium text-zinc-300 transition-colors hover:text-gold-400"
              >
                Explorar Clube VIP
                <ChevronRight size={16} className="transition-transform group-hover:translate-x-1" />
              </button>
            </div>
          </motion.div>
        </motion.div>

        {/* Scroll hint */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1.2 }}
          className="absolute bottom-6 right-4 hidden lg:bottom-8 lg:right-8 lg:block"
        >
          <div className="flex flex-col items-center gap-2 text-zinc-500">
            <span className="text-[10px] uppercase tracking-[0.25em]">Role</span>
            <motion.div
              animate={{ y: [0, 8, 0] }}
              transition={{ duration: 2, repeat: Infinity, ease: 'easeInOut' }}
              className="h-10 w-px bg-gradient-to-b from-gold-500/50 to-transparent"
            />
          </div>
        </motion.div>
      </section>

      {/* ===== LIVE COUNTDOWN ===== */}
      {upcomingAppointment && (
        <motion.section
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: '-60px' }}
          transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
          className="-mt-6"
        >
          <Card glow className="relative overflow-hidden p-5 lg:p-6">
            <AmbientGlow variant="subtle" className="-right-12 -top-12 h-36 w-36" />
            <div className="relative flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <div className="flex items-center gap-3">
                <div className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl bg-gold-500/10 text-gold-400">
                  <Clock size={22} strokeWidth={2.5} />
                </div>
                <div>
                  <p className="text-[10px] font-semibold uppercase tracking-[0.2em] text-gold-500/80">
                    Sua próxima visita
                  </p>
                  <h3 className="font-display text-lg font-bold text-white">
                    {upcomingAppointment.serviceName}
                  </h3>
                  <p className="text-xs text-zinc-400">
                    {upcomingAppointment.date} às {upcomingAppointment.time}
                  </p>
                </div>
              </div>

              <div className="flex items-center gap-2 sm:gap-3">
                <CountdownUnit value={countdown.days} label="dias" />
                <Colon />
                <CountdownUnit value={countdown.hours} label="hrs" />
                <Colon />
                <CountdownUnit value={countdown.minutes} label="min" />
                <Colon />
                <CountdownUnit value={countdown.seconds} label="seg" />
              </div>
            </div>
          </Card>
        </motion.section>
      )}

      {/* ===== HOLOGRAPHIC MEMBERSHIP CARD ===== */}
      <motion.section
        initial={{ opacity: 0, y: 30 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, margin: '-60px' }}
        transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
        onClick={() => onNavigate('vip')}
      >
        <TiltCard>
          <div className="group relative cursor-pointer">
            <div className="absolute -inset-0.5 rounded-[1.75rem] bg-gradient-to-br from-gold-500/25 via-gold-500/5 to-gold-500/15 opacity-50 blur-2xl transition-opacity duration-500 group-hover:opacity-90" />

            <div className="relative overflow-hidden rounded-[1.75rem] border border-gold-500/25 bg-gradient-to-br from-ink-850 via-ink-900 to-black p-6 lg:p-8">
              <div className="grain absolute inset-0 rounded-[1.75rem]" />
              <AmbientGlow className="-right-14 -top-14 h-44 w-44" />

              {/* Holographic shimmer */}
              <div
                className="pointer-events-none absolute inset-0 opacity-30 transition-opacity duration-300 group-hover:opacity-50"
                style={{
                  background:
                    'linear-gradient(115deg, transparent 30%, rgba(234,179,8,0.08) 45%, rgba(253,224,71,0.12) 50%, rgba(234,179,8,0.08) 55%, transparent 70%)',
                }}
              />

              <div className="relative flex items-start justify-between">
                <div>
                  <p className="text-[10px] font-semibold uppercase tracking-[0.28em] text-gold-500/70">
                    Moura&apos;s · Membro
                  </p>
                  <div className="mt-3 flex items-center gap-2.5">
                    <Crown size={20} className="text-gold-400" strokeWidth={2.5} />
                    <h3 className="font-display text-2xl font-bold text-white">{currentUser.membershipTier}</h3>
                  </div>
                  <p className="mt-1.5 text-xs text-zinc-500">
                    {currentUser.name} · Desde {currentUser.memberSince}
                  </p>
                </div>
                <div className="text-right">
                  <p className="font-display text-4xl font-extrabold tracking-tight text-gradient-gold">
                    {currentUser.loyaltyPoints}
                  </p>
                  <p className="text-[10px] uppercase tracking-wide text-zinc-500">pontos</p>
                </div>
              </div>

              <div className="relative mt-7">
                <div className="flex items-center justify-between text-xs">
                  <span className="text-zinc-400">Próxima recompensa</span>
                  <span className="font-semibold text-gold-400">
                    {currentUser.nextRewardAt - currentUser.loyaltyPoints} pts restantes
                  </span>
                </div>
                <div className="mt-2 h-1.5 overflow-hidden rounded-full bg-zinc-800">
                  <motion.div
                    initial={{ width: 0 }}
                    whileInView={{ width: `${loyaltyProgress}%` }}
                    viewport={{ once: true }}
                    transition={{ duration: 1.2, ease: 'easeOut' }}
                    className="h-full rounded-full bg-gradient-gold"
                  />
                </div>
              </div>

              <div className="relative mt-6 flex items-center justify-between">
                <div className="flex gap-5">
                  <MiniStat icon={<Flame size={14} />} label="Visitas" value={String(currentUser.visitsThisMonth)} />
                  <MiniStat icon={<Sparkles size={14} />} label="Nível" value="Ouro" />
                </div>
                <ChevronRight size={18} className="text-gold-400 transition-transform group-hover:translate-x-1" />
              </div>
            </div>
          </div>
        </TiltCard>
      </motion.section>

      {/* ===== SERVICES EDITORIAL ===== */}
      <motion.section
        initial={{ opacity: 0, y: 30 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, margin: '-60px' }}
        transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
      >
        <div className="mb-5 flex items-end justify-between">
          <div>
            <p className="mb-1.5 text-[11px] font-semibold uppercase tracking-[0.22em] text-gold-500/80">
              O Cardápio
            </p>
            <h2 className="font-display text-2xl font-bold tracking-tight text-white lg:text-3xl">
              Serviços
            </h2>
          </div>
          <button
            onClick={() => onNavigate('booking')}
            className="flex items-center gap-1 text-sm text-gold-400 transition-colors hover:text-gold-300"
          >
            Agendar <ChevronRight size={16} />
          </button>
        </div>

        <div className="grid grid-cols-2 gap-3 lg:grid-cols-3">
          {services.slice(0, 6).map((svc, idx) => {
            const Icon = serviceIcons[svc.icon] ?? Scissors;
            return (
              <motion.button
                key={svc.id}
                onClick={() => onNavigate('booking')}
                initial={{ opacity: 0, scale: 0.92 }}
                whileInView={{ opacity: 1, scale: 1 }}
                viewport={{ once: true }}
                transition={{ delay: idx * 0.06, duration: 0.4 }}
                whileTap={{ scale: 0.97 }}
              >
                <Card interactive className="group h-full p-5">
                  <span className="grid h-11 w-11 place-items-center rounded-xl bg-zinc-800 text-gold-400 transition-colors group-hover:bg-gradient-gold group-hover:text-zinc-950">
                    <Icon size={20} strokeWidth={2} />
                  </span>
                  <h3 className="mt-4 font-display text-base font-bold text-white">{svc.name}</h3>
                  <p className="mt-1 line-clamp-2 text-xs text-zinc-500">{svc.description}</p>
                  <div className="mt-3 flex items-center justify-between">
                    <span className="text-sm font-bold text-gold-400">{formatCurrency(svc.price)}</span>
                    <span className="flex items-center gap-1 text-[11px] text-zinc-500">
                      <Clock size={11} /> {svc.durationMin}min
                    </span>
                  </div>
                </Card>
              </motion.button>
            );
          })}
        </div>
      </motion.section>

      {/* ===== BARBERS CARROUSEL ===== */}
      <motion.section
        initial={{ opacity: 0, y: 30 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, margin: '-60px' }}
        transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
      >
        <div className="mb-5 flex items-end justify-between">
          <div>
            <p className="mb-1.5 text-[11px] font-semibold uppercase tracking-[0.22em] text-gold-500/80">
              Os Mestres
            </p>
            <h2 className="font-display text-2xl font-bold tracking-tight text-white lg:text-3xl">
              Nossa Equipe
            </h2>
          </div>
          <button
            onClick={() => onNavigate('booking')}
            className="flex items-center gap-1 text-sm text-gold-400 transition-colors hover:text-gold-300"
          >
            Ver todos <ChevronRight size={16} />
          </button>
        </div>

        <div className="no-scrollbar -mx-4 flex gap-3.5 overflow-x-auto px-4 pb-2 lg:mx-0 lg:px-0">
          {barbers.map((brb, idx) => (
            <motion.button
              key={brb.id}
              onClick={() => onNavigate('booking')}
              initial={{ opacity: 0, scale: 0.92 }}
              whileInView={{ opacity: 1, scale: 1 }}
              viewport={{ once: true }}
              transition={{ delay: idx * 0.08, duration: 0.4 }}
              whileTap={{ scale: 0.97 }}
              className="group w-40 shrink-0 text-left lg:w-44"
            >
              <div className="relative overflow-hidden rounded-2xl border border-zinc-800/60">
                <img
                  src={brb.avatarUrl}
                  alt={brb.name}
                  className="aspect-[3/4] w-full object-cover transition-transform duration-500 group-hover:scale-110"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-ink-950 via-ink-950/20 to-transparent" />
                <div className="absolute right-2 top-2 flex items-center gap-1 rounded-full bg-ink-950/70 px-2 py-1 backdrop-blur-sm">
                  <Star size={11} className="fill-gold-400 text-gold-400" />
                  <span className="text-xs font-semibold text-gold-400">{brb.rating}</span>
                </div>
                <div className="absolute bottom-0 left-0 right-0 p-3.5">
                  <h3 className="truncate font-display text-sm font-bold text-white">{brb.name}</h3>
                  <p className="truncate text-[11px] text-zinc-400">{brb.role}</p>
                  <div className="mt-1.5 flex flex-wrap gap-1">
                    {brb.specialties.slice(0, 2).map((sp) => (
                      <span key={sp} className="rounded-md bg-gold-500/10 px-1.5 py-0.5 text-[9px] text-gold-400">
                        {sp}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            </motion.button>
          ))}
        </div>
      </motion.section>

      {/* ===== ATMOSPHERE SPLIT BANNER ===== */}
      <motion.section
        initial={{ opacity: 0, y: 30 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, margin: '-60px' }}
        transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
        className="grid gap-4 lg:grid-cols-2"
      >
        {/* Grooming quote */}
        <div className="relative overflow-hidden rounded-[2rem] border border-zinc-800/60">
          <img src={GROOMING_IMAGE} alt="Ritual de grooming" className="h-72 w-full object-cover lg:h-full" />
          <div className="absolute inset-0 bg-gradient-to-t from-ink-950 via-ink-950/50 to-transparent" />
          <div className="absolute inset-0 flex flex-col justify-end p-6 lg:p-7">
            <Quote size={26} className="text-gold-500/40" />
            <p className="mt-2 font-display text-lg font-semibold leading-snug text-white">
              &ldquo;Um corte não é estética. É a forma como o mundo te vê primeiro.&rdquo;
            </p>
            <p className="mt-2 text-sm text-gold-500/80">— Murilo Moura, Fundador</p>
          </div>
        </div>

        {/* Tools / CTA */}
        <div className="relative overflow-hidden rounded-[2rem] border border-zinc-800/60">
          <img src={TOOLS_IMAGE} alt="Ferramentas premium" className="h-72 w-full object-cover lg:h-full" />
          <div className="absolute inset-0 bg-gradient-to-t from-ink-950 via-ink-950/50 to-transparent" />
          <div className="absolute inset-0 flex flex-col justify-end p-6 lg:p-7">
            <Zap size={26} className="text-gold-500/40" />
            <p className="mt-2 font-display text-lg font-semibold leading-snug text-white">
              Ferramentas premium, técnica refinada.
            </p>
            <p className="mt-1 text-sm text-zinc-400">Cada detalhe pensado para você.</p>
            <div className="mt-4">
              <Button
                variant="outline"
                size="sm"
                leftIcon={<MapPin size={16} />}
                onClick={() => onNavigate('booking')}
              >
                Visite a Barbearia
              </Button>
            </div>
          </div>
        </div>
      </motion.section>

      {/* ===== QUICK STATS ===== */}
      <motion.section
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ duration: 0.5 }}
        className="grid grid-cols-3 gap-3"
      >
        <StatPill icon={<Sparkles size={18} />} label="Pontos" value={String(currentUser.loyaltyPoints)} />
        <StatPill icon={<Flame size={18} />} label="Visitas" value={String(currentUser.visitsThisMonth)} />
        <StatPill icon={<Crown size={18} />} label="Plano" value="Ultra" />
      </motion.section>
    </div>
  );
}

// ===== Sub-components =====

function CountdownUnit({ value, label }: { value: number; label: string }) {
  return (
    <div className="flex flex-col items-center">
      <motion.span
        key={value}
        initial={{ y: -8, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ duration: 0.3 }}
        className="grid h-12 w-12 place-items-center rounded-xl border border-zinc-800 bg-ink-900 font-display text-xl font-bold text-gold-400 lg:h-14 lg:w-14 lg:text-2xl"
      >
        {String(value).padStart(2, '0')}
      </motion.span>
      <span className="mt-1 text-[9px] uppercase tracking-wide text-zinc-500">{label}</span>
    </div>
  );
}

function Colon() {
  return <span className="font-display text-xl font-bold text-zinc-700 lg:text-2xl">:</span>;
}

function MiniStat({
  icon,
  label,
  value,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
}) {
  return (
    <div className="flex items-center gap-1.5">
      <span className="text-gold-400">{icon}</span>
      <span className="text-xs text-zinc-400">{label}</span>
      <span className="text-xs font-semibold text-white">{value}</span>
    </div>
  );
}

function StatPill({
  icon,
  label,
  value,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
}) {
  return (
    <Card className="flex flex-col items-center gap-1.5 p-4">
      <span className="text-gold-400">{icon}</span>
      <span className="font-display text-lg font-bold text-white">{value}</span>
      <span className="text-[10px] uppercase tracking-wide text-zinc-500">{label}</span>
    </Card>
  );
}

// 3D tilt wrapper
function TiltCard({ children }: { children: React.ReactNode }) {
  const ref = useRef<HTMLDivElement>(null);
  const x = useMotionValue(0);
  const y = useMotionValue(0);
  const rotateX = useSpring(useTransform(y, [-50, 50], [8, -8]), { stiffness: 200, damping: 20 });
  const rotateY = useSpring(useTransform(x, [-50, 50], [-8, 8]), { stiffness: 200, damping: 20 });

  function handleMouse(e: React.MouseEvent<HTMLDivElement>) {
    const rect = ref.current?.getBoundingClientRect();
    if (!rect) return;
    const px = ((e.clientX - rect.left) / rect.width - 0.5) * 100;
    const py = ((e.clientY - rect.top) / rect.height - 0.5) * 100;
    x.set(px);
    y.set(py);
  }

  function handleLeave() {
    x.set(0);
    y.set(0);
  }

  return (
    <motion.div
      ref={ref}
      onMouseMove={handleMouse}
      onMouseLeave={handleLeave}
      style={{ rotateX, rotateY, transformPerspective: 800 }}
      className="[transform-style:preserve-3d]"
    >
      {children}
    </motion.div>
  );
}

function getGreeting(): string {
  const h = new Date().getHours();
  if (h < 12) return 'Bom dia';
  if (h < 18) return 'Boa tarde';
  return 'Boa noite';
}

function ReviewPrompt({
  serviceName,
  barberName,
  onRate,
}: {
  serviceName: string;
  barberName: string;
  onRate: (rating: number) => void;
}) {
  return (
    <div className="rounded-2xl border border-gold-500/30 bg-ink-900/80 p-4">
      <p className="text-sm text-zinc-200">
        Como foi {serviceName} com {barberName}?
      </p>
      <div className="mt-3 flex gap-2">
        {[1, 2, 3, 4, 5].map((rating) => (
          <button
            key={rating}
            type="button"
            onClick={() => onRate(rating)}
            className="rounded-xl border border-zinc-700 px-3 py-2 text-sm text-gold-400 hover:border-gold-500"
          >
            {rating}
          </button>
        ))}
      </div>
    </div>
  );
}
