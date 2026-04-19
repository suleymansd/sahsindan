"use client";

import { useState } from "react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { apiFetch, API_URL } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { toFriendlyError } from "@/lib/errors";

const steps = ["Telefon", "Kimlik", "Selfie", "Meslek", "Onay"];

export default function VerificationPage() {
  const { accessToken } = useAuth();
  const [step, setStep] = useState(0);
  const [otp, setOtp] = useState("123456");
  const [idFront, setIdFront] = useState<File | null>(null);
  const [idBack, setIdBack] = useState<File | null>(null);
  const [selfie, setSelfie] = useState<File | null>(null);
  const [profession, setProfession] = useState<File | null>(null);
  const [consent, setConsent] = useState(false);
  const [status, setStatus] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const disabledReason = !accessToken ? "Giriş gerekli" : null;

  async function handleSubmit() {
    if (!accessToken) return;
    setLoading(true);
    try {
      const res = await apiFetch("/verification/submit", {
        method: "POST",
        headers: { Authorization: `Bearer ${accessToken}` },
        body: JSON.stringify({
          phone_otp: otp,
          selfie_passed: true,
          profession_proof: profession ? "uploaded" : null,
          background_consent: consent,
        }),
      });
      const requestId = res.data.request_id;

      const upload = async (file: File, type: string) => {
        const formData = new FormData();
        formData.append("file", file);
        const uploadRes = await fetch(`${API_URL}/verification/assets/upload?request_id=${requestId}&type=${type}`, {
          method: "POST",
          headers: { Authorization: `Bearer ${accessToken}` },
          body: formData,
        });
        if (!uploadRes.ok) {
          throw new Error("Upload failed");
        }
      };

      if (idFront) await upload(idFront, "id_front");
      if (idBack) await upload(idBack, "id_back");
      if (selfie) await upload(selfie, "selfie");
      if (profession) await upload(profession, "profession");

      setStatus("Başvurun alındı. İnceleme süreci başladı.");
    } catch (err) {
      setStatus(toFriendlyError(err));
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="container py-12">
      <Card className="mx-auto max-w-2xl">
        <CardHeader>
          <div className="flex items-center justify-between">
            <h1 className="font-display text-2xl font-semibold">Doğrulama Sihirbazı</h1>
            <Badge variant="warning">Kapalı Platform</Badge>
          </div>
          <p className="text-sm text-muted-foreground">İlanları görmek için adımları tamamlayın.</p>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="flex flex-wrap gap-2">
            {steps.map((label, index) => (
              <Badge key={label} variant={index === step ? "success" : "neutral"}>
                {label}
              </Badge>
            ))}
          </div>

          {step === 0 && (
            <div className="space-y-4">
              <Input value={otp} onChange={(event) => setOtp(event.target.value)} placeholder="Telefon kodu" />
              <p className="text-xs text-muted-foreground">Geliştirme OTP: 123456</p>
            </div>
          )}

          {step === 1 && (
            <div className="space-y-4">
              <Input type="file" onChange={(event) => setIdFront(event.target.files?.[0] || null)} />
              <Input type="file" onChange={(event) => setIdBack(event.target.files?.[0] || null)} />
            </div>
          )}

          {step === 2 && (
            <div className="space-y-4">
              <Input type="file" onChange={(event) => setSelfie(event.target.files?.[0] || null)} />
              <p className="text-xs text-muted-foreground">Selfie/liveness MVP için simüle edilir.</p>
            </div>
          )}

          {step === 3 && (
            <div className="space-y-4">
              <Input type="file" onChange={(event) => setProfession(event.target.files?.[0] || null)} />
              <p className="text-xs text-muted-foreground">Meslek belgesi veya e-Devlet çıktısı yükleyin.</p>
            </div>
          )}

          {step === 4 && (
            <label className="flex items-center gap-2 text-sm">
              <input type="checkbox" checked={consent} onChange={(event) => setConsent(event.target.checked)} />
              Adli kontrol onayını kabul ediyorum (simülasyon).
            </label>
          )}

          {status ? <div className="text-sm text-emerald-600">{status}</div> : null}

          <div className="flex flex-wrap items-center justify-between gap-3">
            <Button variant="outline" disabled={step === 0} onClick={() => setStep(step - 1)}>
              Geri
            </Button>
            {step < steps.length - 1 ? (
              <Button onClick={() => setStep(step + 1)} disabled={Boolean(disabledReason)}>
                Devam Et
              </Button>
            ) : (
              <Button onClick={handleSubmit} disabled={!consent || loading || Boolean(disabledReason)}>
                {loading ? "Gönderiliyor..." : "Doğrulamayı Gönder"}
              </Button>
            )}
          </div>
          {disabledReason ? <p className="text-xs text-amber-600">{disabledReason}</p> : null}
        </CardContent>
      </Card>
    </main>
  );
}
