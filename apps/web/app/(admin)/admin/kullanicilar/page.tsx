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

type AdminUser = {
  id: number;
  email: string;
  phone: string;
  role: string;
  status: string;
  trust_score: number;
  last_login_at: string | null;
  name?: string | null;
  city?: string | null;
};

export default function UsersAdminPage() {
  const { accessToken } = useAuth();
  const [query, setQuery] = useState("");
  const [role, setRole] = useState("all");
  const [status, setStatus] = useState("all");
  const [city, setCity] = useState("");

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["admin-users", query, role, status, city],
    queryFn: async () => {
      if (!accessToken) return { data: [], meta: {} };
      const params = new URLSearchParams();
      if (query) params.set("query", query);
      if (role !== "all") params.set("role", role);
      if (status !== "all") params.set("status", status);
      if (city) params.set("city", city);
      const res = await apiFetchWithAuth(`/admin/users?${params.toString()}`, accessToken);
      return res as { data: AdminUser[]; meta: { total: number } };
    },
    enabled: Boolean(accessToken),
  });

  return (
    <div className="space-y-6">
      <div className="panel-glass p-5">
        <div className="text-sm text-text-muted">Kullanıcı Yönetimi</div>
        <h1 className="mt-1 font-display text-2xl font-semibold">Kullanıcılar</h1>
      </div>

      <Card>
        <CardContent className="grid gap-4 p-6 md:grid-cols-4">
          <Input placeholder="E-posta, telefon, ad" value={query} onChange={(event) => setQuery(event.target.value)} />
          <Input placeholder="Şehir" value={city} onChange={(event) => setCity(event.target.value)} />
          <select
            value={role}
            onChange={(event) => setRole(event.target.value)}
            className="h-12 w-full rounded-btn border border-border/85 bg-surface/90 px-3 text-sm shadow-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          >
            <option value="all">Tüm roller</option>
            <option value="ADMIN">ADMIN</option>
            <option value="MODERATOR">MODERATOR</option>
            <option value="USER_VERIFIED">USER_VERIFIED</option>
            <option value="USER_PENDING">USER_PENDING</option>
            <option value="BANNED">BANNED</option>
          </select>
          <select
            value={status}
            onChange={(event) => setStatus(event.target.value)}
            className="h-12 w-full rounded-btn border border-border/85 bg-surface/90 px-3 text-sm shadow-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          >
            <option value="all">Tüm durumlar</option>
            <option value="ACTIVE">ACTIVE</option>
            <option value="SUSPENDED">SUSPENDED</option>
          </select>
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
          {data.data.map((item) => (
            <Card key={item.id}>
              <CardContent className="flex flex-wrap items-center justify-between gap-4 p-5 text-sm">
                <div>
                  <div className="font-medium">{item.name || item.email}</div>
                  <div className="text-xs text-text-muted">{item.email}</div>
                  <div className="flex flex-wrap items-center gap-2 text-xs text-text-muted">
                    {item.city || "Şehir yok"}
                    <Badge
                      variant={
                        item.role === "ADMIN" || item.role === "MODERATOR"
                          ? "warning"
                          : item.role === "USER_VERIFIED"
                            ? "success"
                            : item.role === "BANNED"
                              ? "danger"
                              : "neutral"
                      }
                    >
                      {item.role}
                    </Badge>
                  </div>
                </div>
                <div className="text-xs text-text-muted">Güven: {item.trust_score}</div>
                <Button size="sm" asChild>
                  <Link href={`/admin/kullanicilar/${item.id}`}>Detay</Link>
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
