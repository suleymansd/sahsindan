"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import {
  ChevronRight,
  Heart,
  LogOut,
  Menu,
  MessageSquare,
  Plus,
  Search,
  ShieldCheck,
  User,
} from "lucide-react";

import { ThemeToggle } from "@/components/theme-toggle";
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useAuth } from "@/lib/auth";
import { UI } from "@/lib/strings";
import { cn } from "@/lib/utils";

const VERIFIED_ROLES = new Set(["USER_VERIFIED", "ADMIN", "MODERATOR"]);

type NavItem = {
  href: string;
  label: string;
};

function isActive(pathname: string | null, href: string) {
  if (!pathname) return false;
  if (href === "/") return pathname === "/";
  if (href === "/app") return pathname === "/app";
  return pathname === href || pathname.startsWith(`${href}/`);
}

export function SiteHeader() {
  const { user, logout } = useAuth();
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [query, setQuery] = useState("");
  const [scrolled, setScrolled] = useState(false);

  const isVerified = Boolean(user && VERIFIED_ROLES.has(user.role));
  const isPending = user?.role === "USER_PENDING";
  const isAdmin = user?.role === "ADMIN" || user?.role === "MODERATOR";

  useEffect(() => {
    if (pathname?.startsWith("/ilanlar") || pathname === "/app") {
      setQuery(searchParams?.get("q") || "");
    }
  }, [pathname, searchParams]);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 4);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const navItems = useMemo(() => {
    const items: NavItem[] = [];
    if (isVerified) items.push({ href: "/app", label: "Keşfet" });
    items.push({ href: "/ilanlar", label: "İlanlar" });
    if (isVerified) {
      items.push({ href: "/favoriler", label: "Favoriler" });
      items.push({ href: "/mesajlar", label: "Mesajlar" });
      items.push({ href: "/randevular", label: "Randevular" });
      items.push({ href: "/ilanlarim", label: "İlanlarım" });
    }
    if (isPending) items.push({ href: "/dogrulama", label: "Doğrulama" });
    if (isAdmin) items.push({ href: "/admin", label: "Yönetim" });
    return items;
  }, [isAdmin, isPending, isVerified]);

  function handleSearch(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const next = query.trim();
    router.push(next ? `/ilanlar?q=${encodeURIComponent(next)}` : "/ilanlar");
  }

  const homeHref = isVerified ? "/app" : "/";

  return (
    <header
      className={cn(
        "sticky top-0 z-50 w-full border-b transition-all duration-200",
        scrolled
          ? "border-border/70 bg-surface/82 backdrop-blur-xl shadow-medium"
          : "border-transparent bg-surface/52 backdrop-blur-md"
      )}
    >
      <div className="container">
        <div className="flex h-[4.35rem] items-center gap-4">
          <Link
            href={homeHref}
            className="-m-1 flex shrink-0 items-center gap-2.5 rounded-md p-1 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background"
          >
            <div className="icon-3d text-primary">
              <ShieldCheck className="h-4.5 w-4.5" strokeWidth={2.5} />
            </div>
            <div className="font-display text-[1.05rem] font-semibold tracking-tight text-foreground">
              {UI.appName}
            </div>
          </Link>

          <form onSubmit={handleSearch} className="hidden max-w-lg flex-1 lg:block">
            <label className="relative block">
              <Search className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-text-muted" />
              <Input
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Marka, model, ilan no ara..."
                className="h-10 pl-10"
              />
            </label>
          </form>

          <div className="ml-auto flex items-center gap-1.5">
            {isVerified && (
              <>
                <Link
                  href="/mesajlar"
                  aria-label="Mesajlar"
                  className="hidden h-10 w-10 items-center justify-center rounded-full text-text-muted transition-colors hover:bg-surface-2 hover:text-foreground md:inline-flex"
                >
                  <MessageSquare className="h-[18px] w-[18px]" strokeWidth={2} />
                </Link>
                <Link
                  href="/favoriler"
                  aria-label="Favoriler"
                  className="hidden h-10 w-10 items-center justify-center rounded-full text-text-muted transition-colors hover:bg-surface-2 hover:text-foreground md:inline-flex"
                >
                  <Heart className="h-[18px] w-[18px]" strokeWidth={2} />
                </Link>
              </>
            )}

            <ThemeToggle />

            {isVerified ? (
              <Button size="sm" className="hidden md:inline-flex" asChild>
                <Link href="/ilan-ver">
                  <Plus className="h-4 w-4" />
                  İlan Ver
                </Link>
              </Button>
            ) : null}

            {user ? (
              <div className="hidden items-center gap-1.5 md:flex">
                <Link
                  href="/profil"
                  className="inline-flex h-10 items-center gap-2 rounded-full border border-border bg-surface/90 px-3 text-sm font-medium text-foreground transition-all duration-150 hover:border-border-strong hover:bg-surface-2"
                >
                  <div className="icon-3d h-6 w-6 rounded-full text-primary">
                    <User className="h-3.5 w-3.5" />
                  </div>
                  <span className="max-w-[120px] truncate">{user.name || "Profil"}</span>
                </Link>
                <Button variant="ghost" size="icon" onClick={() => logout()} aria-label={UI.actions.logout}>
                  <LogOut className="h-4 w-4" />
                </Button>
              </div>
            ) : (
              <div className="hidden items-center gap-1.5 md:flex">
                <Button size="sm" variant="ghost" asChild>
                  <Link href="/giris">{UI.actions.login}</Link>
                </Button>
                <Button size="sm" asChild>
                  <Link href="/uye-ol">{UI.actions.register}</Link>
                </Button>
              </div>
            )}

            <Sheet>
              <SheetTrigger asChild>
                <Button size="icon" variant="ghost" className="md:hidden" aria-label="Menü">
                  <Menu className="h-5 w-5" />
                </Button>
              </SheetTrigger>
              <SheetContent className="flex flex-col gap-6">
                <div className="flex items-center gap-2.5">
                  <div className="icon-3d text-primary">
                    <ShieldCheck className="h-4.5 w-4.5" strokeWidth={2.5} />
                  </div>
                  <div className="font-display text-base font-semibold">{UI.appName}</div>
                </div>

                <form onSubmit={handleSearch}>
                  <label className="relative block">
                    <Search className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-text-muted" />
                    <Input
                      value={query}
                      onChange={(e) => setQuery(e.target.value)}
                      placeholder="Ara..."
                      className="h-11 pl-10"
                    />
                  </label>
                </form>

                <nav className="flex flex-col gap-1">
                  <p className="px-3 pb-1 text-[11px] font-semibold uppercase tracking-wider text-text-muted">
                    Gezinme
                  </p>
                  {navItems.map((item) => (
                    <Link
                      key={item.href}
                      href={item.href}
                      className={cn(
                        "flex items-center justify-between rounded-xl px-3 py-2.5 text-sm font-medium transition-colors",
                        isActive(pathname, item.href)
                          ? "bg-primary-light text-primary"
                          : "text-foreground hover:bg-surface-2"
                      )}
                    >
                      {item.label}
                      <ChevronRight className="h-4 w-4 opacity-50" />
                    </Link>
                  ))}
                </nav>

                <div className="mt-auto space-y-2 border-t border-border pt-4">
                  {isVerified && (
                    <Button className="w-full" asChild>
                      <Link href="/ilan-ver">
                        <Plus className="h-4 w-4" />
                        İlan Ver
                      </Link>
                    </Button>
                  )}
                  {user ? (
                    <>
                      <Button variant="outline" className="w-full" asChild>
                        <Link href="/profil">
                          <User className="h-4 w-4" />
                          Profilim
                        </Link>
                      </Button>
                      <Button variant="ghost" className="w-full" onClick={() => logout()}>
                        <LogOut className="h-4 w-4" />
                        {UI.actions.logout}
                      </Button>
                    </>
                  ) : (
                    <>
                      <Button variant="outline" className="w-full" asChild>
                        <Link href="/giris">{UI.actions.login}</Link>
                      </Button>
                      <Button className="w-full" asChild>
                        <Link href="/uye-ol">{UI.actions.register}</Link>
                      </Button>
                    </>
                  )}
                </div>
              </SheetContent>
            </Sheet>
          </div>
        </div>

        {navItems.length > 0 && (
          <nav className="hidden h-12 items-center gap-1 overflow-x-auto pb-1 md:flex">
            {navItems.map((item) => {
              const active = isActive(pathname, item.href);
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={cn(
                    "relative inline-flex h-9 items-center whitespace-nowrap rounded-full px-3.5 text-sm font-medium transition-colors",
                    active
                      ? "bg-primary-light text-primary"
                      : "text-text-muted hover:bg-surface-2 hover:text-foreground"
                  )}
                >
                  {item.label}
                  {active && <span className="absolute inset-x-3 -bottom-[5px] h-0.5 rounded-full bg-primary" />}
                </Link>
              );
            })}
          </nav>
        )}
      </div>
    </header>
  );
}
