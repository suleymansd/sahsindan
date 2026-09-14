"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { CalendarClock, MapPin } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/ui/empty-state";
import { Input } from "@/components/ui/input";
import { SectionHeader } from "@/components/section-header";
import { Skeleton } from "@/components/ui/skeleton";
import { toFriendlyError } from "@/lib/errors";
import { PageControls } from "@/components/page-controls";
import { apiFetchWithAuth } from "@/lib/api";
import { useAuth } from "@/lib/auth";

const STATUS_LABELS: Record<
  string,
  { label: string; variant: "success" | "warning" | "neutral" | "danger" }
> = {
  REQUESTED: { label: "Talep Edildi", variant: "warning" },
  ACCEPTED: { label: "Onaylandı", variant: "success" },
  DECLINED: { label: "Reddedildi", variant: "danger" },
  RESCHEDULED: { label: "Yeniden Planlandı", variant: "warning" },
  CANCELLED: { label: "İptal", variant: "neutral" },
  COMPLETED: { label: "Tamamlandı", variant: "success" },
  NO_SHOW: { label: "Gelmedi", variant: "danger" },
};

export default function AppointmentsPage() {
  const [page, setPage] = useState(0);
  const { accessToken, user } = useAuth();
  const [actionError, setActionError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [reschedule, setReschedule] = useState<Record<number, string>>({});

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["appointments", page],
    queryFn: async () => {
      if (!accessToken) return [];
      const res = await apiFetchWithAuth(`/appointments/inbox?limit=50&offset=${page * 50}`, accessToken);
      return res.data as Array<{
        id: number;
        status: string;
        listing_id: number;
        scheduled_at: string;
        seller_id: number;
        buyer_id: number;
        location?: string;
        notes?: string;
      }>;
    },
    enabled: Boolean(accessToken),
  });

  async function action(id: number, endpoint: string, body?: Record<string, unknown>) {
    if (!accessToken || busy) return;
    setBusy(true);
    setActionError(null);
    const params = body?.scheduled_at
      ? `?scheduled_at=${encodeURIComponent(String(body.scheduled_at))}`
      : "";
    try {
      await apiFetchWithAuth(`/appointments/${id}/${endpoint}${params}`, accessToken, { method: "POST" });
      await refetch();
    } catch (error) {
      setActionError(toFriendlyError(error));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="container py-10">
      <SectionHeader
        title="Randevular"
        description="Test sürüşü, ekspertiz ve görüşme randevularını yönet."
      />

      {accessToken && !isLoading && <PageControls page={page} count={data?.length ?? 0} onChange={setPage} />}
      {actionError && <p role="alert" className="mt-4 text-sm text-danger">{actionError}</p>}
      {!accessToken ? (
        <div className="mt-6 rounded-card border border-border bg-surface p-8 shadow-card">
          <EmptyState
            icon={CalendarClock}
            title="Randevuları görmek için giriş yap"
            description="Giriş yaptığında randevu listen burada görünür."
          />
        </div>
      ) : isLoading ? (
        <div className="mt-8 space-y-3">
          {Array.from({ length: 3 }).map((_, idx) => (
            <Skeleton key={idx} className="h-44 w-full" />
          ))}
        </div>
      ) : isError ? (
        <div className="mt-8 flex items-center justify-between rounded-card border border-border bg-surface p-5 shadow-card">
          <span className="text-sm text-text-muted">Randevular yüklenemedi.</span>
          <Button variant="outline" size="sm" onClick={() => refetch()}>
            Tekrar dene
          </Button>
        </div>
      ) : data && data.length ? (
        <div className="mt-8 space-y-4">
          {data.map((appointment) => {
            const status =
              STATUS_LABELS[appointment.status] ?? { label: appointment.status, variant: "neutral" };
            const isSeller = user?.id === appointment.seller_id;
            const canRespond = appointment.status === "REQUESTED" && isSeller;
            const canClose = ["ACCEPTED", "RESCHEDULED"].includes(appointment.status) && isSeller;
            const canCancel =
              ["REQUESTED", "ACCEPTED", "RESCHEDULED"].includes(appointment.status);

            return (
              <div
                key={appointment.id}
                className="rounded-card border border-border bg-surface p-5 shadow-card md:p-6"
              >
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div className="flex items-start gap-3">
                    <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-primary-light text-primary">
                      <CalendarClock className="h-5 w-5" />
                    </div>
                    <div>
                      <div className="text-xs font-medium uppercase tracking-wider text-text-muted">
                        İlan #{appointment.listing_id}
                      </div>
                      <div className="mt-0.5 text-title-md font-semibold text-foreground">
                        {new Date(appointment.scheduled_at).toLocaleString("tr-TR", {
                          dateStyle: "medium",
                          timeStyle: "short",
                        })}
                      </div>
                      {appointment.location && (
                        <div className="mt-1 inline-flex items-center gap-1 text-xs text-text-muted">
                          <MapPin className="h-3.5 w-3.5" />
                          {appointment.location}
                        </div>
                      )}
                    </div>
                  </div>
                  <div className="flex flex-col items-end gap-1.5">
                    <Badge variant={status.variant}>{status.label}</Badge>
                    <Badge variant="neutral">{isSeller ? "Satıcı" : "Alıcı"}</Badge>
                  </div>
                </div>

                {appointment.notes && (
                  <div className="mt-4 rounded-lg border border-border bg-surface-2 px-3 py-2 text-sm text-text-muted">
                    <span className="font-semibold text-foreground">Not:</span> {appointment.notes}
                  </div>
                )}

                <div className="mt-4 flex flex-wrap gap-2">
                  {canRespond && (
                    <>
                      <Button size="sm" onClick={() => action(appointment.id, "accept")}>
                        Kabul Et
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => action(appointment.id, "decline")}
                      >
                        Reddet
                      </Button>
                    </>
                  )}
                  {canClose && (
                    <>
                      <Button size="sm" onClick={() => action(appointment.id, "complete")}>
                        Tamamlandı
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => action(appointment.id, "no-show")}
                      >
                        Gelmedi
                      </Button>
                    </>
                  )}
                  {canCancel && (
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => action(appointment.id, "cancel")}
                    >
                      İptal Et
                    </Button>
                  )}
                </div>

                <div className="mt-4 border-t border-border pt-4">
                  <div className="text-xs font-medium text-foreground">Yeniden planla</div>
                  <div className="mt-2 grid gap-2 sm:grid-cols-[1fr_auto]">
                    <Input
                      type="datetime-local"
                      value={reschedule[appointment.id] || ""}
                      onChange={(event) =>
                        setReschedule((prev) => ({
                          ...prev,
                          [appointment.id]: event.target.value,
                        }))
                      }
                    />
                    <Button
                      variant="outline"
                      onClick={() =>
                        action(appointment.id, "reschedule", {
                          scheduled_at: reschedule[appointment.id],
                        })
                      }
                      disabled={!reschedule[appointment.id]}
                    >
                      Planla
                    </Button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        <div className="mt-8 rounded-card border border-dashed border-border bg-surface-2/60 p-10">
          <EmptyState
            icon={CalendarClock}
            title="Henüz randevu yok"
            description="İlan detayından randevu isteyerek başlayabilirsin."
          />
        </div>
      )}
    </div>
  );
}
