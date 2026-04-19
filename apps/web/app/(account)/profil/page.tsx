"use client";

import { useQuery } from "@tanstack/react-query";

import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { apiFetchWithAuth } from "@/lib/api";
import { useAuth } from "@/lib/auth";

const roleLabels: Record<string, string> = {
  ADMIN: "Yönetici",
  MODERATOR: "Moderatör",
  USER_VERIFIED: "Doğrulanmış Üye",
  USER_PENDING: "Doğrulama Bekliyor",
  BANNED: "Engelli",
};

export default function ProfilePage() {
  const { accessToken, user } = useAuth();

  const { data, isLoading: statusLoading, isError: statusError, refetch: refetchStatus } = useQuery({
    queryKey: ["verification-status"],
    queryFn: async () => {
      if (!accessToken) return null;
      const res = await apiFetchWithAuth("/verification/status", accessToken);
      return res.data as { status: string; reason?: string };
    },
    enabled: Boolean(accessToken),
  });

  const canTrust =
    user?.role === "USER_VERIFIED" || user?.role === "ADMIN" || user?.role === "MODERATOR";

  const { data: trust, isLoading: trustLoading, isError: trustError, refetch: refetchTrust } = useQuery({
    queryKey: ["trust-breakdown"],
    queryFn: async () => {
      if (!accessToken) return null;
      const res = await apiFetchWithAuth("/profile/trust", accessToken);
      return res.data as {
        total: number;
        base: number;
        profession: number;
        completed_appointments: number;
        no_show_penalty: number;
        report_penalty: number;
      };
    },
    enabled: Boolean(accessToken && canTrust),
  });

  return (
    <main className="container py-12">
      <h1 className="font-display text-3xl font-semibold">Profilim</h1>
      {!accessToken ? (
        <div className="mt-6 rounded-card border border-border p-8 text-sm text-muted-foreground">
          Profil bilgileri için giriş yapmalısınız.
        </div>
      ) : null}
      <div className="mt-8 grid gap-6 md:grid-cols-2">
        <Card>
          <CardContent className="space-y-4 p-6">
            <div className="text-sm text-muted-foreground">Hesap</div>
            <div className="text-lg font-semibold">{user?.email || "-"}</div>
            <div className="text-sm">Rol: {roleLabels[user?.role || ""] || user?.role}</div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="space-y-4 p-6">
            <div className="text-sm text-muted-foreground">Güven Skoru</div>
            {trustLoading ? (
              <Skeleton className="h-16 w-full" />
            ) : trustError ? (
              <div className="text-sm text-muted-foreground">
                Güven skoru yüklenemedi.
                <button type="button" className="ml-2 text-primary" onClick={() => refetchTrust()}>
                  Tekrar dene
                </button>
              </div>
            ) : (
              <>
                <div className="text-3xl font-semibold">{trust?.total ?? user?.trust_score ?? 0}</div>
                <div className="space-y-2 text-sm text-muted-foreground">
                  <div>Temel: +{trust?.base ?? 0}</div>
                  <div>Meslek: +{trust?.profession ?? 0}</div>
                  <div>Randevu: +{trust?.completed_appointments ?? 0}</div>
                  <div>Gelmeme: -{trust?.no_show_penalty ?? 0}</div>
                  <div>Rapor: -{trust?.report_penalty ?? 0}</div>
                </div>
              </>
            )}
          </CardContent>
        </Card>
        <Card>
          <CardContent className="space-y-4 p-6">
            <div className="text-sm text-muted-foreground">Doğrulama</div>
            {statusLoading ? (
              <Skeleton className="h-10 w-full" />
            ) : statusError ? (
              <div className="text-sm text-muted-foreground">
                Doğrulama bilgisi yüklenemedi.
                <button type="button" className="ml-2 text-primary" onClick={() => refetchStatus()}>
                  Tekrar dene
                </button>
              </div>
            ) : (
              <>
                <div className="text-lg font-semibold">{data?.status || "-"}</div>
                {data?.reason ? <div className="text-sm text-rose-600">{data.reason}</div> : null}
              </>
            )}
          </CardContent>
        </Card>
        <Card>
          <CardContent className="space-y-4 p-6">
            <div className="text-sm text-muted-foreground">Aktivite</div>
            <div className="text-sm text-muted-foreground">Yanıt süresi ve randevu istatistikleri burada görünür.</div>
          </CardContent>
        </Card>
      </div>
    </main>
  );
}
