export type Service = {
  id: string
  name: string
  duration: number // minutes
  price: number // BRL
  description: string
}

export type Barber = {
  id: string
  name: string
  role: string
  image: string
}

export const services: Service[] = [
  {
    id: "barba",
    name: "Barba",
    duration: 12,
    price: 10,
    description: "Modelagem e toalha quente",
  },
  {
    id: "corte",
    name: "Corte de cabelo",
    duration: 30,
    price: 25,
    description: "Corte na tesoura ou máquina",
  },
  {
    id: "corte-barba",
    name: "Corte + Barba",
    duration: 45,
    price: 32,
    description: "O combo completo",
  },
  {
    id: "sobrancelha",
    name: "Sobrancelha",
    duration: 10,
    price: 8,
    description: "Alinhamento na navalha",
  },
]

export const barbers: Barber[] = [
  {
    id: "murilo",
    name: "Murilo",
    role: "Barbeiro sênior",
    image: "/images/barber-murilo.png",
  },
  {
    id: "rafael",
    name: "Rafael",
    role: "Especialista em fade",
    image: "/images/barber-rafael.png",
  },
]

export const morningSlots = ["09:00", "09:30", "10:00", "10:30", "11:00", "11:30"]
export const afternoonSlots = ["13:00", "13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30"]

// Slots that are already booked (unavailable) for the demo
export const unavailableSlots = ["09:30", "14:00", "15:30"]

const weekdayLabels = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]

export type DayOption = {
  iso: string
  weekday: string
  day: number
}

export function getUpcomingDays(count = 7): DayOption[] {
  const today = new Date()
  return Array.from({ length: count }, (_, i) => {
    const d = new Date(today)
    d.setDate(today.getDate() + i)
    return {
      iso: d.toISOString().slice(0, 10),
      weekday: weekdayLabels[d.getDay()],
      day: d.getDate(),
    }
  })
}

export function formatBRL(value: number): string {
  return value.toLocaleString("pt-BR", { style: "currency", currency: "BRL" })
}
