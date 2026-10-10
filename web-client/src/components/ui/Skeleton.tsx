interface SkeletonProps {
  className?: string;
}

export function Skeleton({ className = '' }: SkeletonProps) {
  return (
    <div
      className={[
        'relative overflow-hidden rounded-xl bg-zinc-800/50',
        className,
      ].join(' ')}
    >
      <div
        className="absolute inset-0 -translate-x-full animate-[shimmer_1.5s_infinite]"
        style={{
          background:
            'linear-gradient(90deg, transparent, rgba(63,63,70,0.4), transparent)',
        }}
      />
    </div>
  );
}
