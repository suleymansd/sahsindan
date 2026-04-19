"use client";

import Link from "next/link";
import { useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { AlertCircle, BadgeCheck, Eye, EyeOff, Loader2, ShieldCheck, Sparkles } from "lucide-react";
import { z } from "zod";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useAuth } from "@/lib/auth";
import { toFriendlyError } from "@/lib/errors";

const POST_STEPS = [
  "Hesap açılır ve panel aktif olur",
  "Profil tamamlandıkça güven seviyen artar",
  "İlan verme ekranında doğrulama adımı görülür",
];

export default function RegisterPage() {
  const { register } = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const schema = z.object({
    name: z.string().min(2),
    email: z.string().email(),
    phone: z.string().min(6),
    password: z.string().min(8),
    profession: z.string().optional(),
  });

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);
    setLoading(true);
    const formData = new FormData(event.currentTarget);
    try {
      const values = schema.parse({
        name: String(formData.get("name")),
        email: String(formData.get("email")),
        phone: String(formData.get("phone")),
        password: String(formData.get("password")),
        profession: formData.get("profession") ? String(formData.get("profession")) : undefined,
      });
      await register({
        email: values.email,
        phone: values.phone,
        password: values.password,
        name: values.name,
        city: "ISTANBUL",
        profession_category: values.profession || "",
      });
      const redirectTo = searchParams?.get("redirect") || "/app";
      router.replace(redirectTo.startsWith("/") ? redirectTo : "/app");
    } catch (err) {
      if (err instanceof z.ZodError) {
        setError("Lütfen zorunlu alanları eksiksiz doldurun.");
      } else {
        setError(toFriendlyError(err));
      }
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="container py-10 md:py-16">
      <div className="mx-auto grid max-w-5xl gap-6 md:grid-cols-[1.1fr_0.9fr] md:items-start">
        <div className="rounded-card border border-border bg-surface p-6 shadow-card md:p-8">
          <div className="space-y-2">
            <div className="inline-flex items-center gap-1.5 rounded-full bg-primary-light px-2.5 py-0.5 text-[11px] font-semibold text-primary">
              <Sparkles className="h-3 w-3" />
              Doğrulanmış üye kaydı
            </div>
            <h1 className="font-display text-display-sm font-bold tracking-tight text-foreground md:text-display-md">
              Üyeliği başlat
            </h1>
            <p className="text-body-md text-text-muted">
              Bilgilerini ekle, hesabını oluştur ve güven odaklı pazara geç.
            </p>
          </div>

          <form className="mt-7 grid gap-4 sm:grid-cols-2" onSubmit={handleSubmit} noValidate>
            <div className="space-y-1.5 sm:col-span-2">
              <label htmlFor="name" className="text-sm font-medium text-foreground">
                Ad Soyad
              </label>
              <Input id="name" name="name" placeholder="Ad Soyad" autoComplete="name" required />
            </div>

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

            <div className="space-y-1.5">
              <label htmlFor="phone" className="text-sm font-medium text-foreground">
                Telefon
              </label>
              <Input
                id="phone"
                name="phone"
                placeholder="5XX XXX XX XX"
                autoComplete="tel"
                required
              />
            </div>

            <div className="space-y-1.5 sm:col-span-2">
              <label htmlFor="profession" className="text-sm font-medium text-foreground">
                Meslek <span className="text-text-muted">(opsiyonel)</span>
              </label>
              <Input
                id="profession"
                name="profession"
                placeholder="Örn. Mühendis"
                autoComplete="organization-title"
              />
            </div>

            <div className="space-y-1.5 sm:col-span-2">
              <label htmlFor="password" className="text-sm font-medium text-foreground">
                Şifre
              </label>
              <div className="relative">
                <Input
                  id="password"
                  name="password"
                  type={showPassword ? "text" : "password"}
                  placeholder="En az 8 karakter"
                  autoComplete="new-password"
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

            {error && (
              <div
                role="alert"
                className="sm:col-span-2 flex items-start gap-2 rounded-lg border border-danger/25 bg-danger-bg px-3 py-2.5 text-sm text-danger"
              >
                <AlertCircle className="h-4 w-4 mt-0.5 shrink-0" />
                <span>{error}</span>
              </div>
            )}

            <div className="sm:col-span-2 space-y-3">
              <Button type="submit" size="lg" className="w-full" disabled={loading}>
                {loading ? (
                  <>
                    <Loader2 className="h-4 w-4 animate-spin" />
                    Kaydediliyor…
                  </>
                ) : (
                  "Hesabı Oluştur"
                )}
              </Button>
              <p className="text-center text-sm text-text-muted">
                Zaten hesabın var mı?{" "}
                <Link href="/giris/kullanici" className="font-semibold text-primary hover:underline">
                  Giriş yap
                </Link>
              </p>
            </div>
          </form>
        </div>

        <aside className="space-y-4">
          <div className="rounded-card border border-border bg-surface p-6 shadow-card">
            <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-primary-light text-primary">
              <BadgeCheck className="h-5 w-5" strokeWidth={2} />
            </div>
            <h2 className="mt-5 text-title-md text-foreground">Kayıt sonrası</h2>
            <ol className="mt-4 space-y-2">
              {POST_STEPS.map((s, i) => (
                <li
                  key={s}
                  className="flex items-start gap-3 rounded-lg border border-border bg-surface-2 px-3 py-2.5 text-sm text-text-muted"
                >
                  <span className="mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-primary text-[11px] font-semibold text-primary-foreground">
                    {i + 1}
                  </span>
                  {s}
                </li>
              ))}
            </ol>
          </div>

          <div className="rounded-card border border-border bg-surface p-6 shadow-card">
            <div className="inline-flex items-center gap-2 text-sm font-semibold text-foreground">
              <ShieldCheck className="h-4 w-4 text-success" />
              Güvenli başlangıç
            </div>
            <p className="mt-2 text-body-md text-text-muted">
              Üyeliğin tamamlandığında ayrık rol panel yapısında sadece kendi yetkili alanlarını görürsün.
            </p>
          </div>
        </aside>
      </div>
    </div>
  );
}
