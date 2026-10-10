import { forwardRef } from 'react';
import type { ButtonHTMLAttributes, ReactNode } from 'react';
import { motion } from 'framer-motion';

type Variant = 'primary' | 'secondary' | 'ghost' | 'outline';
type Size = 'sm' | 'md' | 'lg';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  size?: Size;
  leftIcon?: ReactNode;
  rightIcon?: ReactNode;
  fullWidth?: boolean;
}

const variantClasses: Record<Variant, string> = {
  primary:
    'bg-gradient-gold text-zinc-950 font-semibold hover:shadow-gold-lg hover:brightness-105',
  secondary:
    'bg-zinc-800/80 text-zinc-100 hover:bg-zinc-700/80 border border-zinc-700/50',
  ghost: 'text-zinc-400 hover:text-gold-400 hover:bg-zinc-800/50',
  outline:
    'border border-gold-500/40 text-gold-400 hover:bg-gold-500/10 hover:border-gold-500',
};

const sizeClasses: Record<Size, string> = {
  sm: 'px-4 py-2 text-sm rounded-xl gap-1.5',
  md: 'px-5 py-3 text-sm rounded-xl gap-2',
  lg: 'px-6 py-4 text-base rounded-2xl gap-2.5',
};

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      variant = 'primary',
      size = 'md',
      leftIcon,
      rightIcon,
      fullWidth,
      className = '',
      children,
      disabled,
      ...props
    },
    ref,
  ) => {
    return (
      <motion.button
        ref={ref}
        whileTap={{ scale: disabled ? 1 : 0.96 }}
        whileHover={{ scale: disabled ? 1 : 1.02 }}
        transition={{ type: 'spring', stiffness: 400, damping: 25 }}
        disabled={disabled}
        className={[
          'inline-flex items-center justify-center transition-colors duration-200 select-none',
          'disabled:opacity-40 disabled:cursor-not-allowed disabled:hover:scale-100',
          variantClasses[variant],
          sizeClasses[size],
          fullWidth ? 'w-full' : '',
          className,
        ].join(' ')}
        {...(props as React.ComponentProps<typeof motion.button>)}
      >
        {leftIcon}
        {children}
        {rightIcon}
      </motion.button>
    );
  },
);

Button.displayName = 'Button';
