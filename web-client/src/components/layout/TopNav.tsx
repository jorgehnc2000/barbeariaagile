import { Home, CalendarPlus, Crown } from 'lucide-react';
import type { LucideIcon } from 'lucide-react';
import { motion } from 'framer-motion';
import { Logo } from '@/components/Logo';
import { currentUser } from '@/data/mockData';
import type { ViewId } from '@/types';

interface TopNavProps {
  current: ViewId;
  onNavigate: (view: ViewId) => void;
}

const navItems: { id: ViewId; label: string; icon: LucideIcon }[] = [
  { id: 'home', label: 'Início', icon: Home },
  { id: 'booking', label: 'Agendar', icon: CalendarPlus },
  { id: 'vip', label: 'Clube VIP', icon: Crown },
];

export function TopNav({ current, onNavigate }: TopNavProps) {
  return (
    <header className="fixed top-0 left-0 right-0 z-50 hidden lg:block">
      <div className="glass-strong border-b border-zinc-800/50">
        <div className="mx-auto flex max-w-5xl items-center justify-between px-8 py-3.5">
          <Logo size="md" />

          <nav className="flex items-center gap-1 rounded-2xl border border-zinc-800/60 bg-ink-900/50 p-1">
            {navItems.map((item) => {
              const active = current === item.id;
              const Icon = item.icon;
              return (
                <button
                  key={item.id}
                  onClick={() => onNavigate(item.id)}
                  className="relative rounded-xl px-4 py-2"
                >
                  {active && (
                    <motion.div
                      layoutId="topNavPill"
                      className="absolute inset-0 rounded-xl bg-gradient-gold"
                      transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                    />
                  )}
                  <span
                    className={[
                      'relative flex items-center gap-2 text-sm font-medium transition-colors duration-200',
                      active ? 'text-zinc-950' : 'text-zinc-400 hover:text-zinc-200',
                    ].join(' ')}
                  >
                    <Icon size={17} strokeWidth={active ? 2.5 : 2} />
                    {item.label}
                  </span>
                </button>
              );
            })}
          </nav>

          <button className="flex items-center gap-3">
            <div className="text-right">
              <p className="text-sm font-semibold text-zinc-100">{currentUser.firstName}</p>
              <p className="text-xs text-gold-500">{currentUser.membershipTier}</p>
            </div>
            <div className="relative">
              <img
                src={currentUser.avatarUrl}
                alt={currentUser.name}
                className="h-10 w-10 rounded-full border-2 border-gold-500/40 object-cover"
              />
              <span className="absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full border-2 border-ink-950 bg-emerald-500" />
            </div>
          </button>
        </div>
      </div>
    </header>
  );
}
