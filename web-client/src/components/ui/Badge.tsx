import type { ReactNode } from 'react';

interface BadgeProps {
  children: ReactNode;
  variant?: 'gold' | 'neutral' | 'success' | 'outline' | 'glass';
  icon?: ReactNode;
  className?: string;
}

const variants = {
  gold: 'bg-gold-500/15 text-gold-300 border-gold-500/30',
  neutral: 'bg-zinc-800/80 text-zinc-300 border-zinc-700/50',
  success: 'bg-emerald-500/15 text-emerald-300 border-emerald-500/30',
  outline: 'bg-transparent text-gold-400 border-gold-500/40',
  glass: 'glass text-zinc-200 border-white/10',
};

export function Badge({
  children,
  variant = 'neutral',
  icon,
  className = '',
}: BadgeProps) {
  return (
    <span
      className={[
        'inline-flex items-center gap-1.5 rounded-full border px-3 py-1 text-xs font-medium',
        variants[variant],
        className,
      ].join(' ')}
    >
      {icon}
      {children}
    </span>
  );
}
