"use client"

import { Check, Clock, Scissors } from "lucide-react"
import { type Service, formatBRL } from "@/lib/booking-data"

export function ServiceCard({
  service,
  selected,
  onSelect,
}: {
  service: Service
  selected: boolean
  onSelect: () => void
}) {
  return (
    <button
      type="button"
      onClick={onSelect}
      aria-pressed={selected}
      className={`group relative flex w-full items-center gap-4 rounded-2xl border p-4 text-left transition-all duration-200 ${
        selected
          ? "border-primary/70 bg-primary/10 shadow-lg shadow-primary/10"
          : "border-border bg-card hover:border-primary/40 hover:bg-secondary/50"
      }`}
    >
      <span
        className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-xl border transition-colors ${
          selected ? "border-primary/40 bg-primary/15 text-primary" : "border-border bg-secondary text-muted-foreground"
        }`}
      >
        <Scissors className="h-5 w-5" />
      </span>

      <span className="min-w-0 flex-1">
        <span className="flex items-center justify-between gap-2">
          <span className="truncate text-sm font-semibold text-foreground">{service.name}</span>
          <span className="shrink-0 text-sm font-semibold text-primary">{formatBRL(service.price)}</span>
        </span>
        <span className="mt-1 flex items-center gap-3 text-xs text-muted-foreground">
          <span className="flex items-center gap-1">
            <Clock className="h-3.5 w-3.5" />
            {service.duration} min
          </span>
          <span className="truncate">{service.description}</span>
        </span>
      </span>

      <span
        className={`flex h-5 w-5 shrink-0 items-center justify-center rounded-full border transition-all ${
          selected ? "border-primary bg-primary text-primary-foreground" : "border-border bg-transparent"
        }`}
      >
        {selected && <Check className="h-3.5 w-3.5" />}
      </span>
    </button>
  )
}
