"use client";

import { useCallback, useMemo, useState } from "react";

import { PhotoUploader, type UploadItem } from "@/components/photo-uploader";
import { VehiclePartsSelector } from "@/components/vehicle-parts-selector";
import type { VehiclePartKey } from "@/components/vehicle-parts";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { apiFetchWithAuth, API_URL } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { toFriendlyError } from "@/lib/errors";

export default function NewListingPage() {
  const { accessToken, user } = useAuth();
  const [status, setStatus] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [photos, setPhotos] = useState<UploadItem[]>([]);
  const [selectedChangedParts, setSelectedChangedParts] = useState<VehiclePartKey[]>([]);
  const [photoError, setPhotoError] = useState<string | null>(null);
  const [createdListingId, setCreatedListingId] = useState<number | null>(null);

  const canCreate = user?.role === "USER_VERIFIED" || user?.role === "ADMIN" || user?.role === "MODERATOR";
  const minPhotos = 6;

  const updatePhoto = useCallback((id: string, next: Partial<UploadItem>) => {
    setPhotos((prev) => prev.map((item) => (item.id === id ? { ...item, ...next } : item)));
  }, []);

  const uploadWithProgress = useCallback(
    async (listingId: number, item: UploadItem) => {
      if (!accessToken) throw new Error("Token missing");
      return new Promise<number>((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.open("POST", `${API_URL}/listings/${listingId}/photos`);
        xhr.setRequestHeader("Authorization", `Bearer ${accessToken}`);
        xhr.upload.onprogress = (event) => {
          if (event.lengthComputable) {
            const progress = Math.round((event.loaded / event.total) * 100);
            updatePhoto(item.id, { progress });
          }
        };
        xhr.onload = () => {
          if (xhr.status >= 200 && xhr.status < 300) {
            try {
              const payload = JSON.parse(xhr.responseText);
              resolve(payload.data.photo_id as number);
            } catch (err) {
              reject(err);
            }
            return;
          }
          reject(new Error("upload failed"));
        };
        xhr.onerror = () => reject(new Error("upload failed"));
        xhr.timeout = 60000;
        xhr.ontimeout = () => reject(new Error("upload timed out"));
        const upload = new FormData();
        upload.append("file", item.file);
        xhr.send(upload);
      });
    },
    [accessToken, updatePhoto]
  );

  const retryUpload = useCallback(
    async (item: UploadItem) => {
      if (!accessToken) return;
      if (!createdListingId) {
        setPhotoError("Önce ilanı oluşturup fotoğrafları yükleyin.");
        return;
      }
      updatePhoto(item.id, { status: "uploading", progress: 0, error: null });
      try {
        const photoId = await uploadWithProgress(createdListingId, item);
        updatePhoto(item.id, { status: "done", progress: 100, error: null, photoId });
        await apiFetchWithAuth(`/listings/${createdListingId}/photos/reorder`, accessToken, {
          method: "POST",
          body: JSON.stringify({ photo_ids: [photoId] }),
        });
      } catch (err) {
        updatePhoto(item.id, { status: "error", error: "Yükleme başarısız." });
      }
    },
    [accessToken, createdListingId, updatePhoto, uploadWithProgress]
  );

  const readyToPublish = useMemo(() => photos.length >= minPhotos, [photos.length]);

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!accessToken) return;
    setLoading(true);
    setStatus(null);
    setPhotoError(null);

    const form = event.currentTarget;
    const formData = new FormData(form);
    const submitter = (event.nativeEvent as SubmitEvent).submitter as HTMLButtonElement | null;
    const intent = submitter?.value || "publish";

    if (intent === "publish" && !readyToPublish) {
      setPhotoError(`Yayınlamak için en az ${minPhotos} fotoğraf eklemelisin.`);
      setLoading(false);
      return;
    }

    try {
      const payload = {
        title: formData.get("title"),
        description: formData.get("description"),
        price: Number(formData.get("price")),
        city: "ISTANBUL",
        district: formData.get("district"),
        car_details: {
          brand: formData.get("brand"),
          model: formData.get("model"),
          year: Number(formData.get("year")),
          mileage: Number(formData.get("mileage")),
          transmission: formData.get("transmission"),
          fuel: formData.get("fuel"),
          color: formData.get("color"),
          changed_parts: selectedChangedParts,
        },
      };

      const res = await apiFetchWithAuth(createdListingId ? `/listings/${createdListingId}` : "/listings", accessToken, {
        method: createdListingId ? "PUT" : "POST",
        body: JSON.stringify(payload),
      });
      setCreatedListingId(res.data.id);

      const uploadedIds: number[] = [];
      let uploadFailed = false;

      for (const item of photos) {
        if (item.photoId) {
          uploadedIds.push(item.photoId);
          continue;
        }
        try {
          updatePhoto(item.id, { status: "uploading", progress: 0, error: null });
          const photoId = await uploadWithProgress(res.data.id, item);
          uploadedIds.push(photoId);
          updatePhoto(item.id, { status: "done", progress: 100, error: null, photoId });
        } catch (err) {
          uploadFailed = true;
          updatePhoto(item.id, { status: "error", error: "Yükleme başarısız." });
        }
      }

      if (uploadedIds.length && uploadedIds.length === photos.length) {
        await apiFetchWithAuth(`/listings/${res.data.id}/photos/reorder`, accessToken, {
          method: "POST",
          body: JSON.stringify({ photo_ids: uploadedIds }),
        });
      }

      if (intent === "publish" && !uploadFailed) {
        await apiFetchWithAuth(`/listings/${res.data.id}/publish`, accessToken, { method: "POST" });
        setStatus("İlan oluşturuldu ve yayına alındı.");
        form.reset();
        setPhotos([]);
        setSelectedChangedParts([]);
        setCreatedListingId(null);
      } else if (uploadFailed) {
        setStatus("Bazı fotoğraflar yüklenemedi. İlan taslakta kaldı.");
      } else {
        setStatus("İlan taslak olarak kaydedildi.");
        form.reset();
        setPhotos([]);
        setSelectedChangedParts([]);
        setCreatedListingId(null);
      }
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
          <h1 className="font-display text-2xl font-semibold">İlan Ver</h1>
          <p className="text-sm text-muted-foreground">Yalnızca doğrulanmış üyeler ilan yayınlayabilir.</p>
        </CardHeader>
        <CardContent>
          {!canCreate ? (
            <div className="rounded-card border border-border p-4 text-sm text-muted-foreground">
              İlan verebilmek için doğrulama gereklidir.
            </div>
          ) : (
            <form className="grid gap-4" onSubmit={handleSubmit}>
              <Input name="title" placeholder="Başlık" required />
              <Textarea name="description" placeholder="Açıklama" required />
              <Input name="price" type="number" placeholder="Fiyat" required />
              <Input name="district" placeholder="İlçe" required />
              <div className="space-y-2">
                <div className="text-sm font-semibold">Fotoğraflar</div>
                <p className="text-xs text-muted-foreground">
                  En az {minPhotos} fotoğraf ekleyin. Sürükle-bırak ile sıralama yapabilirsiniz.
                </p>
                <PhotoUploader
                  items={photos}
                  onChange={setPhotos}
                  minFiles={minPhotos}
                  maxFiles={20}
                  onRetry={retryUpload}
                />
                {photoError ? <div role="alert" className="text-xs text-rose-500">{photoError}</div> : null}
              </div>
              <div className="grid gap-4 md:grid-cols-2">
                <Input name="brand" placeholder="Marka" required />
                <Input name="model" placeholder="Model" required />
                <Input name="year" type="number" placeholder="Yıl" required />
                <Input name="mileage" type="number" placeholder="Kilometre" required />
                <Input name="transmission" placeholder="Vites" required />
                <Input name="fuel" placeholder="Yakıt" required />
                <Input name="color" placeholder="Renk" required />
              </div>
              <VehiclePartsSelector selectedParts={selectedChangedParts} onChange={setSelectedChangedParts} />
              {status ? <div className="text-sm text-emerald-600">{status}</div> : null}
              <div className="flex flex-wrap gap-2">
                <Button type="submit" variant="outline" value="draft" disabled={loading}>
                  Taslak Kaydet
                </Button>
                <Button type="submit" value="publish" disabled={loading || !readyToPublish}>
                  {loading ? "Yayınlanıyor..." : "Yayınla"}
                </Button>
              </div>
              {!readyToPublish ? (
                <div className="text-xs text-muted-foreground">
                  Yayınlamak için en az {minPhotos} fotoğraf eklemelisiniz.
                </div>
              ) : null}
            </form>
          )}
        </CardContent>
      </Card>
    </main>
  );
}
