interface AmbientGlowProps {
  className?: string;
  variant?: 'gold' | 'subtle';
}

export function AmbientGlow({
  className = '',
  variant = 'gold',
}: AmbientGlowProps) {
  const color =
    variant === 'gold'
      ? 'bg-gold-500/10'
      : 'bg-gold-500/[0.04]';
  return (
    <div
      className={[
        'pointer-events-none absolute rounded-full blur-3xl',
        color,
        className,
      ].join(' ')}
      aria-hidden
    />
  );
}
