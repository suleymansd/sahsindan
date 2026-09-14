"use client";

import { useEffect, useRef, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Check, CheckCheck, MessageCircle, SendHorizontal } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/ui/empty-state";
import { SectionHeader } from "@/components/section-header";
import { Skeleton } from "@/components/ui/skeleton";
import { Textarea } from "@/components/ui/textarea";
import { PageControls } from "@/components/page-controls";
import { API_URL, apiFetchWithAuth } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { toFriendlyError } from "@/lib/errors";
import { cn } from "@/lib/utils";

type ConversationMessage = { id: number; body: string; sender_id: number; recipient_id?: number; read_at?: string | null; created_at?: string | null };

const QUICK_REPLIES = [
  "Merhaba, ilan hâlâ satışta mı?",
  "Fiyat esnekliği var mı?",
  "Randevu için müsait misiniz?",
];

function formatTime(value?: string | null) {
  if (!value) return "";
  return new Date(value).toLocaleTimeString("tr-TR", { hour: "2-digit", minute: "2-digit" });
}

export default function InboxPage() {
  const [page, setPage] = useState(0);
  const { accessToken, user } = useAuth();
  const [status, setStatus] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [history, setHistory] = useState<Record<number, ConversationMessage[]>>({});
  const [loadingHistory, setLoadingHistory] = useState<number | null>(null);
  const [sending, setSending] = useState(false);
  const queryClient = useQueryClient();
  const wsRef = useRef<WebSocket | null>(null);

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["threads", user?.id, page],
    queryFn: async () => {
      if (!accessToken) return [];
      const res = await apiFetchWithAuth(`/threads?limit=50&offset=${page * 50}`, accessToken);
      return res.data as Array<{
        id: number;
        listing_id: number;
        buyer_id: number;
        seller_id: number;
        last_message_at?: string | null;
        messages: ConversationMessage[];
      }>;
    },
    enabled: Boolean(accessToken),
    refetchInterval: 30000,
    refetchIntervalInBackground: false,
  });

  useEffect(() => {
    if (!accessToken || !user?.id) return;

    const wsBase = API_URL.replace(/^http:/, "ws:").replace(/^https:/, "wss:");
    const socket = new WebSocket(`${wsBase}/ws/connect`, ["trustmarket", `bearer.${accessToken}`]);
    wsRef.current = socket;

    const pingTimer = window.setInterval(() => {
      if (socket.readyState === WebSocket.OPEN) socket.send("ping");
    }, 25000);

    socket.onmessage = (event) => {
      try {
        const payload = JSON.parse(event.data);
        if (payload?.type === "new_message" || payload?.type === "messages_read") {
          queryClient.invalidateQueries({ queryKey: ["threads", user.id] });
        }
      } catch {}
    };

    return () => {
      window.clearInterval(pingTimer);
      socket.close();
      wsRef.current = null;
    };
  }, [accessToken, queryClient, user?.id]);

  async function sendReply(threadId: number, message: string) {
    if (!accessToken || sending || !message.trim()) return false;
    setSending(true);
    setError(null);
    setStatus(null);
    try {
      await apiFetchWithAuth(`/threads/${threadId}/messages`, accessToken, {
        method: "POST", body: JSON.stringify({ body: message.trim() }),
      });
      setHistory(current => { const next = { ...current }; delete next[threadId]; return next; });
      setStatus("Yanıt gönderildi.");
      await refetch();
      return true;
    } catch (err) {
      setError(toFriendlyError(err));
      return false;
    } finally {
      setSending(false);
    }
  }

  async function earlierMessages(threadId: number, beforeId: number) {
    if (!accessToken || loadingHistory !== null) return;
    setLoadingHistory(threadId);
    try {
      const result = await apiFetchWithAuth(`/threads/${threadId}?limit=30&before_id=${beforeId}`, accessToken);
      setHistory(current => ({ ...current, [threadId]: result.data.messages }));
    } catch (err) {
      setError(toFriendlyError(err));
    } finally {
      setLoadingHistory(null);
    }
  }

  async function markRead(threadId: number) {
    if (!accessToken) return;
    try {
      await apiFetchWithAuth(`/threads/${threadId}/read`, accessToken, { method: "POST" });
      await refetch();
    } catch (err) {
      setError(toFriendlyError(err));
    }
  }

  return (
    <div className="container py-10">
      <div className="flex items-start justify-between gap-4">
        <SectionHeader title="Mesajlar" description="Güvenli mesajlaşma ve hızlı yanıtlar." />
        {status && <Badge variant="success">{status}</Badge>}
      </div>

      {error && <p role="alert" className="mt-4 text-sm text-rose-600">{error}</p>}
      {accessToken && !isLoading && <PageControls page={page} count={data?.length ?? 0} onChange={setPage} />}
      {!accessToken ? (
        <div className="mt-6 rounded-card border border-border bg-surface p-8 shadow-card">
          <EmptyState
            icon={MessageCircle}
            title="Mesajları görmek için giriş yap"
            description="Satıcılarla iletişim kurmak için giriş gereklidir."
          />
        </div>
      ) : isLoading ? (
        <div className="mt-8 space-y-3">
          {Array.from({ length: 3 }).map((_, idx) => (
            <Skeleton key={idx} className="h-48 w-full" />
          ))}
        </div>
      ) : isError ? (
        <div className="mt-8 flex items-center justify-between rounded-card border border-border bg-surface p-5 shadow-card">
          <span className="text-sm text-text-muted">Mesajlar yüklenemedi.</span>
          <Button variant="outline" size="sm" onClick={() => refetch()}>
            Tekrar dene
          </Button>
        </div>
      ) : data && data.length ? (
        <div className="mt-8 space-y-4">
          {data.map((thread) => {
            const shownMessages = history[thread.id] ?? thread.messages;
            const otherUserId =
              thread.buyer_id === user?.id ? thread.seller_id : thread.buyer_id;
            const unreadCount = thread.messages.filter(
              (msg) => !msg.read_at && msg.sender_id !== user?.id
            ).length;
            const lastMessage = thread.messages.slice(-1)[0];
            return (
              <div
                key={thread.id}
                className="overflow-hidden rounded-card border border-border bg-surface shadow-card"
              >
                <div className="flex flex-wrap items-start justify-between gap-3 border-b border-border bg-surface-2/50 p-4">
                  <div className="min-w-0">
                    <div className="inline-flex items-center gap-2 text-xs font-medium text-text-muted">
                      <span>İlan #{thread.listing_id}</span>
                      <span>·</span>
                      <span>Kullanıcı #{otherUserId}</span>
                    </div>
                    {lastMessage ? (
                      <p className="mt-1 line-clamp-1 text-sm text-foreground/80">
                        {lastMessage.body}
                      </p>
                    ) : (
                      <p className="mt-1 text-sm text-text-muted">Henüz mesaj yok.</p>
                    )}
                  </div>
                  <div className="flex flex-col items-end gap-1.5">
                    {unreadCount > 0 && <Badge variant="warning">{unreadCount} yeni</Badge>}
                    {thread.last_message_at && (
                      <span className="text-xs text-text-muted">
                        {new Date(thread.last_message_at).toLocaleString("tr-TR", {
                          dateStyle: "short",
                          timeStyle: "short",
                        })}
                      </span>
                    )}
                  </div>
                </div>

                <div className="max-h-[320px] space-y-2 overflow-y-auto bg-surface-2/30 p-4 text-sm">
                  {(shownMessages.length >= 30 || history[thread.id]) && <div className="flex justify-center gap-3">
                    <Button variant="ghost" size="sm" disabled={!shownMessages.length || loadingHistory !== null} onClick={() => earlierMessages(thread.id, shownMessages[0].id)}>Önceki mesajlar</Button>
                    {history[thread.id] && <Button variant="ghost" size="sm" onClick={() => setHistory(current => { const next = { ...current }; delete next[thread.id]; return next; })}>Son mesajlar</Button>}
                  </div>}
                  {shownMessages.map((msg, idx) => {
                    const mine = msg.sender_id === user?.id;
                    return (
                      <div
                        key={`${thread.id}-${idx}`}
                        className={cn("flex", mine ? "justify-end" : "justify-start")}
                      >
                        <div
                          className={cn(
                            "max-w-[82%] rounded-2xl px-3 py-2 shadow-soft",
                            mine
                              ? "rounded-br-sm bg-primary text-primary-foreground"
                              : "rounded-bl-sm border border-border bg-surface text-foreground"
                          )}
                        >
                          <div className="break-words">{msg.body}</div>
                          <div
                            className={cn(
                              "mt-1 flex items-center justify-end gap-1 text-[10px]",
                              mine ? "text-primary-foreground/80" : "text-text-muted"
                            )}
                          >
                            <span>{formatTime(msg.created_at)}</span>
                            {mine &&
                              (msg.read_at ? (
                                <CheckCheck className="h-3 w-3" />
                              ) : (
                                <Check className="h-3 w-3" />
                              ))}
                          </div>
                        </div>
                      </div>
                    );
                  })}
                  {!shownMessages.length && (
                    <div className="text-center text-xs text-text-muted">
                      Bu konuşmada henüz mesaj yok.
                    </div>
                  )}
                </div>

                <div className="space-y-3 border-t border-border p-4">
                  <div className="flex flex-wrap items-center gap-2">
                    <Button variant="outline" size="sm" onClick={() => markRead(thread.id)}>
                      Okundu işaretle
                    </Button>
                    {QUICK_REPLIES.map((reply) => (
                      <Button
                        key={reply}
                        variant="ghost"
                        size="sm"
                        disabled={sending}
                        onClick={() => sendReply(thread.id, reply)}
                      >
                        {reply}
                      </Button>
                    ))}
                  </div>

                  <form
                    className="flex gap-2"
                    onSubmit={async (event) => {
                      event.preventDefault();
                      const form = event.currentTarget;
                      const formData = new FormData(form);
                      if (await sendReply(thread.id, String(formData.get("message")))) form.reset();
                    }}
                  >
                    <Textarea
                      name="message"
                      placeholder="Mesaj yaz…"
                      required
                      className="min-h-[48px] flex-1"
                    />
                    <Button type="submit" disabled={sending} className="shrink-0 self-start">
                      <SendHorizontal className="h-4 w-4" />
                      Gönder
                    </Button>
                  </form>
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        <div className="mt-8 rounded-card border border-dashed border-border bg-surface-2/60 p-10">
          <EmptyState
            icon={MessageCircle}
            title="Henüz konuşma yok"
            description="İlan detayından satıcıya mesaj göndererek başlayabilirsin."
          />
        </div>
      )}
    </div>
  );
}
