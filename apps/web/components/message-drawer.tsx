"use client";

import { useState } from "react";

import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogTrigger } from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea";
import { apiFetchWithAuth } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { toFriendlyError } from "@/lib/errors";

export function MessageDrawer({ listingId, disabledReason }: { listingId: number; disabledReason?: string }) {
  const { accessToken } = useAuth();
  const [status, setStatus] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!accessToken) return;
    if (!message.trim()) return;
    setLoading(true);
    setError(null);
    try {
      const thread = await apiFetchWithAuth("/threads", accessToken, {
        method: "POST",
        body: JSON.stringify({ listing_id: listingId }),
      });
      await apiFetchWithAuth(`/threads/${thread.data.id}/messages`, accessToken, {
        method: "POST",
        body: JSON.stringify({ body: message }),
      });
      setStatus("Mesaj gönderildi.");
      setMessage("");
    } catch (err) {
      setError(toFriendlyError(err));
    } finally {
      setLoading(false);
    }
  }

  return (
    <Dialog>
      <DialogTrigger asChild>
        <Button variant="secondary" disabled={Boolean(disabledReason)}>
          {disabledReason || "Mesaj Gönder"}
        </Button>
      </DialogTrigger>
      <DialogContent>
        <form className="space-y-4" onSubmit={handleSubmit}>
          <h3 className="font-display text-lg font-semibold">Mesaj Gönder</h3>
          <div className="flex flex-wrap gap-2 text-xs">
            {["Hâlâ satılık mı?", "Test sürüşü için uygun musunuz?", "Son bakım kayıtları var mı?"].map(
              (text) => (
                <button
                  type="button"
                  key={text}
                  className="rounded-full border border-border px-3 py-1 text-muted-foreground"
                  onClick={() => setMessage(text)}
                >
                  {text}
                </button>
              )
            )}
          </div>
          <Textarea
            name="message"
            placeholder="Fiyat, bakım, ekspertiz gibi detayları sor..."
            required
            value={message}
            onChange={(event) => setMessage(event.target.value)}
          />
          {status ? <div className="text-sm text-emerald-600">{status}</div> : null}
          {error ? <div className="text-sm text-rose-500">{error}</div> : null}
          <Button type="submit" disabled={loading}>
            {loading ? "Gönderiliyor..." : "Mesajı Gönder"}
          </Button>
        </form>
      </DialogContent>
    </Dialog>
  );
}
