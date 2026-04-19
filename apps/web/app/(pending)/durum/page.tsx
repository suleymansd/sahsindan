"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { apiFetchWithAuth } from "@/lib/api";
import { useAuth } from "@/lib/auth";

const statusCopy: Record<string, { label: string; tone: "success" | "warning" | "neutral" } > = {
  NOT_SUBMITTED: { label: "Doğrulama başlatılmadı", tone: "neutral" },
  PENDING: { label: "İnceleniyor", tone: "warning" },
  APPROVED: { label: "Onaylandı", tone: "success" },
  REJECTED: { label: "Reddedildi", tone: "warning" },
};

export default function VerificationStatusPage() {
  const { accessToken } = useAuth();

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["verification-status"],
    queryFn: async () => {
      if (!accessToken) return null;
      const res = await apiFetchWithAuth("/verification/status", accessToken);
      return res.data as { status: string; reason?: string };
    },
    enabled: Boolean(accessToken),
  });

  const status = data?.status || "NOT_SUBMITTED";
  const copy = statusCopy[status] || statusCopy.NOT_SUBMITTED;

  return (
    <main className="container py-12">
      <div className="space-y-3">
        <Badge variant="success">Doğrulama Durumu</Badge>
        <h1 className="font-display text-3xl font-semibold">Hesap doğrulaman</h1>
        <p className="text-sm text-muted-foreground">
          İlanları görebilmek için doğrulama sürecini tamamlamalısın.
        </p>
      </div>

      <Card className="mt-8">
        <CardContent className="space-y-4 p-6">
          {isLoading ? (
            <Skeleton className="h-24 w-full" />
          ) : isError ? (
            <div className="flex items-center justify-between text-sm text-muted-foreground">
              Durum yüklenemedi.
              <Button variant="outline" size="sm" onClick={() => refetch()}>
                Tekrar dene
              </Button>
            </div>
          ) : (
            <>
              <div className="flex items-center justify-between">
                <div>
                  <div className="text-sm text-muted-foreground">Durum</div>
                  <div className="text-xl font-semibold">{copy.label}</div>
                </div>
                <Badge variant={copy.tone}>{status}</Badge>
              </div>
              {data?.reason ? <div className="text-sm text-rose-600">{data.reason}</div> : null}
              <div className="flex flex-wrap gap-3">
                {status !== "APPROVED" ? (
                  <Button asChild>
                    <Link href="/dogrulama">Doğrulamayı Tamamla</Link>
                  </Button>
                ) : (
                  <Button asChild>
                    <Link href="/app">Ana Sayfaya Git</Link>
                  </Button>
                )}
                <Button variant="outline" asChild>
                  <Link href="/yardim">Yardım</Link>
                </Button>
              </div>
            </>
          )}
        </CardContent>
      </Card>
    </main>
  );
}
