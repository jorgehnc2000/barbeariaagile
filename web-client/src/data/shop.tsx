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
import { supabase } from '@/lib/supabase';
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

type ShopContextValue = {
  loading: boolean;
  error: string | null;
  slug: string | null;
  barbershopId: string | null;
  barbershopName: string;
  services: Service[];
  barbers: Barber[];
  plans: VipPlan[];
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
  const [currentUser, setCurrentUser] = useState<UserProfile>(guestUser);
  const [upcomingAppointment, setUpcomingAppointment] = useState<Appointment | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [occupiedTimes, setOccupiedTimes] = useState<Set<string>>(new Set());

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
    setLoading(true);
    setError(null);

    void (async () => {
      try {
        const shop = await supabase
          .from('barbershops')
          .select('id, slug')
          .eq('slug', slug)
          .maybeSingle();
        if (shop.error) throw shop.error;
        if (!shop.data) throw new Error(`Nenhuma barbearia encontrada para "${slug}".`);
        if (cancelled) return;

        const id = String(shop.data.id);
        setBarbershopId(id);

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
          .select('id, name, description, benefits, monthly_amount, frequency, active, mp_status')
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
        setPlans(
          (planRows.data ?? []).map((row, index) => mapPlan(row as Record<string, unknown>, index)),
        );

        const { data: authData } = await supabase.auth.getSession();
        const activeSession = authData.session;
        const userId = activeSession?.user.id;
        if (!userId || !activeSession || cancelled) {
          setCurrentUser(guestUser);
          setUpcomingAppointment(null);
          return;
        }

        const profile = await loadProfile(id, userId, activeSession.user);
        if (!cancelled) setCurrentUser(profile.user);
        const next = await loadUpcoming(id, userId);
        if (!cancelled) setUpcomingAppointment(next);
      } catch (cause) {
        if (!cancelled) {
          setError(cause instanceof Error ? cause.message : 'Falha ao carregar a barbearia.');
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [slug, session?.user.id]);

  const loadOccupied = useCallback(
    async (barberId: string, day: Date) => {
      if (!barbershopId) {
        setOccupiedTimes(new Set());
        return;
      }
      const start = new Date(day.getFullYear(), day.getMonth(), day.getDate());
      const end = new Date(start);
      end.setDate(end.getDate() + 1);
      const { data, error: queryError } = await supabase
        .from('agendamentos')
        .select('data_inicio, status')
        .eq('barbershop_id', barbershopId)
        .eq('barbeiro_id', barberId)
        .gte('data_inicio', start.toISOString())
        .lt('data_inicio', end.toISOString());
      if (queryError) {
        setOccupiedTimes(new Set());
        return;
      }
      const taken = new Set<string>();
      for (const row of data ?? []) {
        const status = String(row.status ?? '').toLowerCase();
        if (status === 'cancelado' || status === 'cancelled') continue;
        const when = new Date(String(row.data_inicio));
        const hh = String(when.getHours()).padStart(2, '0');
        const mm = String(when.getMinutes()).padStart(2, '0');
        taken.add(`${hh}:${mm}`);
      }
      setOccupiedTimes(taken);
    },
    [barbershopId],
  );

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
        openLegacyAccount('/login');
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
    },
    [barbershopId, openLegacyAccount, slug],
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
      currentUser,
      upcomingAppointment,
      session,
      timeSlots: TIME_SLOTS,
      occupiedTimes,
      loadOccupied,
      createBooking,
      openLegacyAccount,
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
      currentUser,
      upcomingAppointment,
      session,
      occupiedTimes,
      loadOccupied,
      createBooking,
      openLegacyAccount,
    ],
  );

  return <ShopContext.Provider value={value}>{children}</ShopContext.Provider>;
}

export function useShop() {
  const value = useContext(ShopContext);
  if (!value) throw new Error('useShop deve ficar dentro de ShopProvider.');
  return value;
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

async function loadProfile(
  barbershopId: string,
  userId: string,
  authUser: { email?: string; user_metadata?: Record<string, unknown> },
): Promise<{ user: UserProfile }> {
  const { data: profile } = await supabase
    .from('users')
    .select('nome')
    .eq('id', userId)
    .maybeSingle();
  const rawName =
    String(profile?.nome ?? '').trim() ||
    String(authUser.user_metadata?.nome ?? authUser.user_metadata?.full_name ?? '').trim() ||
    authUser.email?.split('@')[0] ||
    'Cliente';

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
  const { count } = await supabase
    .from('agendamentos')
    .select('id', { count: 'exact', head: true })
    .eq('cliente_id', userId)
    .eq('barbershop_id', barbershopId)
    .gte('data_inicio', monthStart.toISOString());

  return {
    user: {
      name: rawName,
      firstName: rawName.split(' ')[0] || rawName,
      avatarUrl: GUEST_AVATAR,
      membershipTier: active ? String(plan?.name ?? 'Clube VIP') : 'Sem plano',
      membershipTierId: active ? String(plan?.id ?? '') : '',
      loyaltyPoints: 0,
      visitsThisMonth: count ?? 0,
      memberSince: '—',
      nextRewardAt: 1,
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
