"use client";

import Link from "next/link";

import { Button } from "@/components/ui/button";

export default function ForbiddenPage() {
  return (
    <main className="container flex min-h-[70vh] flex-col items-center justify-center gap-4 py-12 text-center">
      <div className="text-sm text-muted-foreground">403</div>
      <h1 className="font-display text-3xl font-semibold">Bu sayfaya erişim yetkiniz yok.</h1>
      <p className="max-w-xl text-sm text-muted-foreground">
        Yönetici veya moderatör yetkisi gerektiren bir alana erişmeye çalıştınız.
      </p>
      <Button asChild>
        <Link href="/ilanlar">İlanlara dön</Link>
      </Button>
    </main>
  );
}
