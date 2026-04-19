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

const tabs = [
  { label: "Bekleyen", value: "PENDING" },
  { label: "Onaylanan", value: "APPROVED" },
  { label: "Reddedilen", value: "REJECTED" },
];

type VerificationItem = {
  id: number;
  status: string;
  created_at: string;
  user: {
    id: number;
    email: string;
    phone: string;
    name: string | null;
    city: string | null;
    profession: string | null;
  };
};

export default function VerificationQueuePage() {
  const { accessToken } = useAuth();
  const [status, setStatus] = useState("PENDING");
  const [city, setCity] = useState("");
  const [profession, setProfession] = useState("");
  const [start, setStart] = useState("");
  const [end, setEnd] = useState("");

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["admin-verification", status, city, profession, start, end],
    queryFn: async () => {
      if (!accessToken) return { data: [], meta: {} };
      const params = new URLSearchParams();
      params.set("status", status);
      if (city) params.set("city", city);
      if (profession) params.set("profession", profession);
      if (start) params.set("start", start);
      if (end) params.set("end", end);
      const res = await apiFetchWithAuth(`/admin/verification/queue?${params.toString()}`, accessToken);
      return res as { data: VerificationItem[]; meta: { total: number } };
    },
    enabled: Boolean(accessToken),
  });

  return (
    <div className="space-y-6">
      <div className="panel-glass p-5">
        <div className="text-sm text-text-muted">Doğrulama Yönetimi</div>
        <h1 className="mt-1 font-display text-2xl font-semibold">Doğrulama Kuyruğu</h1>
      </div>

      <div className="flex flex-wrap gap-2">
        {tabs.map((tab) => (
          <Button
            key={tab.value}
            variant={status === tab.value ? "default" : "outline"}
            size="sm"
            onClick={() => setStatus(tab.value)}
          >
            {tab.label}
          </Button>
        ))}
      </div>

      <Card>
        <CardContent className="grid gap-4 p-6 md:grid-cols-4">
          <Input placeholder="Şehir" value={city} onChange={(event) => setCity(event.target.value)} />
          <Input placeholder="Meslek" value={profession} onChange={(event) => setProfession(event.target.value)} />
          <Input type="date" value={start} onChange={(event) => setStart(event.target.value)} />
          <Input type="date" value={end} onChange={(event) => setEnd(event.target.value)} />
        </CardContent>
      </Card>

      {isLoading ? (
        <div className="space-y-3">
          {Array.from({ length: 5 }).map((_, idx) => (
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
                <div className="space-y-1">
                  <div className="font-medium">{item.user.name || "İsimsiz Kullanıcı"}</div>
                  <div className="text-xs text-text-muted">{item.user.email}</div>
                  <div className="flex flex-wrap items-center gap-2 text-xs text-text-muted">
                    {item.user.city || "Şehir yok"} - {item.user.profession || "Meslek yok"}
                    <Badge variant={item.status === "APPROVED" ? "success" : item.status === "REJECTED" ? "danger" : "warning"}>
                      {item.status}
                    </Badge>
                  </div>
                </div>
                <div className="text-xs text-text-muted">
                  Başvuru: {new Date(item.created_at).toLocaleDateString("tr-TR")}
                </div>
                <Button size="sm" asChild>
                  <Link href={`/admin/dogrulamalar/${item.id}`}>İncele</Link>
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
