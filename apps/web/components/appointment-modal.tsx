"use client";

import { useState } from "react";

import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogTrigger } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { apiFetchWithAuth } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { toFriendlyError } from "@/lib/errors";

export function AppointmentModal({ listingId, disabledReason }: { listingId: number; disabledReason?: string }) {
  const { accessToken } = useAuth();
  const [status, setStatus] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!accessToken) return;
    const formData = new FormData(event.currentTarget);
    setError(null);
    try {
      const res = await apiFetchWithAuth("/appointments", accessToken, {
        method: "POST",
        body: JSON.stringify({
          listing_id: listingId,
          scheduled_at: formData.get("scheduled_at"),
          location: formData.get("location"),
          notes: formData.get("notes"),
        }),
      });
      setStatus(`Randevu talebi alındı (#${res.data.id}).`);
    } catch (err) {
      setError(toFriendlyError(err));
    }
  }

  return (
    <Dialog>
      <DialogTrigger asChild>
        <Button variant="outline" disabled={Boolean(disabledReason)}>
          {disabledReason || "Randevu İste"}
        </Button>
      </DialogTrigger>
      <DialogContent>
        <form className="space-y-4" onSubmit={handleSubmit}>
          <h3 className="font-display text-lg font-semibold">Randevu Talebi</h3>
          <Input name="scheduled_at" type="datetime-local" required />
          <Input name="location" placeholder="Buluşma yeri" required />
          <Input name="notes" placeholder="Not" />
          {status ? <div className="text-sm text-emerald-600">{status}</div> : null}
          {error ? <div className="text-sm text-rose-500">{error}</div> : null}
          <Button type="submit">Talebi Gönder</Button>
        </form>
      </DialogContent>
    </Dialog>
  );
}
