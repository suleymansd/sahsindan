"use client";

import Link from "next/link";
import { ArrowUpRight } from "lucide-react";
import { ReactNode } from "react";

import { cn } from "@/lib/utils";

type CategoryCardProps = {
  title: string;
  description: string;
  icon: ReactNode;
  href?: string;
  disabled?: boolean;
};

export function CategoryCard({ title, description, icon, href = "#", disabled }: CategoryCardProps) {
  const content = (
    <div
      className={cn(
        "group relative flex h-full flex-col gap-5 rounded-card border border-border/80 bg-surface/88 p-6 shadow-card backdrop-blur-md transition-all duration-200",
        disabled
          ? "cursor-not-allowed opacity-60"
          : "hover:-translate-y-0.5 hover:border-border-strong hover:shadow-card-hover"
      )}
    >
      <div className="flex items-start justify-between">
        <div className="icon-3d text-primary">{icon}</div>
        {!disabled && (
          <ArrowUpRight className="h-5 w-5 text-text-muted transition-all duration-200 group-hover:-translate-y-0.5 group-hover:translate-x-0.5 group-hover:text-primary" />
        )}
      </div>
      <div className="space-y-1.5">
        <div className="text-title-md text-foreground">{title}</div>
        <p className="text-body-md text-text-muted">{description}</p>
      </div>
      {disabled ? (
        <div className="mt-auto inline-flex w-fit rounded-full border border-border bg-surface-2 px-2.5 py-0.5 text-[11px] font-semibold text-text-muted">
          Yakında
        </div>
      ) : null}
    </div>
  );

  if (disabled) {
    return content;
  }

  return (
    <Link href={href} className="block h-full rounded-card focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background">
      {content}
    </Link>
  );
}
