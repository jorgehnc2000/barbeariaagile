import { useState } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { TopNav } from '@/components/layout/TopNav';
import { BottomNav } from '@/components/layout/BottomNav';
import { HomeView } from '@/views/HomeView';
import { BookingView } from '@/views/BookingView';
import { VipView } from '@/views/VipView';
import { AuthDialog } from '@/components/AuthDialog';
import { useShop } from '@/data/shop';
import type { ViewId } from '@/types';

const viewOrder: ViewId[] = ['home', 'booking', 'vip'];

const pageVariants = {
  enter: (dir: number) => ({ opacity: 0, x: dir > 0 ? 32 : -32, filter: 'blur(4px)' }),
  center: { opacity: 1, x: 0, filter: 'blur(0px)' },
  exit: (dir: number) => ({ opacity: 0, x: dir > 0 ? -32 : 32, filter: 'blur(4px)' }),
};

export default function App() {
  const { loading, error, barbershopName } = useShop();
  const [view, setView] = useState<ViewId>('home');
  const [direction, setDirection] = useState(1);

  function navigate(next: ViewId) {
    const dir = viewOrder.indexOf(next) >= viewOrder.indexOf(view) ? 1 : -1;
    setDirection(dir);
    setView(next);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  return (
    <div className="relative min-h-screen bg-ink-950 text-zinc-100">
      <TopNav current={view} onNavigate={navigate} />
      <BottomNav current={view} onNavigate={navigate} />

      <main className="mx-auto max-w-5xl px-4 pb-28 pt-6 lg:px-8 lg:pb-16 lg:pt-24">
        {(loading || error) && (
          <p className={`mb-4 text-sm ${error ? 'text-red-300' : 'text-zinc-500'}`}>
            {error ?? `Carregando ${barbershopName}…`}
          </p>
        )}
        <AnimatePresence mode="wait" custom={direction}>
          <motion.div
            key={view}
            custom={direction}
            variants={pageVariants}
            initial="enter"
            animate="center"
            exit="exit"
            transition={{ duration: 0.36, ease: [0.22, 1, 0.36, 1] }}
          >
            {view === 'home' && <HomeView onNavigate={navigate} />}
            {view === 'booking' && <BookingView onNavigate={navigate} />}
            {view === 'vip' && <VipView onNavigate={navigate} />}
          </motion.div>
        </AnimatePresence>
      </main>
      <AuthDialog />
    </div>
  );
}
