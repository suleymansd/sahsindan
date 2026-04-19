import { Badge } from "@/components/ui/badge";

export function ListingBadge({ state, staleState }: { state: string; staleState?: string | null }) {
  if (state === "SOLD") {
    return <Badge variant="danger">Satıldı</Badge>;
  }
  if (state === "ARCHIVED") {
    return <Badge variant="neutral">Arşivlendi</Badge>;
  }
  if (state === "REJECTED") {
    return <Badge variant="danger">Reddedildi</Badge>;
  }
  if (staleState === "NEEDS_CONFIRMATION") {
    return <Badge variant="warning">Onay Bekliyor</Badge>;
  }
  return <Badge variant="success">Yayında</Badge>;
}

export function TrustBadge({ score }: { score: number }) {
  if (score >= 80) {
    return <Badge variant="success">Güven {score}</Badge>;
  }
  if (score >= 50) {
    return <Badge variant="warning">Güven {score}</Badge>;
  }
  return <Badge variant="neutral">Güven {score}</Badge>;
}

export function ResponseStats({ responseTime, lastActive }: { responseTime?: string | null; lastActive: string }) {
  return (
    <div className="rounded-card border border-border/70 bg-muted/60 p-3 text-xs text-muted-foreground">
      <div>
        <span className="font-semibold text-foreground">Yanıt:</span>{" "}
        {responseTime || "Yeni satıcı, yanıt süresi oluşuyor"}
      </div>
      <div className="mt-1">
        <span className="font-semibold text-foreground">Aktiflik:</span> {lastActive || "Yakın zamanda aktifti"}
      </div>
    </div>
  );
}
