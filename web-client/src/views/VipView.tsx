import { useEffect, useState } from 'react';
import { Crown, Check, Sparkles, Zap, Star, ChevronLeft, Shield, Infinity as InfinityIcon } from 'lucide-react';
import { motion } from 'framer-motion';
import { Button } from '@/components/ui/Button';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { AmbientGlow } from '@/components/ui/AmbientGlow';
import { useShop } from '@/data/shop';
import { formatCurrency } from '@/utils/format';
import type { ViewId, VipPlan } from '@/types';

interface VipViewProps {
  onNavigate: (view: ViewId) => void;
}

export function VipView({ onNavigate }: VipViewProps) {
  const {
    plans: vipPlans,
    currentUser,
    session,
    requestAuth,
    plansMessage,
    vipEnabled,
    subscribePlan,
  } = useShop();
  const [selected, setSelected] = useState<string>('');
  const [cardholder, setCardholder] = useState('');
  const [cpf, setCpf] = useState('');
  const [cardNumber, setCardNumber] = useState('');
  const [expiry, setExpiry] = useState('');
  const [cvv, setCvv] = useState('');
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState<string | null>(null);
  const [done, setDone] = useState(false);
  useEffect(() => {
    if (selected) return;
    if (currentUser.membershipTierId) {
      setSelected(currentUser.membershipTierId);
      return;
    }
    if (vipPlans[0]) setSelected(vipPlans[0].id);
  }, [selected, currentUser.membershipTierId, vipPlans]);
  const isCurrent = Boolean(selected) && selected === currentUser.membershipTierId;
  const selectedPlan = vipPlans.find((plan) => plan.id === selected);

  async function pay() {
    if (!selectedPlan || isCurrent || busy) return;
    if (!session) {
      requestAuth();
      return;
    }
    setBusy(true);
    setNotice(null);
    setDone(false);
    try {
      await subscribePlan({
        planId: selectedPlan.id,
        cardNumber,
        expiry,
        cvv,
        cardholder,
        cpf,
      });
      setCardNumber('');
      setCvv('');
      setCpf('');
      setDone(true);
      setNotice('Assinatura enviada ao Mercado Pago.');
    } catch (cause) {
      setNotice(cause instanceof Error ? cause.message : 'Não foi possível assinar.');
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <header className="flex items-center gap-3">
        <button
          onClick={() => onNavigate('home')}
          className="grid h-10 w-10 place-items-center rounded-xl border border-zinc-800 bg-ink-850 text-zinc-300 transition-colors hover:border-gold-500/40 hover:text-gold-400 lg:hidden"
        >
          <ChevronLeft size={20} />
        </button>
        <div className="flex-1">
          <p className="text-[11px] font-semibold uppercase tracking-[0.2em] text-gold-500/80">
            Acesso Exclusivo
          </p>
          <h1 className="font-display text-2xl font-bold tracking-tight text-white lg:text-3xl">
            Clube VIP
          </h1>
        </div>
      </header>

      {/* Hero */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
        className="relative overflow-hidden rounded-[2rem] border border-gold-500/20 bg-gradient-to-br from-ink-900 via-ink-850 to-gold-950/30 p-7 lg:p-10"
      >
        <AmbientGlow className="-right-16 -top-16 h-56 w-56" />
        <AmbientGlow variant="subtle" className="-bottom-20 -left-10 h-44 w-44" />
        <div className="grain absolute inset-0 rounded-[2rem]" />

        <div className="relative flex flex-col items-start gap-5 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-center gap-4">
            <motion.div
              animate={{ y: [0, -6, 0] }}
              transition={{ duration: 5, repeat: Infinity, ease: 'easeInOut' }}
              className="grid h-16 w-16 shrink-0 place-items-center rounded-2xl bg-gradient-gold shadow-gold-lg"
            >
              <Crown size={30} className="text-zinc-950" strokeWidth={2.5} />
            </motion.div>
            <div>
              <h2 className="font-display text-2xl font-bold tracking-tight text-white lg:text-3xl">
                Faça parte do <span className="text-gradient-gold">clube</span>
              </h2>
              <p className="mt-1.5 max-w-md text-sm text-zinc-400">
                Mais estilo, mais economia. Eleve cada visita à Moura&apos;s com benefícios exclusivos.
              </p>
            </div>
          </div>
          <Badge variant="glass" icon={<Star size={12} className="fill-gold-400 text-gold-400" />}>
            Plano atual: {currentUser.membershipTier}
          </Badge>
        </div>
      </motion.div>

      {/* Plans grid */}
      <div className="grid gap-4 lg:grid-cols-3">
        {vipPlans.length === 0 && (
          <p className="text-sm text-zinc-400 lg:col-span-3">
            {plansMessage ?? 'Nenhum plano disponível.'}
          </p>
        )}
        {vipPlans.map((plan, idx) => {
          const icons = [Sparkles, Zap, Crown];
          const Icon = icons[idx % icons.length];
          const active = selected === plan.id;
          return (
            <motion.div
              key={plan.id}
              initial={{ opacity: 0, y: 24 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: idx * 0.1, ease: [0.22, 1, 0.36, 1] }}
            >
              <PlanCard
                plan={plan}
                icon={Icon}
                active={active}
                isCurrent={plan.id === currentUser.membershipTierId}
                onSelect={() => setSelected(plan.id)}
              />
            </motion.div>
          );
        })}
      </div>

      {/* Trust row */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.4 }}
        className="flex flex-wrap items-center justify-center gap-4 text-xs text-zinc-500"
      >
        <span className="flex items-center gap-1.5">
          <Shield size={14} className="text-gold-500/70" /> Cancele quando quiser
        </span>
        <span className="h-3 w-px bg-zinc-800" />
        <span className="flex items-center gap-1.5">
          <InfinityIcon size={14} className="text-gold-500/70" /> Sem fidelidade
        </span>
        <span className="h-3 w-px bg-zinc-800" />
        <span className="flex items-center gap-1.5">
          <Check size={14} className="text-gold-500/70" /> Ativação imediata
        </span>
      </motion.div>

      {/* CTA */}
      <motion.div
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5 }}
        className="flex flex-col gap-3"
      >
        <p className="text-sm text-zinc-400">
          {isCurrent
            ? 'Este é o seu plano atual.'
            : vipEnabled
              ? 'O cartão é tokenizado no Mercado Pago. A cobrança usa o plano sincronizado.'
              : plansMessage}
        </p>
        {!isCurrent && selectedPlan && (
          <div className="grid gap-3 sm:grid-cols-2">
            <input
              value={cardholder}
              onChange={(event) => setCardholder(event.target.value)}
              placeholder="Nome no cartão"
              className="rounded-xl border border-zinc-800 bg-ink-950 px-4 py-3 text-sm text-white outline-none focus:border-gold-500/50 sm:col-span-2"
            />
            <input
              inputMode="numeric"
              value={cpf}
              onChange={(event) => setCpf(event.target.value)}
              placeholder="CPF do titular"
              autoComplete="off"
              className="rounded-xl border border-zinc-800 bg-ink-950 px-4 py-3 text-sm text-white outline-none focus:border-gold-500/50 sm:col-span-2"
            />
            <input
              inputMode="numeric"
              value={cardNumber}
              onChange={(event) => setCardNumber(event.target.value)}
              placeholder="Número do cartão"
              className="rounded-xl border border-zinc-800 bg-ink-950 px-4 py-3 text-sm text-white outline-none focus:border-gold-500/50 sm:col-span-2"
            />
            <input
              inputMode="numeric"
              value={expiry}
              onChange={(event) => setExpiry(event.target.value)}
              placeholder="MM/AA"
              className="rounded-xl border border-zinc-800 bg-ink-950 px-4 py-3 text-sm text-white outline-none focus:border-gold-500/50"
            />
            <input
              inputMode="numeric"
              value={cvv}
              onChange={(event) => setCvv(event.target.value)}
              placeholder="CVV"
              className="rounded-xl border border-zinc-800 bg-ink-950 px-4 py-3 text-sm text-white outline-none focus:border-gold-500/50"
            />
          </div>
        )}
        {notice && (
          <p className={`text-sm ${done ? 'text-emerald-300' : 'text-red-300'}`}>{notice}</p>
        )}
        <Button
          size="lg"
          leftIcon={<Crown size={20} />}
          className="sm:min-w-[280px]"
          disabled={isCurrent || !selectedPlan || busy || !vipEnabled}
          onClick={() => void pay()}
        >
          {busy ? 'Assinando…' : isCurrent ? 'Plano Ativo' : `Assinar ${selectedPlan?.name ?? ''}`}
        </Button>
      </motion.div>
    </div>
  );
}

function PlanCard({
  plan,
  icon: Icon,
  active,
  isCurrent,
  onSelect,
}: {
  plan: VipPlan;
  icon: typeof Crown;
  active: boolean;
  isCurrent: boolean;
  onSelect: () => void;
}) {
  return (
    <Card
      onClick={onSelect}
      interactive={plan.highlighted}
      className={[
        'relative flex h-full cursor-pointer flex-col p-6 transition-all duration-300',
        plan.highlighted
          ? 'border-gold-500/50 bg-gradient-to-b from-gold-500/[0.06] to-ink-850 shadow-gold'
          : '',
        active && !plan.highlighted ? 'border-gold-500/40' : '',
      ].join(' ')}
    >
      {plan.badge && (
        <div className="absolute -top-3 left-1/2 -translate-x-1/2">
          <Badge variant="gold" className="shadow-gold">
            <Star size={11} className="fill-gold-400" /> {plan.badge}
          </Badge>
        </div>
      )}

      <div className="flex items-center gap-3">
        <span
          className={[
            'grid h-12 w-12 place-items-center rounded-xl transition-colors',
            plan.highlighted ? 'bg-gradient-gold text-zinc-950' : 'bg-zinc-800 text-gold-400',
          ].join(' ')}
        >
          <Icon size={24} strokeWidth={2} />
        </span>
        <div>
          <h3 className="font-display text-lg font-bold text-white">{plan.name}</h3>
          <p className="text-xs text-zinc-500">{plan.tagline}</p>
        </div>
      </div>

      <div className="mt-6 flex items-end gap-1.5">
        <span className="font-display text-4xl font-extrabold tracking-tight text-white">
          {plan.price === 0 ? 'Grátis' : formatCurrency(plan.price)}
        </span>
        {plan.price > 0 && <span className="mb-1.5 text-sm text-zinc-500">/ {plan.period}</span>}
      </div>
      {plan.price === 0 && <span className="mt-1 text-sm text-gold-500">{plan.period}</span>}

      <ul className="mt-6 space-y-3">
        {plan.benefits.map((benefit, i) => (
          <motion.li
            key={benefit}
            initial={{ opacity: 0, x: -8 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.15 + i * 0.05 }}
            className="flex items-start gap-3"
          >
            <span
              className={[
                'mt-0.5 grid h-5 w-5 shrink-0 place-items-center rounded-full',
                plan.highlighted ? 'bg-gold-500 text-zinc-950' : 'bg-zinc-800 text-gold-400',
              ].join(' ')}
            >
              <Check size={12} strokeWidth={3} />
            </span>
            <span className="text-sm text-zinc-300">{benefit}</span>
          </motion.li>
        ))}
      </ul>

      <div className="mt-auto pt-6">
        {isCurrent ? (
          <div className="flex items-center justify-center gap-2 rounded-xl border border-gold-500/30 bg-gold-500/5 py-3 text-sm font-semibold text-gold-400">
            <Check size={16} strokeWidth={2.5} /> Plano Ativo
          </div>
        ) : (
          <Button
            variant={plan.highlighted ? 'primary' : 'outline'}
            fullWidth
            className={active ? 'ring-2 ring-gold-500/40' : ''}
          >
            {active ? 'Plano Selecionado' : 'Escolher Plano'}
          </Button>
        )}
      </div>
    </Card>
  );
}
