import type { HTMLMotionProps } from 'framer-motion';
import { motion } from 'framer-motion';

interface CardProps extends HTMLMotionProps<'div'> {
  hover?: boolean;
  glow?: boolean;
  interactive?: boolean;
}

export function Card({
  hover = false,
  glow = false,
  interactive = false,
  className = '',
  children,
  ...props
}: CardProps) {
  return (
    <motion.div
      whileHover={hover || interactive ? { y: -4 } : undefined}
      whileTap={interactive ? { scale: 0.98 } : undefined}
      transition={{ type: 'spring', stiffness: 300, damping: 22 }}
      className={[
        'relative rounded-3xl bg-ink-850 border border-zinc-800/70',
        glow ? 'shadow-gold' : '',
        hover || interactive ? 'hover:border-gold-500/30 transition-colors duration-300' : '',
        className,
      ].join(' ')}
      {...props}
    >
      {children}
    </motion.div>
  );
}
