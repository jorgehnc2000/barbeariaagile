import type { ReactNode } from 'react';
import { motion } from 'framer-motion';

interface SectionHeadingProps {
  eyebrow?: string;
  title: string;
  action?: ReactNode;
  className?: string;
}

export function SectionHeading({
  eyebrow,
  title,
  action,
  className = '',
}: SectionHeadingProps) {
  return (
    <div className={['flex items-end justify-between gap-4', className].join(' ')}>
      <div>
        {eyebrow && (
          <motion.p
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            className="mb-1.5 text-[11px] font-semibold uppercase tracking-[0.2em] text-gold-500/80"
          >
            {eyebrow}
          </motion.p>
        )}
        <motion.h2
          initial={{ opacity: 0, y: 8 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.05 }}
          className="font-display text-xl font-bold tracking-tight text-white lg:text-2xl"
        >
          {title}
        </motion.h2>
      </div>
      {action}
    </div>
  );
}
