import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import type { Session } from '@supabase/supabase-js';
import { supabase, supabaseAnonKey } from '@/lib/supabase';
import type { Appointment, Barber, Service, UserProfile, VipPlan } from '@/types';

export const TIME_SLOTS = [
  '09:00',
  '09:30',
  '10:00',
  '10:30',
  '11:00',
  '11:30',
  '14:00',
  '14:30',
  '15:00',
  '15:30',
  '16:00',
  '16:30',
  '17:00',
  '17:30',
  '18:00',
  '18:30',
];

const GUEST_AVATAR =
  'data:image/svg+xml,' +
  encodeURIComponent(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80"><rect fill="#27272a" width="80" height="80"/><circle cx="40" cy="32" r="12" fill="#a1a1aa"/><ellipse cx="40" cy="62" rx="18" ry="12" fill="#a1a1aa"/></svg>',
  );

const guestUser: UserProfile = {
  name: 'Visitante',
  firstName: 'visitante',
  avatarUrl: GUEST_AVATAR,
  membershipTier: 'Sem plano',
  membershipTierId: '',
  loyaltyPoints: 0,
  visitsThisMonth: 0,
  memberSince: '—',
  nextRewardAt: 1,
};

export type PendingReview = {
  appointmentId: string;
  barberId: string;
  barberName: string;
  serviceName: string;
};

type ShopContextValue = {
  loading: boolean;
  error: string | null;
  slug: string | null;
  barbershopId: string | null;
  barbershopName: string;
  services: Service[];
  barbers: Barber[];
  plans: VipPlan[];
  vipEnabled: boolean;
  mpPublicKey: string;
  plansMessage: string | null;
  currentUser: UserProfile;
  upcomingAppointment: Appointment | null;
  session: Session | null;
  timeSlots: string[];
  occupiedTimes: Set<string>;
  loadOccupied: (barberId: string, day: Date) => Promise<void>;
  createBooking: (input: {
    barberId: string;
    serviceId: string;
    startAt: Date;
    durationMin: number;
  }) => Promise<void>;
  openLegacyAccount: (path?: string) => void;
  authOpen: boolean;
  requestAuth: () => void;
  closeAuth: () => void;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string, name: string) => Promise<string | null>;
  signOut: () => Promise<void>;
  pendingReview: PendingReview | null;
  submitReview: (rating: number) => Promise<void>;
  subscribePlan: (input: {
    planId: string;
    cardNumber: string;
    expiry: string;
    cvv: string;
    cardholder: string;
    cpf: string;
  }) => Promise<void>;
};

const ShopContext = createContext<ShopContextValue | null>(null);

export function ShopProvider({ children }: { children: ReactNode }) {
  const slug = useMemo(() => readSlug(), []);
  const [loading, setLoading] = useState(Boolean(slug));
  const [error, setError] = useState<string | null>(null);
  const [barbershopId, setBarbershopId] = useState<string | null>(null);
  const [barbershopName, setBarbershopName] = useState('Barbearia');
  const [services, setServices] = useState<Service[]>([]);
  const [barbers, setBarbers] = useState<Barber[]>([]);
  const [plans, setPlans] = useState<VipPlan[]>([]);
  const [vipEnabled, setVipEnabled] = useState(false);
  const [mpPublicKey, setMpPublicKey] = useState('');
  const [plansMessage, setPlansMessage] = useState<string | null>(null);
  const [currentUser, setCurrentUser] = useState<UserProfile>(guestUser);
  const [upcomingAppointment, setUpcomingAppointment] = useState<Appointment | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [occupiedTimes, setOccupiedTimes] = useState<Set<string>>(new Set());
  const [authOpen, setAuthOpen] = useState(false);
  const [pendingReview, setPendingReview] = useState<PendingReview | null>(null);

  useEffect(() => {
    const { data } = supabase.auth.onAuthStateChange((_event, next) => {
      setSession(next);
    });
    void supabase.auth.getSession().then(({ data: current }) => {
      setSession(current.session);
    });
    return () => data.subscription.unsubscribe();
  }, []);

  useEffect(() => {
    if (!slug) {
      setError('Abra o app com o slug da barbearia na URL (ex.: /moura ou ?slug=moura).');
      setLoading(false);
      return;
    }

    let cancelled = false;
    const timeout = window.setTimeout(() => {
      if (cancelled) return;
      cancelled = true;
      setError('O Supabase não respondeu. Se o projeto estiver pausado, retome no dashboard.');
      setLoading(false);
    }, 12000);
    setLoading(true);
    setError(null);

    void (async () => {
      try {
        const shopFull = await supabase
          .from('barbershops')
          .select('id, slug, mp_public_key, vip_enabled')
          .eq('slug', slug)
          .maybeSingle();
        const shop = shopFull.error
          ? await supabase.from('barbershops').select('id, slug').eq('slug', slug).maybeSingle()
          : shopFull;
        if (shop.error) throw shop.error;
        if (!shop.data) throw new Error(`Nenhuma barbearia encontrada para "${slug}".`);
        if (cancelled) return;

        const id = String(shop.data.id);
        setBarbershopId(id);
        const shopRow = shop.data as { mp_public_key?: string; vip_enabled?: boolean };
        setVipEnabled(shopRow.vip_enabled !== false);
        setMpPublicKey(String(shopRow.mp_public_key ?? '').trim());

        const { data: earlyAuth } = await supabase.auth.getSession();
        if (earlyAuth.session?.user) {
          await ensureClientProfile(id, earlyAuth.session.user);
        }

        const info = await supabase
          .from('barbearia_info')
          .select('nome')
          .eq('barbershop_id', id)
          .limit(1)
          .maybeSingle();
        const name = String(info.data?.nome ?? '').trim();
        if (name) setBarbershopName(name);

        const serviceRows = await supabase
          .from('servicos')
          .select('id, nome, preco, duracao_minutos, descricao, imagem_url')
          .eq('barbershop_id', id)
          .order('nome');
        if (serviceRows.error) throw serviceRows.error;

        const withAvailability = await supabase
          .from('barbeiros')
          .select('id, nome, foto_url, especialidades, disponivel')
          .eq('barbershop_id', id)
          .order('nome');
        const barberRows = withAvailability.error
          ? await supabase
              .from('barbeiros')
              .select('id, nome, foto_url, especialidades')
              .eq('barbershop_id', id)
              .order('nome')
          : withAvailability;
        if (barberRows.error) throw barberRows.error;

        const planRows = await supabase
          .from('plans')
          .select('id, name, description, benefits, monthly_amount, frequency, active, mp_status, mp_plan_id')
          .eq('barbershop_id', id)
          .eq('active', true)
          .eq('mp_status', 'synchronized')
          .order('created_at');
        if (planRows.error) throw planRows.error;
        if (cancelled) return;

        setServices((serviceRows.data ?? []).map((row) => mapService(row as Record<string, unknown>)));
        setBarbers(
          (barberRows.data ?? [])
            .filter((row) => (row as { disponivel?: boolean }).disponivel !== false)
            .map((row) => mapBarber(row as Record<string, unknown>)),
        );
        const ratings = await supabase.rpc('barber_rating_summary', { p_barbershop_id: id });
        if (!ratings.error && ratings.data) {
          const byId = new Map(
            (ratings.data as { barbeiro_id: string; rating: number; reviews: number }[]).map((row) => [
              String(row.barbeiro_id),
              row,
            ]),
          );
          setBarbers((current) =>
            current.map((barber) => {
              const stats = byId.get(barber.id);
              return stats
                ? { ...barber, rating: Number(stats.rating), reviews: Number(stats.reviews) }
                : barber;
            }),
          );
        }
        const mappedPlans = (planRows.data ?? []).map((row, index) =>
          mapPlan(row as Record<string, unknown>, index),
        );
        setPlans(mappedPlans);
        if (shopRow.vip_enabled === false) {
          setPlansMessage('O Clube VIP não está habilitado nesta barbearia.');
        } else if (mappedPlans.length === 0) {
          setPlansMessage('Nenhum plano ativo sincronizado com o Mercado Pago.');
        } else {
          setPlansMessage(null);
        }

        const { data: authData } = await supabase.auth.getSession();
        const activeSession = authData.session;
        const userId = activeSession?.user.id;
        if (!userId || !activeSession || cancelled) {
          setCurrentUser(guestUser);
          setUpcomingAppointment(null);
          setPendingReview(null);
          return;
        }

        const profile = await loadProfile(id, userId, activeSession.user);
        if (!cancelled) setCurrentUser(profile.user);
        const next = await loadUpcoming(id, userId);
        if (!cancelled) setUpcomingAppointment(next);
        const review = await loadPendingReview(id, userId);
        if (!cancelled) setPendingReview(review);
      } catch (cause) {
        if (!cancelled) {
          setError(cause instanceof Error ? cause.message : 'Falha ao carregar a barbearia.');
        }
      } finally {
        window.clearTimeout(timeout);
        if (!cancelled) setLoading(false);
      }
    })();

    return () => {
      cancelled = true;
      window.clearTimeout(timeout);
    };
  }, [slug, session?.user.id]);

  const loadOccupied = useCallback(
    async (barberId: string, day: Date) => {
      if (!barbershopId) {
        setOccupiedTimes(new Set());
        return;
      }
      const dayKey = `${day.getFullYear()}-${String(day.getMonth() + 1).padStart(2, '0')}-${String(day.getDate()).padStart(2, '0')}`;
      const { data, error: queryError } = await supabase.rpc('occupied_slot_times', {
        p_barbershop_id: barbershopId,
        p_barber_id: barberId,
        p_day: dayKey,
      });
      if (queryError) {
        setOccupiedTimes(new Set());
        return;
      }
      setOccupiedTimes(new Set((data ?? []).map((row: { slot: string }) => row.slot)));
    },
    [barbershopId],
  );

  const refreshAccount = useCallback(async () => {
    if (!barbershopId) return;
    const { data } = await supabase.auth.getSession();
    const user = data.session?.user;
    if (!user) {
      setCurrentUser(guestUser);
      setUpcomingAppointment(null);
      setPendingReview(null);
      return;
    }
    const profile = await loadProfile(barbershopId, user.id, user);
    setCurrentUser(profile.user);
    setUpcomingAppointment(await loadUpcoming(barbershopId, user.id));
    setPendingReview(await loadPendingReview(barbershopId, user.id));
  }, [barbershopId]);

  useEffect(() => {
    if (!barbershopId || !session?.user.id) return;
    const userId = session.user.id;
    const refresh = () => {
      void refreshAccount();
    };
    const onVisible = () => {
      if (document.visibilityState === 'visible') refresh();
    };
    window.addEventListener('focus', refresh);
    document.addEventListener('visibilitychange', onVisible);
    const timer = window.setInterval(() => {
      if (document.visibilityState === 'visible') refresh();
    }, 15000);
    const channel = supabase
      .channel(`account-${userId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'agendamentos',
          filter: `cliente_id=eq.${userId}`,
        },
        refresh,
      )
      .subscribe();
    return () => {
      window.removeEventListener('focus', refresh);
      document.removeEventListener('visibilitychange', onVisible);
      window.clearInterval(timer);
      void supabase.removeChannel(channel);
    };
  }, [barbershopId, refreshAccount, session?.user.id]);

  const openLegacyAccount = useCallback(
    (path = '') => {
      if (!slug) return;
      const origin = (import.meta.env.VITE_LEGACY_APP_ORIGIN || 'https://barbeariaagile.vercel.app').replace(
        /\/$/,
        '',
      );
      const suffix = path.startsWith('/') ? path : path ? `/${path}` : '';
      window.location.assign(`${origin}/${slug}${suffix}`);
    },
    [slug],
  );

  const createBooking = useCallback(
    async (input: {
      barberId: string;
      serviceId: string;
      startAt: Date;
      durationMin: number;
    }) => {
      if (!barbershopId || !slug) {
        throw new Error('Barbearia não identificada.');
      }
      const { data: auth } = await supabase.auth.getSession();
      if (!auth.session) {
        setAuthOpen(true);
        throw new Error('Entre na conta para confirmar o horário.');
      }
      await ensureClientProfile(barbershopId, auth.session.user);
      const end = new Date(input.startAt.getTime() + input.durationMin * 60_000);
      const { data, error: rpcError } = await supabase.rpc('create_vip_booking', {
        p_barbershop_id: barbershopId,
        p_barber_id: input.barberId,
        p_service_id: input.serviceId,
        p_start_at: input.startAt.toISOString(),
        p_end_at: end.toISOString(),
        p_status: 'confirmado',
      });
      if (rpcError) throw new Error(rpcError.message);
      const rows = Array.isArray(data) ? data : data ? [data] : [];
      if (rows.length === 0) throw new Error('O agendamento não foi criado.');
      await refreshAccount();
    },
    [barbershopId, refreshAccount, slug],
  );

  const signIn = useCallback(async (email: string, password: string) => {
    const { error: authError } = await supabase.auth.signInWithPassword({ email, password });
    if (authError) throw new Error(authError.message);
    setAuthOpen(false);
  }, []);

  const signUp = useCallback(
    async (email: string, password: string, name: string) => {
      const { data, error: authError } = await supabase.auth.signUp({
        email,
        password,
        options: { data: { nome: name } },
      });
      if (authError) throw new Error(authError.message);
      if (data.session && data.user && barbershopId) {
        await ensureClientProfile(barbershopId, data.user);
        setAuthOpen(false);
        return null;
      }
      return 'Conta criada. Confirme o e-mail para entrar.';
    },
    [barbershopId],
  );

  const signOut = useCallback(async () => {
    await supabase.auth.signOut();
    setCurrentUser(guestUser);
    setUpcomingAppointment(null);
    setPendingReview(null);
  }, []);

  const submitReview = useCallback(
    async (rating: number) => {
      if (!pendingReview || !barbershopId || !session?.user.id) {
        throw new Error('Entre na conta para avaliar.');
      }
      const { error: insertError } = await supabase.from('barber_reviews').insert({
        barbershop_id: barbershopId,
        barbeiro_id: pendingReview.barberId,
        cliente_id: session.user.id,
        agendamento_id: pendingReview.appointmentId,
        rating,
      });
      if (insertError) throw new Error(insertError.message);
      setPendingReview(null);
      const ratings = await supabase.rpc('barber_rating_summary', { p_barbershop_id: barbershopId });
      if (!ratings.error && ratings.data) {
        const byId = new Map(
          (ratings.data as { barbeiro_id: string; rating: number; reviews: number }[]).map((row) => [
            String(row.barbeiro_id),
            row,
          ]),
        );
        setBarbers((current) =>
          current.map((barber) => {
            const stats = byId.get(barber.id);
            return stats
              ? { ...barber, rating: Number(stats.rating), reviews: Number(stats.reviews) }
              : barber;
          }),
        );
      }
    },
    [barbershopId, pendingReview, session?.user.id],
  );

  const subscribePlan = useCallback(
    async (input: {
      planId: string;
      cardNumber: string;
      expiry: string;
      cvv: string;
      cardholder: string;
      cpf: string;
    }) => {
      if (!barbershopId) throw new Error('Barbearia não identificada.');
      if (!vipEnabled) throw new Error('O Clube VIP não está habilitado nesta barbearia.');
      if (!mpPublicKey || mpPublicKey === 'public_key_not_configured') {
        throw new Error('A chave pública do Mercado Pago ainda não foi configurada.');
      }
      const { data: auth } = await supabase.auth.getSession();
      const user = auth.session?.user;
      if (!user?.email) {
        setAuthOpen(true);
        throw new Error('Faça login para assinar o Clube VIP.');
      }
      const plan = plans.find((item) => item.id === input.planId);
      if (!plan?.mpPlanId) throw new Error('Este plano ainda não está disponível para assinatura.');

      const cpf = input.cpf.replace(/\D/g, '');
      if (cpf.length !== 11) throw new Error('Informe o CPF do titular do cartão.');
      const expiry = input.expiry.replace(/\D/g, '');
      if (expiry.length !== 4) throw new Error('Use o vencimento no formato MM/AA.');
      const month = Number(expiry.slice(0, 2));
      const year = Number(`20${expiry.slice(2, 4)}`);
      if (month < 1 || month > 12) throw new Error('Vencimento inválido.');

      const tokenResponse = await fetch(
        `/api/mp/card_tokens?public_key=${encodeURIComponent(mpPublicKey)}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            card_number: input.cardNumber.replace(/\D/g, ''),
            expiration_month: month,
            expiration_year: year,
            security_code: input.cvv.replace(/\D/g, ''),
            cardholder: {
              name: input.cardholder.trim(),
              identification: { type: 'CPF', number: cpf },
            },
          }),
        },
      );
      const tokenBody = (await readJson(tokenResponse)) as {
        id?: string;
        message?: string;
        error?: string;
        cause?: { description?: string }[];
      };
      if (!tokenResponse.ok || !tokenBody.id) {
        const cause = tokenBody.cause?.find((item) => item.description)?.description;
        throw new Error(cause || tokenBody.message || tokenBody.error || 'Não foi possível validar o cartão.');
      }

      const { data: sessionData } = await supabase.auth.getSession();
      const accessToken = sessionData.session?.access_token;
      if (!accessToken) throw new Error('Faça login para assinar o Clube VIP.');

      const subscriptionResponse = await fetch('/api/create-subscription', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          apikey: supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          plan_id: plan.id,
          card_token_id: tokenBody.id,
          barbershop_id: barbershopId,
          user_id: user.id,
          email: user.email,
        }),
      });
      const subscriptionBody = await readJson(subscriptionResponse);
      if (!subscriptionResponse.ok || subscriptionBody.error) {
        throw new Error(
          subscriptionError(subscriptionBody) ||
            `Não foi possível criar a assinatura (${subscriptionResponse.status}).`,
        );
      }

      const profile = await loadProfile(barbershopId, user.id, user);
      setCurrentUser(profile.user);
    },
    [barbershopId, mpPublicKey, plans, vipEnabled],
  );

  const value = useMemo<ShopContextValue>(
    () => ({
      loading,
      error,
      slug,
      barbershopId,
      barbershopName,
      services,
      barbers,
      plans,
      vipEnabled,
      mpPublicKey,
      plansMessage,
      currentUser,
      upcomingAppointment,
      session,
      timeSlots: TIME_SLOTS,
      occupiedTimes,
      loadOccupied,
      createBooking,
      openLegacyAccount,
      authOpen,
      requestAuth: () => setAuthOpen(true),
      closeAuth: () => setAuthOpen(false),
      signIn,
      signUp,
      signOut,
      pendingReview,
      submitReview,
      subscribePlan,
    }),
    [
      loading,
      error,
      slug,
      barbershopId,
      barbershopName,
      services,
      barbers,
      plans,
      vipEnabled,
      mpPublicKey,
      plansMessage,
      currentUser,
      upcomingAppointment,
      session,
      occupiedTimes,
      loadOccupied,
      createBooking,
      openLegacyAccount,
      authOpen,
      signIn,
      signUp,
      signOut,
      pendingReview,
      submitReview,
      subscribePlan,
    ],
  );

  return <ShopContext.Provider value={value}>{children}</ShopContext.Provider>;
}

export function useShop() {
  const value = useContext(ShopContext);
  if (!value) throw new Error('useShop deve ficar dentro de ShopProvider.');
  return value;
}

function subscriptionError(body: Record<string, unknown>): string {
  const details = body.details;
  const detailMessage =
    typeof details === 'string'
      ? details
      : details && typeof details === 'object'
        ? String((details as { message?: unknown }).message ?? '')
        : '';
  if (detailMessage.includes('CC_VAL_433')) {
    return 'O Mercado Pago recusou este cartão. Confira número, validade, CVV e CPF do titular.';
  }
  if (detailMessage) return detailMessage;
  return String(body.error || body.message || '');
}

function readJson(response: Response): Promise<Record<string, unknown>> {
  return response
    .text()
    .then((text) => {
      if (!text.trim()) return {};
      try {
        const parsed = JSON.parse(text) as unknown;
        return parsed && typeof parsed === 'object' ? (parsed as Record<string, unknown>) : {};
      } catch {
        return { message: text };
      }
    })
    .catch(() => ({}));
}

function readSlug(): string | null {
  const query = new URLSearchParams(window.location.search).get('slug')?.trim().toLowerCase();
  if (query) return query;
  const segment = window.location.pathname
    .split('/')
    .map((part) => decodeURIComponent(part).trim().toLowerCase())
    .find((part) => part.length > 0);
  if (!segment || segment === 'admin' || segment === 'sucesso-assinatura') return null;
  return segment;
}

function mapService(row: Record<string, unknown>): Service {
  const name = String(row.nome ?? '');
  return {
    id: String(row.id),
    name,
    description: String(row.descricao ?? ''),
    price: Number(row.preco ?? 0),
    durationMin: Number(row.duracao_minutos ?? 30),
    icon: iconForService(name),
  };
}

function mapBarber(row: Record<string, unknown>): Barber {
  const specialties = Array.isArray(row.especialidades)
    ? row.especialidades.map((item) => String(item))
    : [];
  return {
    id: String(row.id),
    name: String(row.nome ?? ''),
    role: specialties[0] || 'Barbeiro',
    rating: 0,
    reviews: 0,
    avatarUrl: String(row.foto_url ?? '') || GUEST_AVATAR,
    specialties,
  };
}

function mapPlan(row: Record<string, unknown>, index: number): VipPlan {
  const benefits = Array.isArray(row.benefits)
    ? row.benefits.map((item) => String(item))
    : String(row.benefits ?? '')
        .split('\n')
        .map((item) => item.trim())
        .filter(Boolean);
  const frequency = String(row.frequency ?? 'monthly');
  return {
    id: String(row.id),
    name: String(row.name ?? 'Plano'),
    price: Number(row.monthly_amount ?? 0),
    period: frequency === 'yearly' ? 'por ano' : frequency === 'quarterly' ? 'por trimestre' : 'por mês',
    tagline: String(row.description ?? ''),
    highlighted: index === 0,
    benefits,
    mpPlanId: String(row.mp_plan_id ?? ''),
  };
}

function iconForService(name: string): string {
  const normalized = name.toLowerCase();
  if (normalized.includes('barba') && normalized.includes('cabelo')) return 'sparkles';
  if (normalized.includes('barba')) return 'brush';
  if (normalized.includes('sobran')) return 'eye';
  if (normalized.includes('pigment')) return 'palette';
  if (normalized.includes('hidrata')) return 'droplet';
  return 'scissors';
}

async function loadPendingReview(barbershopId: string, userId: string): Promise<PendingReview | null> {
  const { data: bookings, error } = await supabase
    .from('agendamentos')
    .select('id, barbeiro_id, status, data_inicio, barbeiros(nome), servicos(nome)')
    .eq('cliente_id', userId)
    .eq('barbershop_id', barbershopId)
    .lt('data_inicio', new Date().toISOString())
    .order('data_inicio', { ascending: false })
    .limit(8);
  if (error || !bookings) return null;

  const done = bookings.filter((row) => {
    const status = String(row.status ?? '').toLowerCase();
    return ['confirmado', 'concluido', 'completed', 'finalizado'].includes(status);
  });
  if (done.length === 0) return null;

  const ids = done.map((row) => String(row.id));
  const { data: reviews } = await supabase
    .from('barber_reviews')
    .select('agendamento_id')
    .in('agendamento_id', ids);
  const reviewed = new Set((reviews ?? []).map((row) => String(row.agendamento_id)));
  const pending = done.find((row) => !reviewed.has(String(row.id)));
  if (!pending) return null;
  const barber = firstJoin(pending.barbeiros);
  const service = firstJoin(pending.servicos);
  return {
    appointmentId: String(pending.id),
    barberId: String(pending.barbeiro_id),
    barberName: String(barber?.nome ?? 'Barbeiro'),
    serviceName: String(service?.nome ?? 'serviço'),
  };
}

async function loadProfile(
  barbershopId: string,
  userId: string,
  authUser: { email?: string; user_metadata?: Record<string, unknown> },
): Promise<{ user: UserProfile }> {
  const { data: profile } = await supabase
    .from('users')
    .select('nome, avatar_url')
    .eq('id', userId)
    .maybeSingle();
  const rawName =
    String(profile?.nome ?? '').trim() ||
    String(authUser.user_metadata?.nome ?? authUser.user_metadata?.full_name ?? '').trim() ||
    authUser.email?.split('@')[0] ||
    'Cliente';

  const [{ data: loyalty }, { data: settings }] = await Promise.all([
    supabase
      .from('loyalty_accounts')
      .select('points, member_since')
      .eq('user_id', userId)
      .eq('barbershop_id', barbershopId)
      .maybeSingle(),
    supabase.from('loyalty_settings').select('reward_at').eq('barbershop_id', barbershopId).maybeSingle(),
  ]);

  const { data: subscription } = await supabase
    .from('subscriptions')
    .select('status, plan_id, plans(id, name)')
    .eq('user_id', userId)
    .eq('barbershop_id', barbershopId)
    .maybeSingle();

  const status = String(subscription?.status ?? '').toLowerCase();
  const active = status === 'authorized' || status === 'active' || status === 'ativo';
  const planJoin = subscription?.plans as { id?: string; name?: string } | { id?: string; name?: string }[] | null;
  const plan = Array.isArray(planJoin) ? planJoin[0] : planJoin;

  const monthStart = new Date();
  monthStart.setDate(1);
  monthStart.setHours(0, 0, 0, 0);
  const nextMonth = new Date(monthStart);
  nextMonth.setMonth(nextMonth.getMonth() + 1);
  const { data: monthRows } = await supabase
    .from('agendamentos')
    .select('id, status')
    .eq('cliente_id', userId)
    .eq('barbershop_id', barbershopId)
    .gte('data_inicio', monthStart.toISOString())
    .lt('data_inicio', nextMonth.toISOString());
  const visits = (monthRows ?? []).filter((row) => {
    const status = String(row.status ?? '').toLowerCase();
    return status !== 'cancelado' && status !== 'canceled' && status !== 'cancelled';
  }).length;

  return {
    user: {
      name: rawName,
      firstName: rawName.split(' ')[0] || rawName,
      avatarUrl: String(profile?.avatar_url ?? '') || GUEST_AVATAR,
      membershipTier: active ? String(plan?.name ?? 'Clube VIP') : 'Sem plano',
      membershipTierId: active ? String(plan?.id ?? '') : '',
      loyaltyPoints: Number(loyalty?.points ?? 0),
      visitsThisMonth: visits,
      memberSince: loyalty?.member_since
        ? new Date(`${loyalty.member_since}T12:00:00`).getFullYear().toString()
        : '—',
      nextRewardAt: Number(settings?.reward_at ?? 1500),
    },
  };
}

async function loadUpcoming(barbershopId: string, userId: string): Promise<Appointment | null> {
  const now = new Date().toISOString();
  const { data, error } = await supabase
    .from('agendamentos')
    .select('id, data_inicio, status, charged_price, barbeiros(nome, foto_url), servicos(nome, preco)')
    .eq('cliente_id', userId)
    .eq('barbershop_id', barbershopId)
    .gte('data_inicio', now)
    .order('data_inicio', { ascending: true })
    .limit(5);
  if (error || !data) return null;
  const row = data.find((item) => {
    const status = String(item.status ?? '').toLowerCase();
    return status !== 'cancelado' && status !== 'cancelled';
  });
  if (!row) return null;
  const when = new Date(String(row.data_inicio));
  const barber = firstJoin(row.barbeiros) as { nome?: string; foto_url?: string } | null;
  const service = firstJoin(row.servicos) as { nome?: string; preco?: number } | null;
  return {
    id: String(row.id),
    serviceName: String(service?.nome ?? 'Serviço'),
    barberName: String(barber?.nome ?? 'Barbeiro'),
    barberAvatarUrl: String(barber?.foto_url ?? '') || GUEST_AVATAR,
    date: when.toLocaleDateString('pt-BR', { weekday: 'long', day: 'numeric', month: 'long' }),
    time: when.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' }),
    price: Number(row.charged_price ?? service?.preco ?? 0),
    status: 'confirmed',
    startsAt: when.toISOString(),
  };
}

function firstJoin(value: unknown): Record<string, unknown> | null {
  if (Array.isArray(value)) return (value[0] as Record<string, unknown>) ?? null;
  if (value && typeof value === 'object') return value as Record<string, unknown>;
  return null;
}

async function ensureClientProfile(
  barbershopId: string,
  authUser: { id: string; email?: string; user_metadata?: Record<string, unknown> },
) {
  const existing = await supabase
    .from('users')
    .select('id, role, barbershop_id')
    .eq('id', authUser.id)
    .maybeSingle();
  if (existing.error) throw new Error(existing.error.message);
  const name =
    String(authUser.user_metadata?.nome ?? authUser.user_metadata?.full_name ?? '').trim() ||
    authUser.email?.split('@')[0] ||
    'Cliente';
  if (!existing.data) {
    const inserted = await supabase.from('users').insert({
      id: authUser.id,
      nome: name,
      role: 'cliente',
      barbershop_id: barbershopId,
    });
    if (inserted.error) throw new Error(inserted.error.message);
    return;
  }
  const role = String(existing.data.role ?? '').trim().toLowerCase();
  const currentShop = String(existing.data.barbershop_id ?? '');
  const shouldBind =
    currentShop !== barbershopId &&
    (role === 'cliente' || role === '' || currentShop === '');
  if (!shouldBind) return;
  const updated = await supabase
    .from('users')
    .update({ barbershop_id: barbershopId })
    .eq('id', authUser.id);
  if (updated.error) throw new Error(updated.error.message);
}
