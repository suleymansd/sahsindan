"use client";

import { cn } from "@/lib/utils";

type Chip = {
  label: string;
  onClick: () => void;
  active?: boolean;
};

export function FilterChips({ chips }: { chips: Chip[] }) {
  return (
    <div className="flex flex-wrap gap-2">
      {chips.map((chip) => (
        <button
          key={chip.label}
          type="button"
          onClick={chip.onClick}
          className={cn(
            "inline-flex h-8 items-center rounded-full border px-3.5 text-[13px] font-medium transition-all duration-150",
            "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background",
            chip.active
              ? "border-primary bg-primary text-primary-foreground shadow-soft"
              : "border-border bg-surface text-foreground hover:border-border-strong hover:bg-surface-2"
          )}
        >
          {chip.label}
        </button>
      ))}
    </div>
  );
}
