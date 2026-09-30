import type {
  Service,
  Barber,
  Appointment,
  VipPlan,
  UserProfile,
} from '@/types';

export const currentUser: UserProfile = {
  name: 'Jorge Moura',
  firstName: 'Jorge',
  avatarUrl:
    'https://images.pexels.com/photos/1681010/pexels-photo-1681010.jpeg?auto=compress&cs=tinysrgb&w=240&h=240&fit=crop',
  membershipTier: 'Plano Ultra',
  membershipTierId: 'plan-ultra',
  loyaltyPoints: 1240,
  visitsThisMonth: 3,
  memberSince: '2023',
  nextRewardAt: 1500,
};

export const services: Service[] = [
  {
    id: 'svc-cabelo',
    name: 'Cabelo',
    description: 'Corte moderno com acabamento degradê e finalização.',
    price: 45,
    durationMin: 40,
    icon: 'scissors',
  },
  {
    id: 'svc-barba',
    name: 'Barba',
    description: 'Toalha quente, navalhado e hidratação completa.',
    price: 35,
    durationMin: 30,
    icon: 'brush',
  },
  {
    id: 'svc-combo',
    name: 'Cabelo + Barba',
    description: 'O combo completo para um visual impecável.',
    price: 70,
    durationMin: 70,
    icon: 'sparkles',
  },
  {
    id: 'svc-sobrancelha',
    name: 'Sobrancelha',
    description: 'Design e alinhamento masculino com precisão.',
    price: 20,
    durationMin: 15,
    icon: 'eye',
  },
  {
    id: 'svc-pigmentacao',
    name: 'Pigmentação',
    description: 'Cobertura e definição de barba com pigmento.',
    price: 60,
    durationMin: 45,
    icon: 'palette',
  },
  {
    id: 'svc-hidratacao',
    name: 'Hidratação',
    description: 'Tratamento profundo para couro cabeludo e fios.',
    price: 50,
    durationMin: 35,
    icon: 'droplet',
  },
];

export const barbers: Barber[] = [
  {
    id: 'brb-murilo',
    name: 'Murilo Moura',
    role: 'Barbeiro & Fundador',
    rating: 4.9,
    reviews: 312,
    avatarUrl:
      'https://images.pexels.com/photos/2078265/pexels-photo-2078265.jpeg?auto=compress&cs=tinysrgb&w=240&h=240&fit=crop',
    specialties: ['Corte Clássico', 'Degradê'],
  },
  {
    id: 'brb-lucas',
    name: 'Lucas Almeida',
    role: 'Especialista em Barba',
    rating: 4.8,
    reviews: 198,
    avatarUrl:
      'https://images.pexels.com/photos/1043471/pexels-photo-1043471.jpeg?auto=compress&cs=tinysrgb&w=240&h=240&fit=crop',
    specialties: ['Barba', 'Navalhado'],
  },
  {
    id: 'brb-rafael',
    name: 'Rafael Costa',
    role: 'Barbeiro & Stylist',
    rating: 4.9,
    reviews: 264,
    avatarUrl:
      'https://images.pexels.com/photos/2182970/pexels-photo-2182970.jpeg?auto=compress&cs=tinysrgb&w=240&h=240&fit=crop',
    specialties: ['Styling', 'Pigmentação'],
  },
  {
    id: 'brb-diego',
    name: 'Diego Santos',
    role: 'Barbeiro',
    rating: 4.7,
    reviews: 141,
    avatarUrl:
      'https://images.pexels.com/photos/1681010/pexels-photo-1681010.jpeg?auto=compress&cs=tinysrgb&w=240&h=240&fit=crop',
    specialties: ['Sobrancelha', 'Hidratação'],
  },
];

export const upcomingAppointment: Appointment | null = {
  id: 'apt-1',
  serviceName: 'Cabelo + Barba',
  barberName: 'Murilo Moura',
  barberAvatarUrl:
    'https://images.pexels.com/photos/2078265/pexels-photo-2078265.jpeg?auto=compress&cs=tinysrgb&w=240&h=240&fit=crop',
  date: 'Sexta, 15 de Agosto',
  time: '14:30',
  price: 70,
  status: 'confirmed',
};

export const vipPlans: VipPlan[] = [
  {
    id: 'plan-trial',
    name: 'Teste',
    price: 0,
    period: '7 dias grátis',
    tagline: 'Conheça o clube sem compromisso.',
    highlighted: false,
    benefits: [
      '1 corte de cabelo gratuito',
      '10% off em produtos',
      'Acesso ao app exclusivo',
    ],
  },
  {
    id: 'plan-ultra',
    name: 'Plano Ultra',
    price: 89,
    period: 'por mês',
    tagline: 'O equilíbrio perfeito entre estilo e economia.',
    highlighted: true,
    badge: 'Mais Assinado',
    benefits: [
      'Cortes ilimitados no mês',
      'Barba grátis a cada 3 visitas',
      '15% off em produtos e tratamentos',
      'Prioridade no agendamento',
      'Brinde exclusivo do clube',
    ],
  },
  {
    id: 'plan-master',
    name: 'Master',
    price: 149,
    period: 'por mês',
    tagline: 'A experiência premium sem limites.',
    highlighted: false,
    benefits: [
      'Tudo do Plano Ultra',
      'Cabelo + Barba ilimitados',
      'Hidratação e pigmentação inclusas',
      'Atendimento em horário VIP',
      'Convite para eventos exclusivos',
    ],
  },
];

export const timeSlots: string[] = [
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

const unavailableSlots = new Set(['10:30', '11:30', '15:30', '18:00']);

export function isSlotAvailable(time: string): boolean {
  return !unavailableSlots.has(time);
}

export function getNextFourteenDays(): Date[] {
  const days: Date[] = [];
  const today = new Date();
  for (let i = 0; i < 14; i++) {
    days.push(new Date(today.getFullYear(), today.getMonth(), today.getDate() + i));
  }
  return days;
}
