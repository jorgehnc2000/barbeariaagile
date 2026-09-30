import { SiteHeader } from "@/components/dashboard/site-header"
import { BookingFlow } from "@/components/booking/booking-flow"

export default function AgendarPage() {
  return (
    <div className="min-h-screen bg-background">
      <SiteHeader />
      <main className="mx-auto max-w-6xl px-4 py-8 sm:px-6 sm:py-10">
        <div className="mb-8">
          <p className="text-sm font-medium text-primary">Barbearia Moura&apos;s</p>
          <h1 className="mt-1 text-3xl font-bold tracking-tight text-foreground sm:text-4xl">Agendar</h1>
          <p className="mt-2 text-pretty text-sm leading-relaxed text-muted-foreground">
            Escolha seu serviço ou barbeiro — depois confirme o horário.
          </p>
        </div>
        <BookingFlow />
      </main>
    </div>
  )
}
