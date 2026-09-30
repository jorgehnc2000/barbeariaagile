"use client"

import Image from "next/image"
import { Calendar, Clock, Scissors, User } from "lucide-react"
import { type Barber, type Service, formatBRL } from "@/lib/booking-data"

function Row({
  icon,
  label,
  value,
}: {
  icon: React.ReactNode
  label: string
  value: string
}) {
  return (
    <div className="flex items-center gap-3 py-3">
      <span className="flex h-9 w-9 items-center justify-center rounded-lg border border-border bg-secondary text-muted-foreground">
        {icon}
      </span>
      <div className="min-w-0 flex-1">
        <p className="text-xs text-muted-foreground">{label}</p>
        <p className="truncate text-sm font-medium text-foreground">{value}</p>
      </div>
    </div>
  )
}

export function SummaryPanel({
  service,
  barber,
  dateLabel,
  time,
}: {
  service: Service | null
  barber: Barber
  dateLabel: string
  time: string | null
}) {
  return (
    <div className="rounded-2xl border border-border bg-card p-6">
      <p className="text-xs font-medium uppercase tracking-wider text-primary">Resumo do agendamento</p>
      <h2 className="mt-1 text-balance text-2xl font-bold tracking-tight text-foreground">
        Jorge, pronto para o seu corte?
      </h2>
      <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
        Confira os detalhes abaixo e confirme quando estiver tudo certo.
      </p>

      <div className="mt-5 flex items-center gap-3 rounded-xl border border-border bg-secondary/40 p-3">
        <span className="relative h-12 w-12 shrink-0 overflow-hidden rounded-lg border border-border">
          <Image src={barber.image || "/placeholder.svg"} alt={barber.name} fill sizes="48px" className="object-cover" />
        </span>
        <div>
          <p className="text-sm font-semibold text-foreground">{barber.name}</p>
          <p className="text-xs text-muted-foreground">{barber.role}</p>
        </div>
      </div>

      <div className="mt-3 divide-y divide-border">
        <Row icon={<Scissors className="h-4 w-4" />} label="Serviço" value={service ? service.name : "Selecione um serviço"} />
        <Row icon={<User className="h-4 w-4" />} label="Barbeiro" value={barber.name} />
        <Row icon={<Calendar className="h-4 w-4" />} label="Data" value={dateLabel} />
        <Row icon={<Clock className="h-4 w-4" />} label="Horário" value={time ?? "A escolher"} />
      </div>
    </div>
  )
}
