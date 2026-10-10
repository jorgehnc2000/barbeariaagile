import { useState, type FormEvent } from 'react';
import { Button } from '@/components/ui/Button';
import { useShop } from '@/data/shop';

export function AuthDialog() {
  const { authOpen, closeAuth, session, signIn, signUp, signOut } = useShop();
  const [mode, setMode] = useState<'in' | 'up'>('in');
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  if (!authOpen) return null;

  async function submit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setMessage(null);
    try {
      if (mode === 'in') {
        await signIn(email.trim(), password);
      } else {
        const notice = await signUp(email.trim(), password, name.trim());
        if (notice) setMessage(notice);
      }
    } catch (cause) {
      setMessage(cause instanceof Error ? cause.message : 'Não foi possível entrar.');
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="fixed inset-0 z-[80] grid place-items-center bg-black/70 px-4">
      <div className="w-full max-w-md rounded-3xl border border-zinc-800 bg-ink-900 p-6 shadow-2xl">
        <div className="mb-5 flex items-start justify-between gap-4">
          <div>
            <p className="text-[11px] font-semibold uppercase tracking-[0.2em] text-gold-500/80">Conta</p>
            <h2 className="font-display text-2xl font-bold text-white">
              {session ? 'Sua conta' : mode === 'in' ? 'Entrar' : 'Criar conta'}
            </h2>
          </div>
          <button type="button" onClick={closeAuth} className="text-sm text-zinc-400 hover:text-white">
            Fechar
          </button>
        </div>

        {session ? (
          <div className="space-y-4">
            <p className="text-sm text-zinc-300">{session.user.email}</p>
            <Button fullWidth variant="outline" onClick={() => void signOut().then(closeAuth)}>
              Sair
            </Button>
          </div>
        ) : (
          <form className="space-y-3" onSubmit={(event) => void submit(event)}>
            {mode === 'up' && (
              <input
                required
                value={name}
                onChange={(event) => setName(event.target.value)}
                placeholder="Seu nome"
                className="w-full rounded-xl border border-zinc-800 bg-ink-950 px-4 py-3 text-sm text-white outline-none focus:border-gold-500/50"
              />
            )}
            <input
              required
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              placeholder="E-mail"
              className="w-full rounded-xl border border-zinc-800 bg-ink-950 px-4 py-3 text-sm text-white outline-none focus:border-gold-500/50"
            />
            <input
              required
              minLength={6}
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              placeholder="Senha"
              className="w-full rounded-xl border border-zinc-800 bg-ink-950 px-4 py-3 text-sm text-white outline-none focus:border-gold-500/50"
            />
            {message && <p className="text-sm text-gold-200">{message}</p>}
            <Button fullWidth type="submit" disabled={busy}>
              {busy ? 'Aguarde…' : mode === 'in' ? 'Entrar' : 'Criar conta'}
            </Button>
            <button
              type="button"
              className="w-full text-sm text-zinc-400 hover:text-gold-400"
              onClick={() => {
                setMode(mode === 'in' ? 'up' : 'in');
                setMessage(null);
              }}
            >
              {mode === 'in' ? 'Não tem conta? Cadastre-se' : 'Já tenho conta'}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
