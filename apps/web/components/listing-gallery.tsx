"use client";

import * as React from "react";

import { Dialog, DialogContent, DialogTrigger } from "@/components/ui/dialog";

type GalleryPhoto = {
  url: string;
};

export function ListingGallery({ photos, title }: { photos: GalleryPhoto[]; title: string }) {
  const items = photos.length ? photos : [{ url: "/placeholder.png" }];
  const [active, setActive] = React.useState(0);
  const activePhoto = items[active]?.url || items[0].url;

  return (
    <div className="space-y-3">
      <Dialog>
        <DialogTrigger asChild>
          <div className="relative overflow-hidden rounded-card border border-border bg-muted">
            <img src={activePhoto} alt={title} className="h-80 w-full object-cover md:h-[420px]" />
            <div className="absolute bottom-3 right-3 rounded-full bg-black/60 px-3 py-1 text-xs text-white">
              {active + 1} / {items.length}
            </div>
          </div>
        </DialogTrigger>
        <DialogContent className="max-w-5xl border-none bg-transparent p-0 shadow-none">
          <img src={activePhoto} alt={title} className="max-h-[80vh] w-full rounded-card object-contain" />
        </DialogContent>
      </Dialog>
      <div className="flex gap-2 overflow-x-auto pb-2">
        {items.map((photo, index) => (
          <button
            key={`${photo.url}-${index}`}
            type="button"
            aria-label={`${title} fotoğraf ${index + 1}`}
            className={`h-20 w-28 overflow-hidden rounded-btn border ${
              index === active ? "border-primary" : "border-transparent"
            }`}
            onClick={() => setActive(index)}
          >
            <img src={photo.url} alt={`${title} ${index + 1}`} className="h-full w-full object-cover" />
          </button>
        ))}
      </div>
    </div>
  );
}
