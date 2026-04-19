"use client";

import { ImagePlus, Trash2, UploadCloud } from "lucide-react";
import { useCallback, useMemo, useState } from "react";

import { Button } from "@/components/ui/button";
import { Dialog, DialogContent } from "@/components/ui/dialog";
import { cn } from "@/lib/utils";

export type UploadItem = {
  id: string;
  file: File;
  preview: string;
  status: "pending" | "uploading" | "done" | "error";
  progress?: number;
  error?: string | null;
};

type PhotoUploaderProps = {
  items: UploadItem[];
  onChange: (items: UploadItem[]) => void;
  maxFiles?: number;
  minFiles?: number;
  onRetry?: (item: UploadItem) => void;
};

const ACCEPTED_TYPES = ["image/jpeg", "image/png"];
const MAX_SIZE = 8 * 1024 * 1024;

export function PhotoUploader({
  items,
  onChange,
  maxFiles = 20,
  minFiles = 6,
  onRetry,
}: PhotoUploaderProps) {
  const [error, setError] = useState<string | null>(null);
  const [dragIndex, setDragIndex] = useState<number | null>(null);
  const [removeId, setRemoveId] = useState<string | null>(null);

  const canAddMore = items.length < maxFiles;
  const hint = useMemo(
    () => `En az ${minFiles}, en fazla ${maxFiles} fotoğraf ekleyebilirsin. Her fotoğraf max 8MB.`,
    [maxFiles, minFiles]
  );

  const addFiles = useCallback(
    (files: FileList | File[]) => {
      const list = Array.from(files);
      const next: UploadItem[] = [];
      setError(null);

      for (const file of list) {
        if (!ACCEPTED_TYPES.includes(file.type)) {
          setError("Sadece JPEG veya PNG dosyaları yükleyebilirsin.");
          continue;
        }
        if (file.size > MAX_SIZE) {
          setError("Bir fotoğraf 8MB sınırını aşıyor.");
          continue;
        }
        if (items.length + next.length >= maxFiles) {
          setError("Maksimum fotoğraf sayısına ulaştın.");
          break;
        }
        next.push({
          id: crypto.randomUUID(),
          file,
          preview: URL.createObjectURL(file),
          status: "pending",
        });
      }

      if (next.length) {
        onChange([...items, ...next]);
      }
    },
    [items, maxFiles, onChange]
  );

  const handleDrop = useCallback(
    (event: React.DragEvent<HTMLDivElement>) => {
      event.preventDefault();
      if (!canAddMore) return;
      if (event.dataTransfer.files?.length) {
        addFiles(event.dataTransfer.files);
      }
    },
    [addFiles, canAddMore]
  );

  const reorder = useCallback(
    (from: number, to: number) => {
      if (from === to) return;
      const updated = [...items];
      const [moved] = updated.splice(from, 1);
      updated.splice(to, 0, moved);
      onChange(updated);
    },
    [items, onChange]
  );

  const confirmRemove = useCallback(() => {
    if (!removeId) return;
    const updated = items.filter((item) => item.id !== removeId);
    const removed = items.find((item) => item.id === removeId);
    if (removed) {
      URL.revokeObjectURL(removed.preview);
    }
    onChange(updated);
    setRemoveId(null);
  }, [items, onChange, removeId]);

  return (
    <div className="space-y-4">
      <div
        className={cn(
          "flex flex-col items-center justify-center gap-2 rounded-card border border-dashed border-border bg-surface px-6 py-8 text-center transition",
          canAddMore ? "hover:border-primary/60" : "opacity-60"
        )}
        onDragOver={(event) => event.preventDefault()}
        onDrop={handleDrop}
      >
        <div className="flex h-12 w-12 items-center justify-center rounded-btn bg-accent-light text-accent">
          <UploadCloud size={22} />
        </div>
        <div className="text-sm font-semibold">Fotoğrafları sürükleyip bırak</div>
        <div className="text-xs text-muted-foreground">{hint}</div>
        <Button
          type="button"
          variant="outline"
          size="sm"
          disabled={!canAddMore}
          onClick={() => document.getElementById("photo-input")?.click()}
        >
          Dosya seç
        </Button>
        <input
          id="photo-input"
          type="file"
          multiple
          accept="image/png,image/jpeg"
          className="hidden"
          onChange={(event) => event.target.files && addFiles(event.target.files)}
        />
        {error ? <div className="text-xs text-danger">{error}</div> : null}
      </div>

      {items.length ? (
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          {items.map((item, index) => (
            <div
              key={item.id}
              className="group relative overflow-hidden rounded-card border border-border bg-surface shadow-card"
              draggable
              onDragStart={() => setDragIndex(index)}
              onDragEnter={() => {
                if (dragIndex === null || dragIndex === index) return;
                reorder(dragIndex, index);
                setDragIndex(index);
              }}
              onDragEnd={() => setDragIndex(null)}
            >
              <img src={item.preview} alt="Yüklenen fotoğraf" className="h-36 w-full object-cover" />
              <div className="absolute inset-0 bg-black/40 opacity-0 transition group-hover:opacity-100" />
              <div className="absolute left-3 top-3 flex items-center gap-2">
                <span className="rounded-full bg-black/70 px-2 py-1 text-[10px] text-white">
                  {index + 1}
                </span>
                {item.status === "uploading" ? (
                  <span className="rounded-full bg-warning px-2 py-1 text-[10px] text-white">
                    Yükleniyor
                  </span>
                ) : null}
                {item.status === "done" ? (
                  <span className="rounded-full bg-success px-2 py-1 text-[10px] text-white">
                    Yüklendi
                  </span>
                ) : null}
                {item.status === "error" ? (
                  <span className="rounded-full bg-danger px-2 py-1 text-[10px] text-white">
                    Hata
                  </span>
                ) : null}
              </div>
              {item.status === "uploading" ? (
                <div className="absolute bottom-0 left-0 right-0 h-1 bg-black/30">
                  <div
                    className="h-1 bg-primary transition-all"
                    style={{ width: `${Math.min(100, item.progress ?? 0)}%` }}
                  />
                </div>
              ) : null}
              <Button
                type="button"
                size="sm"
                variant="ghost"
                className="absolute right-2 top-2 h-8 w-8 rounded-full bg-black/60 p-0 text-white opacity-0 transition group-hover:opacity-100"
                onClick={() => setRemoveId(item.id)}
              >
                <Trash2 size={16} />
              </Button>
              {item.status === "error" && onRetry ? (
                <Button
                  type="button"
                  size="sm"
                  variant="secondary"
                  className="absolute bottom-3 right-3 opacity-0 transition group-hover:opacity-100"
                  onClick={() => onRetry(item)}
                >
                  Tekrar dene
                </Button>
              ) : null}
            </div>
          ))}
        </div>
      ) : (
        <div className="flex items-center gap-3 rounded-card border border-dashed border-border p-4 text-sm text-muted-foreground">
          <ImagePlus size={18} />
          Henüz fotoğraf eklemedin.
        </div>
      )}

      <Dialog open={Boolean(removeId)} onOpenChange={(open) => !open && setRemoveId(null)}>
        <DialogContent>
          <div className="space-y-4">
            <div className="text-lg font-semibold">Fotoğraf silinsin mi?</div>
            <p className="text-sm text-muted-foreground">
              Bu fotoğraf ilanından kaldırılacak. Devam etmek istiyor musun?
            </p>
            <div className="flex justify-end gap-2">
              <Button type="button" variant="outline" onClick={() => setRemoveId(null)}>
                Vazgeç
              </Button>
              <Button type="button" onClick={confirmRemove}>
                Sil
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
