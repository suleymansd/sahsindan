"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { ArrowLeft, CarFront, Flag, LayoutGrid, ShieldCheck, Sliders, Users } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet";
import { useAuth } from "@/lib/auth";
import { cn } from "@/lib/utils";

const navItems = [
  { href: "/admin", label: "Genel Bakış", icon: LayoutGrid },
  { href: "/admin/dogrulamalar", label: "Doğrulamalar", icon: ShieldCheck },
  { href: "/admin/kullanicilar", label: "Kullanıcılar", icon: Users },
  { href: "/admin/ilanlar", label: "İlanlar", icon: CarFront },
  { href: "/admin/raporlar", label: "Raporlar", icon: Flag },
];

function AdminNav({ isAdmin }: { isAdmin: boolean }) {
  const pathname = usePathname();

  const NavLink = ({
    href,
    label,
    Icon,
    active,
  }: {
    href: string;
    label: string;
    Icon: typeof LayoutGrid;
    active: boolean;
  }) => (
    <Link
      href={href}
      className={cn(
        "flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors",
        active ? "bg-primary-light text-primary" : "text-text-muted hover:bg-surface-2 hover:text-foreground"
      )}
    >
      <Icon className="h-4.5 w-4.5" strokeWidth={2} />
      {label}
    </Link>
  );

  return (
    <nav className="space-y-1">
      {navItems.map((item) => {
        const active = pathname === item.href || (item.href !== "/admin" && pathname?.startsWith(`${item.href}/`));
        return <NavLink key={item.href} href={item.href} label={item.label} Icon={item.icon} active={Boolean(active)} />;
      })}
      {isAdmin && (
        <NavLink
          href="/admin/ayarlar"
          label="Ayarlar"
          Icon={Sliders}
          active={Boolean(pathname?.startsWith("/admin/ayarlar"))}
        />
      )}
      <div className="pt-2">
        <NavLink href="/app" label="Siteye dön" Icon={ArrowLeft} active={false} />
      </div>
    </nav>
  );
}

export function AdminShell({ children }: { children: React.ReactNode }) {
  const { user } = useAuth();
  const isAdmin = user?.role === "ADMIN";
  const roleLabel = user?.role === "MODERATOR" ? "Moderatör" : "Yönetici";

  return (
    <div className="min-h-screen bg-background">
      <div className="mx-auto flex w-full max-w-[1540px] gap-6 px-4 pb-12 pt-8 lg:px-8">
        <aside className="panel-glass sticky top-8 hidden h-[calc(100vh-4rem)] w-72 flex-col p-5 lg:flex">
          <div className="space-y-3">
            <div className="text-[11px] font-semibold uppercase tracking-wider text-text-muted">Yönetim Merkezi</div>
            <div className="font-display text-xl font-semibold tracking-tight text-foreground">Operasyon</div>
            <Badge variant="solid-accent">{roleLabel}</Badge>
          </div>

          <div className="mt-6 flex-1 overflow-y-auto pr-1">
            <AdminNav isAdmin={Boolean(isAdmin)} />
          </div>

          <div className="mt-6 rounded-xl border border-border/70 bg-surface-2/65 p-3 text-xs text-text-muted">
            Giriş yapan:
            <div className="mt-0.5 truncate font-semibold text-foreground">{user?.email || "-"}</div>
          </div>
        </aside>

        <div className="min-w-0 flex-1">
          <div className="panel-glass mb-6 flex items-center justify-between px-4 py-3 lg:px-6">
            <div className="flex items-center gap-3">
              <Sheet>
                <SheetTrigger asChild>
                  <Button variant="outline" size="sm" className="lg:hidden">
                    Menü
                  </Button>
                </SheetTrigger>
                <SheetContent>
                  <div className="space-y-5">
                    <div>
                      <div className="font-display text-lg font-semibold">Yönetim</div>
                      <p className="text-xs text-text-muted">Hızlı erişim</p>
                    </div>
                    <AdminNav isAdmin={Boolean(isAdmin)} />
                  </div>
                </SheetContent>
              </Sheet>
              <div>
                <div className="text-[11px] font-semibold uppercase tracking-wider text-text-muted">Aktif Rol</div>
                <div className="text-sm font-semibold text-foreground">{roleLabel}</div>
              </div>
            </div>
            <div className="hidden text-xs text-text-muted sm:block">{user?.email}</div>
          </div>

          <section className="panel-strong p-4 sm:p-6 lg:p-8">{children}</section>
        </div>
      </div>
    </div>
  );
}
