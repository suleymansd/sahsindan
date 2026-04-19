"use client";

import Link from "next/link";
import { useState } from "react";
import { useQuery } from "@tanstack/react-query";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { apiFetchWithAuth } from "@/lib/api";
import { useAuth } from "@/lib/auth";

type ReportItem = {
  id: number;
  listing_id?: number | null;
  target_type: string;
  target_id: number | null;
  reason: string;
  category?: string | null;
  status: string;
  created_at: string;
  reporter?: { id: number; email: string };
};

export default function ReportsAdminPage() {
  const { accessToken } = useAuth();
  const [status, setStatus] = useState("all");
  const [type, setType] = useState("all");
  const [category, setCategory] = useState("");

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["admin-reports", status, type, category],
    queryFn: async () => {
      if (!accessToken) return { data: [], meta: {} };
      const params = new URLSearchParams();
      if (status !== "all") params.set("status", status);
      if (type !== "all") params.set("report_type", type);
      if (category) params.set("reason", category);
      const res = await apiFetchWithAuth(`/admin/reports?${params.toString()}`, accessToken);
      return res as { data: ReportItem[]; meta: { total: number } };
    },
    enabled: Boolean(accessToken),
  });

  return (
    <div className="space-y-6">
      <div className="panel-glass p-5">
        <div className="text-sm text-text-muted">Rapor Yönetimi</div>
        <h1 className="mt-1 font-display text-2xl font-semibold">Raporlar</h1>
      </div>

      <Card>
        <CardContent className="grid gap-4 p-6 md:grid-cols-3">
          <select
            value={status}
            onChange={(event) => setStatus(event.target.value)}
            className="h-12 w-full rounded-btn border border-border/85 bg-surface/90 px-3 text-sm shadow-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          >
            <option value="all">Tüm durumlar</option>
            <option value="OPEN">Açık</option>
            <option value="IN_REVIEW">İncelemede</option>
            <option value="RESOLVED">Çözüldü</option>
          </select>
          <select
            value={type}
            onChange={(event) => setType(event.target.value)}
            className="h-12 w-full rounded-btn border border-border/85 bg-surface/90 px-3 text-sm shadow-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          >
            <option value="all">Tüm türler</option>
            <option value="listing">İlan</option>
            <option value="user">Kullanıcı</option>
            <option value="thread">Mesaj</option>
          </select>
          <Input placeholder="Sebep kategorisi" value={category} onChange={(event) => setCategory(event.target.value)} />
        </CardContent>
      </Card>

      {isLoading ? (
        <div className="space-y-3">
          {Array.from({ length: 6 }).map((_, idx) => (
            <Skeleton key={idx} className="h-16 w-full" />
          ))}
        </div>
      ) : null}

      {isError ? (
        <Card>
          <CardContent className="flex items-center justify-between gap-3 p-6 text-sm text-text-muted">
            Liste yüklenemedi.
            <Button variant="outline" size="sm" onClick={() => refetch()}>
              Tekrar dene
            </Button>
          </CardContent>
        </Card>
      ) : null}

      {data?.data?.length ? (
        <div className="space-y-3">
          {data.data.map((report) => (
            <Card key={report.id}>
              <CardContent className="flex flex-wrap items-center justify-between gap-4 p-5 text-sm">
                <div>
                  <div className="font-medium">{report.reason}</div>
                  <div className="flex flex-wrap items-center gap-2 text-xs text-text-muted">
                    <span>{report.category || "Genel"}</span>
                    <Badge
                      variant={
                        report.status === "RESOLVED"
                          ? "success"
                          : report.status === "IN_REVIEW"
                            ? "warning"
                            : "neutral"
                      }
                    >
                      {report.status}
                    </Badge>
                  </div>
                  {report.reporter ? <div className="text-xs text-text-muted">{report.reporter.email}</div> : null}
                </div>
                <Button size="sm" asChild>
                  <Link href={`/admin/raporlar/${report.id}`}>İncele</Link>
                </Button>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : (
        !isLoading && (
          <Card>
            <CardContent className="p-6 text-sm text-text-muted">Sonuç bulunamadı.</CardContent>
          </Card>
        )
      )}
    </div>
  );
}
