"use client";

import { useState } from "react";
import { CarFront } from "lucide-react";
import { cn } from "@/lib/utils";

export function ListingImage({
  src,
  alt,
  className,
  loading = "lazy",
}: {
  src?: string;
  alt: string;
  className?: string;
  loading?: "lazy" | "eager";
}) {
  const [failedUrl, setFailedUrl] = useState<string>();
  if (!src || src.includes("/placeholder.png") || src === failedUrl) {
    return (
      <div
        role="img"
        aria-label={`${alt}: fotoğraf henüz eklenmedi`}
        className={cn(
          "flex h-full w-full flex-col items-center justify-center gap-3 bg-surface-2 text-text-muted",
          className,
        )}
      >
        <CarFront className="h-16 w-16 opacity-35" strokeWidth={1} />
        <span className="text-[11px]">Fotoğraf henüz eklenmedi</span>
      </div>
    );
  }
  return (
    <img
      src={src}
      alt={alt}
      loading={loading}
      onError={() => setFailedUrl(src)}
      className={cn("h-full w-full object-cover", className)}
    />
  );
}
