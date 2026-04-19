"use client";

import Link from "next/link";
import { ArrowRight } from "lucide-react";

type SectionHeaderProps = {
  title: string;
  description?: string;
  actionLabel?: string;
  actionHref?: string;
};

export function SectionHeader({ title, description, actionLabel, actionHref }: SectionHeaderProps) {
  return (
    <div className="flex flex-wrap items-end justify-between gap-4">
      <div className="space-y-1">
        <h2 className="text-display-sm text-foreground">{title}</h2>
        {description ? <p className="text-body-md text-text-muted">{description}</p> : null}
      </div>
      {actionLabel && actionHref ? (
        <Link
          href={actionHref}
          className="group inline-flex items-center gap-1.5 rounded-full border border-border/70 bg-surface/70 px-3.5 py-1.5 text-sm font-semibold text-primary transition-colors hover:border-border-strong hover:bg-surface-2"
        >
          {actionLabel}
          <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-0.5" />
        </Link>
      ) : null}
    </div>
  );
}
