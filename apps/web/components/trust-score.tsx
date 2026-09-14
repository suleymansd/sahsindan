import { cn } from "@/lib/utils";

export function TrustScore({ score }: { score: number }) {
  const value = Math.max(0, Math.min(100, score));
  return (
    <div className="flex items-center gap-4 rounded-xl bg-surface-2 p-4">
      <div className="relative h-20 w-20 shrink-0">
        <svg
          viewBox="0 0 100 100"
          className="h-full w-full -rotate-90"
          aria-hidden="true"
        >
          <circle
            cx="50"
            cy="50"
            r="42"
            fill="none"
            stroke="hsl(var(--border))"
            strokeWidth="7"
          />
          <circle
            cx="50"
            cy="50"
            r="42"
            fill="none"
            stroke="currentColor"
            strokeWidth="7"
            strokeLinecap="round"
            strokeDasharray={`${value * 2.639} 263.9`}
            className={cn(
              value >= 80
                ? "text-accent"
                : value >= 50
                  ? "text-warning"
                  : "text-text-muted",
            )}
          />
        </svg>
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <span className="font-display text-2xl font-semibold">{value}</span>
          <span className="text-[9px] text-text-muted">/ 100</span>
        </div>
      </div>
      <div>
        <p className="text-sm font-semibold">Satıcı güven puanı</p>
        <p className="mt-1 text-xs leading-5 text-text-muted">
          Doğrulama, randevu ve
          <br />
          topluluk geri bildirimleri.
        </p>
      </div>
    </div>
  );
}
