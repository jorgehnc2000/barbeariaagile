import { ArrowRight } from "lucide-react"

export function HeroCta() {
  return (
    <section className="group relative overflow-hidden rounded-3xl border border-border">
      <img
        src="/images/barbershop-interior.png"
        alt="Interior da Barbearia Moura's com cadeiras de barbeiro e iluminação quente"
        className="absolute inset-0 h-full w-full object-cover transition-transform duration-700 ease-out group-hover:scale-105"
      />
      <div className="absolute inset-0 bg-gradient-to-t from-background via-background/70 to-background/10" />
      <div className="absolute inset-0 bg-gradient-to-r from-background/80 to-transparent" />

      <div className="relative flex min-h-[420px] flex-col justify-end p-6 sm:min-h-[480px] sm:p-8 lg:p-10">
        <span className="mb-4 inline-flex w-fit items-center gap-2 rounded-full border border-primary/30 bg-primary/10 px-3 py-1 text-xs font-medium uppercase tracking-wider text-primary">
          Barbearia Moura&apos;s
        </span>
        <h2 className="max-w-md text-balance text-4xl font-bold leading-[1.05] tracking-tight text-foreground sm:text-5xl">
          Pronto para elevar seu estilo?
        </h2>
        <p className="mt-4 max-w-sm text-pretty text-sm leading-relaxed text-muted-foreground">
          Reserve seu horário em segundos e viva a experiência premium que você merece.
        </p>
        <a
          href="#"
          className="mt-7 inline-flex w-fit items-center gap-2 rounded-xl bg-primary px-6 py-3.5 text-sm font-semibold text-primary-foreground shadow-lg shadow-primary/25 transition-all duration-200 hover:bg-primary/90 hover:shadow-primary/40 active:scale-[0.98]"
        >
          Agendar agora
          <ArrowRight className="h-4 w-4 transition-transform duration-200 group-hover:translate-x-0.5" />
        </a>
      </div>
    </section>
  )
}
