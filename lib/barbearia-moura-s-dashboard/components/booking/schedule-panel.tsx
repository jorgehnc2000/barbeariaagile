"use client"

import { type DayOption, morningSlots, afternoonSlots, unavailableSlots } from "@/lib/booking-data"

function SlotGrid({
  label,
  slots,
  selectedTime,
  onSelectTime,
}: {
  label: string
  slots: string[]
  selectedTime: string | null
  onSelectTime: (t: string) => void
}) {
  return (
    <div>
      <p className="mb-2 text-xs font-medium uppercase tracking-wider text-muted-foreground">{label}</p>
      <div className="grid grid-cols-3 gap-2 sm:grid-cols-4">
        {slots.map((time) => {
          const disabled = unavailableSlots.includes(time)
          const active = selectedTime === time
          return (
            <button
              key={time}
              type="button"
              disabled={disabled}
              onClick={() => onSelectTime(time)}
              aria-pressed={active}
              className={`rounded-xl border py-2.5 text-sm font-medium transition-all duration-200 ${
                disabled
                  ? "cursor-not-allowed border-border/50 bg-secondary/40 text-muted-foreground/40 line-through"
                  : active
                    ? "border-primary bg-primary text-primary-foreground shadow-lg shadow-primary/20"
                    : "border-primary/25 bg-card text-foreground hover:border-primary/70 hover:bg-primary/5"
              }`}
            >
              {time}
            </button>
          )
        })}
      </div>
    </div>
  )
}

export function SchedulePanel({
  days,
  selectedDay,
  onSelectDay,
  selectedTime,
  onSelectTime,
}: {
  days: DayOption[]
  selectedDay: string
  onSelectDay: (iso: string) => void
  selectedTime: string | null
  onSelectTime: (t: string) => void
}) {
  return (
    <div className="space-y-6">
      <div>
        <h3 className="mb-3 text-sm font-semibold text-foreground">Escolha o dia</h3>
        <div className="grid grid-cols-4 gap-2 sm:grid-cols-7">
          {days.map((d) => {
            const active = selectedDay === d.iso
            return (
              <button
                key={d.iso}
                type="button"
                onClick={() => onSelectDay(d.iso)}
                aria-pressed={active}
                className={`flex flex-col items-center gap-1 rounded-xl border py-3 transition-all duration-200 ${
                  active
                    ? "border-primary bg-primary/10 text-primary shadow-lg shadow-primary/10"
                    : "border-border bg-card text-muted-foreground hover:border-primary/40 hover:text-foreground"
                }`}
              >
                <span className="text-xs font-medium">{d.weekday}</span>
                <span className={`text-lg font-bold ${active ? "text-primary" : "text-foreground"}`}>{d.day}</span>
              </button>
            )
          })}
        </div>
      </div>

      <div>
        <h3 className="mb-3 text-sm font-semibold text-foreground">Horários disponíveis</h3>
        <div className="space-y-4">
          <SlotGrid label="Manhã" slots={morningSlots} selectedTime={selectedTime} onSelectTime={onSelectTime} />
          <SlotGrid label="Tarde" slots={afternoonSlots} selectedTime={selectedTime} onSelectTime={onSelectTime} />
        </div>
      </div>
    </div>
  )
}
