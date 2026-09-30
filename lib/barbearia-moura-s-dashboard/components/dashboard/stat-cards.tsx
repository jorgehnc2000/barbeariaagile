import { Scissors, Users, Clock } from "lucide-react"

export function StatCards() {
  return (
    <div className="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-3">
      <StatCard icon={<Scissors className="h-4 w-4" />} label="Serviços" value="1" hint="disponíveis" />
      <StatCard icon={<Users className="h-4 w-4" />} label="Barbeiros" value="2" hint="na equipe" />
      <NextStatCard />
    </div>
  )
}

function StatCard({
  icon,
  label,
  value,
  hint,
}: {
  icon: React.ReactNode
  label: string
  value: string
  hint: string
}) {
  return (
    <div className="group rounded-2xl border border-border bg-card p-5 transition-all duration-200 hover:border-border/80 hover:bg-secondary/40">
      <div className="flex items-center gap-2 text-muted-foreground">
        <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-secondary text-muted-foreground transition-colors group-hover:text-foreground">
          {icon}
        </span>
        <span className="text-xs font-medium uppercase tracking-wider">{label}</span>
      </div>
      <div className="mt-4 flex items-baseline gap-2">
        <span className="text-3xl font-bold tracking-tight text-foreground">{value}</span>
        <span className="text-xs text-muted-foreground">{hint}</span>
      </div>
    </div>
  )
}

function NextStatCard() {
  return (
    <div className="group col-span-2 rounded-2xl border border-primary/25 bg-gradient-to-br from-primary/[0.12] to-primary/[0.02] p-5 transition-all duration-200 hover:border-primary/40 lg:col-span-1">
      <div className="flex items-center gap-2 text-primary">
        <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary/15 text-primary">
          <Clock className="h-4 w-4" />
        </span>
        <span className="text-xs font-medium uppercase tracking-wider">Próximo horário</span>
      </div>
      <div className="mt-4 flex items-baseline gap-2">
        <span className="text-3xl font-bold tracking-tight text-foreground">09:30</span>
        <span className="rounded-full bg-primary/15 px-2 py-0.5 text-xs font-medium text-primary">Barba</span>
      </div>
    </div>
  )
}
