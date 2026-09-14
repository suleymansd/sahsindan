"use client";

import Link from "next/link";
import { useState } from "react";
import { usePathname } from "next/navigation";
import {
  ArrowUpRight,
  LogOut,
  Menu,
  Plus,
  ShieldCheck,
  User,
} from "lucide-react";
import { ThemeToggle } from "@/components/theme-toggle";
import {
  Sheet,
  SheetContent,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/lib/auth";

const VERIFIED_ROLES = new Set(["USER_VERIFIED", "ADMIN", "MODERATOR"]);

export function SiteHeader() {
  const { user, logout } = useAuth();
  const pathname = usePathname();
  const [menuOpen, setMenuOpen] = useState(false);
  const isVerified = Boolean(user && VERIFIED_ROLES.has(user.role));
  const isAdmin = user?.role === "ADMIN" || user?.role === "MODERATOR";
  const homeHref = isVerified ? "/app" : "/";
  const navItems = isVerified
    ? [
        { href: "/app", label: "Keşfet" },
        { href: "/ilanlar", label: "İlanlar" },
        { href: "/favoriler", label: "Favoriler" },
        { href: "/mesajlar", label: "Mesajlar" },
        { href: "/randevular", label: "Randevular" },
        { href: "/ilanlarim", label: "İlanlarım" },
      ]
    : [
        { href: "/", label: "Ana sayfa" },
        { href: "/yardim", label: "Nasıl çalışır?" },
      ];
  if (user?.role === "USER_PENDING")
    navItems.push({ href: "/dogrulama", label: "Doğrulama" });
  if (isAdmin) navItems.push({ href: "/admin", label: "Yönetim" });
  const active = (href: string) =>
    pathname === href || (href !== "/" && pathname?.startsWith(`${href}/`));
  return (
    <header className="sticky top-0 z-50 border-b border-border bg-surface/95 backdrop-blur-md">
      <div className="container">
        <div className="flex h-[76px] items-center justify-between gap-4">
          <Link
            href={homeHref}
            aria-label="şahsından.com ana sayfa"
            className="inline-flex shrink-0 items-center gap-2.5"
          >
            <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-primary text-primary-foreground">
              <ShieldCheck className="h-5 w-5" strokeWidth={1.8} />
            </span>
            <span className="font-display text-lg font-semibold tracking-tight sm:text-xl">
              şahsından<span className="font-normal text-text-muted">.com</span>
            </span>
          </Link>
          {!isVerified && (
            <nav
              aria-label="Ana menü"
              className="hidden items-center gap-8 lg:flex"
            >
              {navItems.map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  className="text-sm font-medium text-text-muted hover:text-foreground"
                  aria-current={active(item.href) ? "page" : undefined}
                >
                  {item.label}
                </Link>
              ))}
            </nav>
          )}
          {isVerified && (
            <span className="mr-auto hidden border-l border-border pl-5 text-xs text-text-muted lg:block">
              İstanbul’un doğrulanmış
              <br />
              araç topluluğu
            </span>
          )}
          <div className="flex items-center gap-2 sm:gap-3">
            <div className="hidden sm:block">
              <ThemeToggle />
            </div>
            {user ? (
              <>
                <Link
                  href="/profil"
                  className="hidden items-center gap-2 rounded-lg px-2 py-2 text-sm font-medium hover:bg-surface-2 md:inline-flex"
                >
                  <User className="h-4 w-4" />
                  <span className="max-w-28 truncate">
                    {user.name || "Profilim"}
                  </span>
                </Link>
                <Button
                  variant="ghost"
                  size="icon"
                  className="hidden md:inline-flex"
                  onClick={() => logout()}
                  aria-label="Çıkış yap"
                >
                  <LogOut className="h-4 w-4" />
                </Button>
                {isVerified && (
                  <Button
                    variant="secondary"
                    asChild
                    className="hidden sm:inline-flex"
                  >
                    <Link href="/ilan-ver">
                      <Plus className="h-4 w-4" />
                      İlan Ver
                    </Link>
                  </Button>
                )}
              </>
            ) : (
              <div className="hidden items-center gap-2 sm:flex">
                <Button asChild variant="ghost">
                  <Link href="/giris/kullanici">Giriş yap</Link>
                </Button>
                <Button asChild>
                  <Link href="/uye-ol">
                    Üye ol
                    <ArrowUpRight className="h-4 w-4" />
                  </Link>
                </Button>
              </div>
            )}
            <Sheet open={menuOpen} onOpenChange={setMenuOpen}>
              <SheetTrigger asChild>
                <Button
                  variant="ghost"
                  size="icon"
                  className="md:hidden"
                  aria-label="Menü"
                >
                  <Menu className="h-5 w-5" />
                </Button>
              </SheetTrigger>
              <SheetContent className="flex flex-col gap-6">
                <SheetTitle className="text-lg font-semibold">Menü</SheetTitle>
                <nav aria-label="Mobil menü" className="flex flex-col gap-1">
                  {navItems.map((item) => (
                    <Link
                      key={item.href}
                      onClick={() => setMenuOpen(false)}
                      href={item.href}
                      aria-current={active(item.href) ? "page" : undefined}
                      className="rounded-lg px-3 py-3 text-sm font-medium hover:bg-surface-2"
                    >
                      {item.label}
                    </Link>
                  ))}
                </nav>
                <div className="mt-auto space-y-3 border-t border-border pt-5">
                  {isVerified && (
                    <Button variant="secondary" asChild className="w-full">
                      <Link onClick={() => setMenuOpen(false)} href="/ilan-ver">
                        İlan Ver
                      </Link>
                    </Button>
                  )}
                  {user ? (
                    <>
                      <Button asChild variant="outline" className="w-full">
                        <Link onClick={() => setMenuOpen(false)} href="/profil">
                          Profilim
                        </Link>
                      </Button>
                      <Button
                        variant="ghost"
                        className="w-full"
                        onClick={() => {
                          setMenuOpen(false);
                          void logout();
                        }}
                      >
                        Çıkış yap
                      </Button>
                    </>
                  ) : (
                    <>
                      <Button asChild className="w-full">
                        <Link
                          onClick={() => setMenuOpen(false)}
                          href="/giris/kullanici"
                        >
                          Giriş yap
                        </Link>
                      </Button>
                      <Button asChild variant="outline" className="w-full">
                        <Link onClick={() => setMenuOpen(false)} href="/uye-ol">
                          Üye ol
                        </Link>
                      </Button>
                    </>
                  )}
                  <ThemeToggle />
                </div>
              </SheetContent>
            </Sheet>
          </div>
        </div>
        {isVerified && (
          <nav
            aria-label="Ana menü"
            className="-mb-px hidden h-11 items-stretch gap-7 overflow-x-auto md:flex"
          >
            {navItems.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                aria-current={active(item.href) ? "page" : undefined}
                className="market-nav-link inline-flex shrink-0 items-center text-xs font-semibold text-text-muted transition-colors hover:text-foreground"
              >
                {item.label}
              </Link>
            ))}
          </nav>
        )}
      </div>
    </header>
  );
}
