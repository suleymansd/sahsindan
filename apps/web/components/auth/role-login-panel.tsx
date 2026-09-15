"use client";

import Link from "next/link";
import { useState } from "react";
import { useSearchParams } from "next/navigation";
import type { LucideIcon } from "lucide-react";
import { AlertCircle, Eye, EyeOff, Loader2 } from "lucide-react";
import { z } from "zod";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useAuth, type UserSummary } from "@/lib/auth";
import { toFriendlyError } from "@/lib/errors";
import { safeRedirect } from "@/lib/redirect";
import { API_CONFIGURED } from "@/lib/api";

type RoleLoginPanelProps = {
  badge: string;
  title: string;
  description: string;
  icon: LucideIcon;
  expectedRoles: string[];
  roleErrorMessage: string;
  resolveRedirect: (user: UserSummary, redirectParam: string | null) => string;
  secondaryLabel: string;
  secondaryHref: string;
};

export function RoleLoginPanel({
  badge,
  title,
  description,
  icon: Icon,
  expectedRoles,
  roleErrorMessage,
  resolveRedirect,
  secondaryLabel,
  secondaryHref,
}: RoleLoginPanelProps) {
  const { login, logout } = useAuth();
  const searchParams = useSearchParams();
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const schema = z.object({
    email: z.string().email(),
    password: z.string().min(8),
  });

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);
    setLoading(true);

    const formData = new FormData(event.currentTarget);
    try {
      const values = schema.parse({
        email: String(formData.get("email")),
        password: String(formData.get("password")),
      });

      const currentUser = await login(values.email, values.password, expectedRoles, String(formData.get("otp_code") || "").trim() || undefined);
      if (!expectedRoles.includes(currentUser.role)) {
        await logout();
        setError(roleErrorMessage);
        return;
      }

      const redirectParam = searchParams?.get("redirect") || null;
      const next = resolveRedirect(currentUser, redirectParam);
      // Start from the issued cookie; avoid racing RouteGuard's client navigation.
      window.location.replace(safeRedirect(next));
    } catch (err) {
      if (err instanceof z.ZodError) {
        setError("Lütfen geçerli bir e-posta ve en az 8 karakterli şifre girin.");
      } else {
        setError(toFriendlyError(err));
      }
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="panel-glass p-6 md:p-8">
      <div className="flex items-start justify-between gap-4">
        <div className="space-y-2">
          <div className="inline-flex items-center rounded-full border border-primary/25 bg-primary-light px-2.5 py-0.5 text-[11px] font-semibold text-primary">
            {badge}
          </div>
          <h1 className="font-display text-display-sm font-bold tracking-tight text-foreground md:text-display-md">
            {title}
          </h1>
          <p className="text-body-md text-text-muted">{description}</p>
        </div>
        <div className="icon-3d shrink-0 text-primary">
          <Icon className="h-5 w-5" strokeWidth={2} />
        </div>
      </div>

      <form className="mt-7 space-y-4" onSubmit={handleSubmit} noValidate>
        <div className="space-y-1.5">
          <label htmlFor="email" className="text-sm font-medium text-foreground">
            E-posta
          </label>
          <Input
            id="email"
            name="email"
            type="email"
            placeholder="mail@ornek.com"
            autoComplete="username"
            required
          />
        </div>
        <div className="space-y-1.5">
          <div className="flex items-center justify-between">
            <label htmlFor="password" className="text-sm font-medium text-foreground">
              Şifre
            </label>
            <Link href="/sifre-unuttum" className="text-xs font-medium text-primary hover:underline">
              Şifremi unuttum
            </Link>
          </div>
          <div className="relative">
            <Input
              id="password"
              name="password"
              type={showPassword ? "text" : "password"}
              placeholder="En az 8 karakter"
              autoComplete="current-password"
              required
              className="pr-10"
            />
            <button
              type="button"
              onClick={() => setShowPassword((v) => !v)}
              aria-label={showPassword ? "Şifreyi gizle" : "Şifreyi göster"}
              className="absolute right-1 top-1/2 inline-flex h-9 w-9 -translate-y-1/2 items-center justify-center rounded-md text-text-muted transition-colors hover:bg-surface-2 hover:text-foreground"
            >
              {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
            </button>
          </div>
        </div>

        {expectedRoles.some((role) => ["ADMIN", "MODERATOR"].includes(role)) && (
          <div className="space-y-1.5">
            <label htmlFor="otp_code" className="text-sm font-medium">Doğrulayıcı uygulama kodu</label>
            <Input id="otp_code" name="otp_code" inputMode="numeric" autoComplete="one-time-code" maxLength={6} pattern="[0-9]{6}" placeholder="6 haneli kod" />
            <p className="text-xs text-text-muted">Hesabınıza bağlı doğrulayıcı uygulamadaki güncel kodu girin.</p>
          </div>
        )}

        {error && (
          <div
            role="alert"
            className="flex items-start gap-2 rounded-lg border border-danger/25 bg-danger-bg/85 px-3 py-2.5 text-sm text-danger"
          >
            <AlertCircle className="mt-0.5 h-4 w-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <Button type="submit" size="lg" className="w-full" disabled={loading || !API_CONFIGURED}>
          {loading ? (
            <>
              <Loader2 className="h-4 w-4 animate-spin" />
              Giriş yapılıyor...
            </>
          ) : (
            "Giriş Yap"
          )}
        </Button>
      </form>

      <div className="mt-6 flex flex-wrap items-center justify-between gap-2 border-t border-border/70 pt-5 text-sm">
        <span className="text-text-muted">Hesabın yok mu?</span>
        <div className="flex items-center gap-3">
          <Link href={secondaryHref} className="font-medium text-text-muted hover:text-foreground">
            {secondaryLabel}
          </Link>
          <Link href="/uye-ol" className="font-semibold text-primary hover:underline">
            Üye ol
          </Link>
        </div>
      </div>
    </div>
  );
}
