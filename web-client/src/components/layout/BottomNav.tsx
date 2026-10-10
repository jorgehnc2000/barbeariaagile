import { Home, CalendarPlus, Crown } from 'lucide-react';
import type { LucideIcon } from 'lucide-react';
import { motion } from 'framer-motion';
import type { ViewId } from '@/types';

interface NavItem {
  id: ViewId;
  label: string;
  icon: LucideIcon;
}

const navItems: NavItem[] = [
  { id: 'home', label: 'Início', icon: Home },
  { id: 'booking', label: 'Agendar', icon: CalendarPlus },
  { id: 'vip', label: 'Clube VIP', icon: Crown },
];

interface BottomNavProps {
  current: ViewId;
  onNavigate: (view: ViewId) => void;
}

export function BottomNav({ current, onNavigate }: BottomNavProps) {
  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 lg:hidden safe-bottom">
      <div className="glass-strong border-t border-zinc-800/50">
        <div className="mx-auto flex max-w-md items-center justify-around px-4 pb-2 pt-2.5">
          {navItems.map((item) => {
            const active = current === item.id;
            const Icon = item.icon;
            return (
              <button
                key={item.id}
                onClick={() => onNavigate(item.id)}
                className="relative flex flex-1 flex-col items-center gap-1 py-1.5"
              >
                {active && (
                  <motion.div
                    layoutId="bottomNavPill"
                    className="absolute inset-x-2 -top-0.5 bottom-0 rounded-2xl bg-gold-500/10"
                    transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                  />
                )}
                <motion.div
                  whileTap={{ scale: 0.85 }}
                  transition={{ type: 'spring', stiffness: 500, damping: 20 }}
                  className="relative"
                >
                  <Icon
                    size={22}
                    className={[
                      'transition-colors duration-200',
                      active ? 'text-gold-400' : 'text-zinc-500',
                    ].join(' ')}
                    strokeWidth={active ? 2.5 : 2}
                  />
                  {active && (
                    <motion.span
                      layoutId="bottomNavDot"
                      className="absolute -bottom-1.5 left-1/2 h-1 w-1 -translate-x-1/2 rounded-full bg-gold-400"
                    />
                  )}
                </motion.div>
                <span
                  className={[
                    'relative text-[10px] font-medium transition-colors duration-200',
                    active ? 'text-gold-400' : 'text-zinc-500',
                  ].join(' ')}
                >
                  {item.label}
                </span>
              </button>
            );
          })}
        </div>
      </div>
    </nav>
  );
}
