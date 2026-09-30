"use client"

import Image from "next/image"
import { Check } from "lucide-react"
import type { Barber } from "@/lib/booking-data"

export function BarberCard({
  barber,
  selected,
  onSelect,
}: {
  barber: Barber
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
        className={`relative h-12 w-12 shrink-0 overflow-hidden rounded-xl border ${
          selected ? "border-primary/50" : "border-border"
        }`}
      >
        <Image src={barber.image || "/placeholder.svg"} alt={barber.name} fill sizes="48px" className="object-cover" />
      </span>

      <span className="min-w-0 flex-1">
        <span className="block truncate text-sm font-semibold text-foreground">{barber.name}</span>
        <span className="mt-0.5 block truncate text-xs text-muted-foreground">{barber.role}</span>
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
