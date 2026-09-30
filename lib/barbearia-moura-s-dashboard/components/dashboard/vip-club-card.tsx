import { Medal, AlertCircle, ArrowRight } from "lucide-react"

export function VipClubCard() {
  return (
    <section className="relative overflow-hidden rounded-3xl border border-primary/25 bg-gradient-to-br from-primary/[0.14] via-card to-card p-6 transition-all duration-200 hover:border-primary/40">
      <div className="flex items-start justify-between gap-4">
        <div className="flex items-center gap-3">
          <span className="flex h-11 w-11 items-center justify-center rounded-2xl border border-primary/30 bg-primary/15 text-primary">
            <Medal className="h-5 w-5" />
          </span>
          <div>
            <h3 className="text-base font-semibold tracking-tight text-foreground">Clube VIP</h3>
            <span className="mt-1 inline-flex items-center gap-1.5 rounded-full bg-destructive/15 px-2.5 py-0.5 text-xs font-medium text-destructive">
              <span className="h-1.5 w-1.5 rounded-full bg-destructive" />
              Assinatura pausada
            </span>
          </div>
        </div>
      </div>

      <div className="mt-5 flex items-start gap-2 rounded-2xl border border-border/60 bg-background/40 p-4">
        <AlertCircle className="mt-0.5 h-4 w-4 shrink-0 text-primary" />
        <p className="text-sm leading-relaxed text-muted-foreground">
          Sua assinatura está pausada. Atualize o cartão para reativar cortes ilimitados, descontos e
          prioridade no agendamento.
        </p>
      </div>

      <a
        href="#"
        className="group mt-5 inline-flex w-full items-center justify-center gap-2 rounded-xl bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground shadow-lg shadow-primary/25 transition-all duration-200 hover:bg-primary/90 hover:shadow-primary/40 active:scale-[0.98]"
      >
        Regularizar agora
        <ArrowRight className="h-4 w-4 transition-transform duration-200 group-hover:translate-x-0.5" />
      </a>
    </section>
  )
}
