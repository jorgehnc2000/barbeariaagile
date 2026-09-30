"use client"

import { useMemo, useState } from "react"
import { Check, CheckCircle2 } from "lucide-react"
import {
  barbers,
  services,
  getUpcomingDays,
  formatBRL,
} from "@/lib/booking-data"
import { ServiceCard } from "./service-card"
import { BarberCard } from "./barber-card"
import { SchedulePanel } from "./schedule-panel"
import { SummaryPanel } from "./summary-panel"

type Tab = "servicos" | "barbeiros"

export function BookingFlow() {
  const days = useMemo(() => getUpcomingDays(7), [])

  const [tab, setTab] = useState<Tab>("servicos")
  const [serviceId, setServiceId] = useState<string>(services[0].id)
  const [barberId, setBarberId] = useState<string>(barbers[0].id)
  const [selectedDay, setSelectedDay] = useState<string>(days[0].iso)
  const [selectedTime, setSelectedTime] = useState<string | null>(null)
  const [confirmed, setConfirmed] = useState(false)

  const service = services.find((s) => s.id === serviceId) ?? null
  const barber = barbers.find((b) => b.id === barberId) ?? barbers[0]

  const dateLabel = useMemo(() => {
    const d = new Date(`${selectedDay}T00:00:00`)
    return d.toLocaleDateString("pt-BR", { weekday: "long", day: "2-digit", month: "long" })
  }, [selectedDay])

  const canConfirm = Boolean(service && selectedTime)

  function handleConfirm() {
    if (!canConfirm) return
    setConfirmed(true)
  }

  function resetSelection() {
    setConfirmed(false)
    setSelectedTime(null)
  }

  if (confirmed && service) {
    return (
      <div className="mx-auto max-w-md rounded-2xl border border-primary/40 bg-card p-8 text-center">
        <span className="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-primary/15 text-primary">
          <CheckCircle2 className="h-7 w-7" />
        </span>
        <h2 className="mt-4 text-xl font-bold text-foreground">Agendamento confirmado!</h2>
        <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
          {service.name} com {barber.name} · {dateLabel} às {selectedTime}.
        </p>
        <p className="mt-1 text-sm font-semibold text-primary">{formatBRL(service.price)}</p>
        <button
          type="button"
          onClick={resetSelection}
          className="mt-6 w-full rounded-xl border border-border bg-secondary py-3 text-sm font-medium text-foreground transition-colors hover:bg-secondary/70"
        >
          Fazer outro agendamento
        </button>
      </div>
    )
  }

  return (
    <div className="grid gap-6 lg:grid-cols-[1fr_1.15fr]">
      {/* Left: selection */}
      <section aria-label="Seleção de serviço e barbeiro" className="space-y-4">
        <div className="grid grid-cols-2 gap-1 rounded-xl border border-border bg-card p-1">
          <button
            type="button"
            onClick={() => setTab("servicos")}
            aria-pressed={tab === "servicos"}
            className={`rounded-lg py-2.5 text-sm font-medium transition-all ${
              tab === "servicos" ? "bg-primary text-primary-foreground shadow" : "text-muted-foreground hover:text-foreground"
            }`}
          >
            Serviços
          </button>
          <button
            type="button"
            onClick={() => setTab("barbeiros")}
            aria-pressed={tab === "barbeiros"}
            className={`rounded-lg py-2.5 text-sm font-medium transition-all ${
              tab === "barbeiros" ? "bg-primary text-primary-foreground shadow" : "text-muted-foreground hover:text-foreground"
            }`}
          >
            Barbeiros
          </button>
        </div>

        <div className="space-y-3">
          {tab === "servicos"
            ? services.map((s) => (
                <ServiceCard key={s.id} service={s} selected={serviceId === s.id} onSelect={() => setServiceId(s.id)} />
              ))
            : barbers.map((b) => (
                <BarberCard key={b.id} barber={b} selected={barberId === b.id} onSelect={() => setBarberId(b.id)} />
              ))}
        </div>

        <SummaryPanel service={service} barber={barber} dateLabel={dateLabel} time={selectedTime} />
      </section>

      {/* Right: schedule + confirm */}
      <section aria-label="Escolha de data e horário" className="space-y-6 rounded-2xl border border-border bg-card p-5 sm:p-6">
        <SchedulePanel
          days={days}
          selectedDay={selectedDay}
          onSelectDay={setSelectedDay}
          selectedTime={selectedTime}
          onSelectTime={setSelectedTime}
        />

        <div className="rounded-xl border border-border bg-secondary/40 p-4">
          <div className="flex items-center justify-between">
            <span className="text-sm text-muted-foreground">Valor total</span>
            <span className="text-2xl font-bold text-foreground">{service ? formatBRL(service.price) : "—"}</span>
          </div>
        </div>

        <div>
          <button
            type="button"
            onClick={handleConfirm}
            disabled={!canConfirm}
            className={`flex w-full items-center justify-center gap-2 rounded-xl py-4 text-sm font-semibold transition-all duration-200 ${
              canConfirm
                ? "bg-primary text-primary-foreground shadow-lg shadow-primary/20 hover:brightness-105 active:scale-[0.99]"
                : "cursor-not-allowed bg-secondary text-muted-foreground"
            }`}
          >
            <Check className="h-4 w-4" />
            Confirmar agendamento
          </button>
          <p className="mt-2 text-center text-xs text-muted-foreground">
            {canConfirm ? "Tudo pronto — é só confirmar." : "Selecione um horário para confirmar."}
          </p>
          <a
            href="/"
            className="mt-3 block text-center text-sm font-medium text-muted-foreground transition-colors hover:text-foreground"
          >
            Cancelar
          </a>
        </div>
      </section>
    </div>
  )
}
