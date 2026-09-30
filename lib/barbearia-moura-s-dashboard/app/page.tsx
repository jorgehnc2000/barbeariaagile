import { SiteHeader } from "@/components/dashboard/site-header"
import { StatCards } from "@/components/dashboard/stat-cards"
import { HeroCta } from "@/components/dashboard/hero-cta"
import { VipClubCard } from "@/components/dashboard/vip-club-card"
import { NextAppointmentCard } from "@/components/dashboard/next-appointment-card"

export default function Page() {
  return (
    <div className="min-h-screen bg-background">
      <SiteHeader />

      <main className="mx-auto max-w-6xl px-4 py-8 sm:px-6 sm:py-10">
        <header className="mb-8">
          <p className="text-sm font-medium text-primary">Bom dia, Jorge</p>
          <h1 className="mt-1 text-3xl font-bold tracking-tight text-foreground text-balance sm:text-4xl">
            Sua central de estilo
          </h1>
          <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
            Você tem um agendamento hoje às 09:30. Tudo pronto para o seu próximo visual.
          </p>
        </header>

        <div className="mb-6">
          <StatCards />
        </div>

        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <HeroCta />
          <div className="flex flex-col gap-6">
            <VipClubCard />
            <NextAppointmentCard />
          </div>
        </div>
      </main>
    </div>
  )
}
