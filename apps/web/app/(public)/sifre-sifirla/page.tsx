"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { CheckCircle2, Eye, EyeOff, Loader2, LockKeyhole } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { apiFetch, API_CONFIGURED } from "@/lib/api";
import { toFriendlyError } from "@/lib/errors";

export default function ResetPage() {
  const [token, setToken] = useState("");
  useEffect(() => { setToken(new URLSearchParams(window.location.search).get("token") || ""); }, []);
  const [message, setMessage] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showPassword, setShowPassword] = useState(false);

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLoading(true);
    setError(null);
    try {
    const formData = new FormData(event.currentTarget);
    await apiFetch("/auth/reset-password", {
      method: "POST",
      body: JSON.stringify({
        token: formData.get("token"),
        new_password: formData.get("password"),
      }),
    });
    setMessage("Şifren güncellendi. Yeni şifrenle giriş yapabilirsin.");
    } catch (cause) { setError(toFriendlyError(cause)); }
    finally { setLoading(false); }
  }

  return (
    <div className="container py-12 md:py-16">
      <div className="mx-auto max-w-md rounded-card border border-border bg-surface p-6 shadow-card md:p-8">
        <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-primary-light text-primary">
          <LockKeyhole className="h-5 w-5" strokeWidth={2} />
        </div>
        <h1 className="mt-5 font-display text-display-sm font-bold tracking-tight text-foreground">
          Şifreyi güncelle
        </h1>
        <p className="mt-2 text-body-md text-text-muted">
          E-postana gelen sıfırlama kodu ve yeni şifrenle devam et.
        </p>

        <form className="mt-7 space-y-4" onSubmit={handleSubmit}>
          <div className="space-y-1.5">
            <label htmlFor="token" className="text-sm font-medium text-foreground">
              Sıfırlama kodu
            </label>
            <Input
              id="token"
              name="token"
              value={token}
              onChange={(event) => setToken(event.target.value)}
              placeholder="E-postadaki kod"
              autoComplete="one-time-code"
              required
            />
          </div>

          <div className="space-y-1.5">
            <label htmlFor="password" className="text-sm font-medium text-foreground">
              Yeni şifre
            </label>
            <div className="relative">
              <Input
                id="password"
                name="password"
                type={showPassword ? "text" : "password"}
                placeholder="En az 8 karakter"
                autoComplete="new-password"
                minLength={8}
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

          <Button type="submit" size="lg" className="w-full" disabled={loading || !API_CONFIGURED}>
            {loading ? (
              <>
                <Loader2 className="h-4 w-4 animate-spin" />
                Güncelleniyor…
              </>
            ) : (
              "Şifreyi Güncelle"
            )}
          </Button>
        </form>

        {message && (
          <div className="mt-5 flex items-start gap-2 rounded-lg border border-success/25 bg-success-bg px-3 py-2.5 text-sm text-success">
            <CheckCircle2 className="h-4 w-4 mt-0.5 shrink-0" />
            <span>{message}</span>
          </div>
        )}

        {error && <p role="alert" className="mt-4 rounded-lg border border-danger/30 bg-danger/5 p-3 text-sm text-danger">{error}</p>}
        <div className="mt-6 border-t border-border pt-5 text-center text-sm">
          <Link href="/giris" className="font-semibold text-primary hover:underline">
            ← Giriş panellerine dön
          </Link>
        </div>
      </div>
    </div>
  );
}
