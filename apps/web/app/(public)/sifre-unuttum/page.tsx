"use client";

import Link from "next/link";
import { useState } from "react";
import { CheckCircle2, KeyRound, Loader2 } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { apiFetch } from "@/lib/api";
import { toFriendlyError } from "@/lib/errors";

export default function ForgotPage() {
  const [result, setResult] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLoading(true);
    setError(null);
    try {
    const formData = new FormData(event.currentTarget);
    const res = await apiFetch("/auth/forgot-password", {
      method: "POST",
      body: JSON.stringify({ email: formData.get("email") }),
    });
    setResult(res.data.reset_token || "Eğer hesap varsa sıfırlama bağlantısı gönderildi.");
    } catch (cause) { setError(toFriendlyError(cause)); }
    finally { setLoading(false); }
  }

  return (
    <div className="container py-12 md:py-16">
      <div className="mx-auto max-w-md rounded-card border border-border bg-surface p-6 shadow-card md:p-8">
        <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-primary-light text-primary">
          <KeyRound className="h-5 w-5" strokeWidth={2} />
        </div>
        <h1 className="mt-5 font-display text-display-sm font-bold tracking-tight text-foreground">
          Şifre sıfırlama
        </h1>
        <p className="mt-2 text-body-md text-text-muted">
          E-postanı gir, sıfırlama bağlantısını gönderelim.
        </p>

        <form className="mt-7 space-y-4" onSubmit={handleSubmit}>
          <div className="space-y-1.5">
            <label htmlFor="email" className="text-sm font-medium text-foreground">
              E-posta
            </label>
            <Input
              id="email"
              name="email"
              type="email"
              placeholder="mail@ornek.com"
              autoComplete="email"
              required
            />
          </div>
          <Button type="submit" size="lg" className="w-full" disabled={loading}>
            {loading ? (
              <>
                <Loader2 className="h-4 w-4 animate-spin" />
                Gönderiliyor…
              </>
            ) : (
              "Sıfırlama Bağlantısı Gönder"
            )}
          </Button>
        </form>

        {result && (
          <div className="mt-5 flex items-start gap-2 rounded-lg border border-success/25 bg-success-bg px-3 py-2.5 text-sm text-success">
            <CheckCircle2 className="h-4 w-4 mt-0.5 shrink-0" />
            <span className="break-all">{result}</span>
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
