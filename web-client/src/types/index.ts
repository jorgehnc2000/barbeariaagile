export type ViewId = 'home' | 'booking' | 'vip';

export interface Service {
  id: string;
  name: string;
  description: string;
  price: number;
  durationMin: number;
  icon: string;
}

export interface Barber {
  id: string;
  name: string;
  role: string;
  rating: number;
  reviews: number;
  avatarUrl: string;
  specialties: string[];
}

export interface Appointment {
  id: string;
  serviceName: string;
  barberName: string;
  barberAvatarUrl: string;
  date: string;
  time: string;
  price: number;
  status: 'confirmed' | 'completed' | 'cancelled';
  startsAt?: string;
}

export interface VipPlan {
  id: string;
  name: string;
  price: number;
  period: string;
  tagline: string;
  highlighted: boolean;
  badge?: string;
  benefits: string[];
  mpPlanId?: string;
}

export interface UserProfile {
  name: string;
  firstName: string;
  avatarUrl: string;
  membershipTier: string;
  membershipTierId: string;
  loyaltyPoints: number;
  visitsThisMonth: number;
  memberSince: string;
  nextRewardAt: number;
}
