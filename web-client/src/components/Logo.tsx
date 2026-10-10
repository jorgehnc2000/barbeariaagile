import { Scissors } from 'lucide-react';
import { useShop } from '@/data/shop';

interface LogoProps {
  size?: 'sm' | 'md' | 'lg';
  showText?: boolean;
}

const sizes = {
  sm: { box: 'h-9 w-9', icon: 16, text: 'text-base', sub: 'text-[9px]' },
  md: { box: 'h-11 w-11', icon: 20, text: 'text-lg', sub: 'text-[10px]' },
  lg: { box: 'h-14 w-14', icon: 26, text: 'text-2xl', sub: 'text-[11px]' },
};

export function Logo({ size = 'md', showText = true }: LogoProps) {
  const { shopProfile } = useShop();
  const s = sizes[size];
  const title = shopProfile.name.trim() || 'Barbearia';
  return (
    <div className="flex items-center gap-3">
      <div
        className={[
          s.box,
          'relative grid place-items-center rounded-2xl bg-gradient-gold shadow-gold',
        ].join(' ')}
      >
        <Scissors size={s.icon} className="text-zinc-950" strokeWidth={2.5} />
        <span className="absolute inset-0 rounded-2xl ring-1 ring-white/20" />
      </div>
      {showText && (
        <div className="flex flex-col leading-none">
            <span className={['max-w-[9rem] truncate font-display font-extrabold tracking-tightest text-white sm:max-w-[14rem]', s.text].join(' ')}>
              {title}
            </span>
          <span
            className={[
              'mt-0.5 uppercase tracking-[0.28em] text-gold-500/70 font-semibold',
              s.sub,
            ].join(' ')}
          >
            Barbearia
          </span>
        </div>
      )}
    </div>
  );
}
