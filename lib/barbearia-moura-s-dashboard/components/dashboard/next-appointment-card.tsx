import { Calendar, ChevronRight } from "lucide-react"

export function NextAppointmentCard() {
  return (
    <section className="rounded-3xl border border-border bg-card p-6 transition-all duration-200 hover:border-border/80">
      <div className="flex items-center gap-2 text-primary">
        <Calendar className="h-4 w-4" />
        <span className="text-xs font-medium uppercase tracking-wider">Próximo agendamento</span>
      </div>

      <div className="mt-5 flex items-center gap-4">
        <img
          src="/images/barber-murilo.png"
          alt="Foto do barbeiro Murilo"
          className="h-14 w-14 rounded-2xl border border-border object-cover"
        />
        <div className="min-w-0 flex-1">
          <h3 className="text-lg font-semibold tracking-tight text-foreground">Barba</h3>
          <p className="truncate text-sm text-muted-foreground">
            com Murilo · 02 Ago 2026 · 09h30
          </p>
        </div>
        <div className="text-right">
          <span className="block text-lg font-bold tracking-tight text-primary">R$ 10,00</span>
          <span className="text-xs text-muted-foreground">confirmado</span>
        </div>
      </div>

      <a
        href="#"
        className="mt-5 flex items-center justify-between rounded-xl border border-border bg-secondary/40 px-4 py-3 text-sm font-medium text-foreground transition-all duration-200 hover:border-border/80 hover:bg-secondary"
      >
        Ver detalhes do agendamento
        <ChevronRight className="h-4 w-4 text-muted-foreground" />
      </a>
    </section>
  )
}
