"use client";

import { Check } from "lucide-react";

import { VEHICLE_PARTS, type VehiclePartKey } from "@/components/vehicle-parts";
import { cn } from "@/lib/utils";

type VehiclePartsSelectorProps = {
  selectedParts: VehiclePartKey[];
  onChange: (parts: VehiclePartKey[]) => void;
};

export function VehiclePartsSelector({ selectedParts, onChange }: VehiclePartsSelectorProps) {
  function togglePart(partKey: VehiclePartKey) {
    if (selectedParts.includes(partKey)) {
      onChange(selectedParts.filter((item) => item !== partKey));
      return;
    }
    onChange([...selectedParts, partKey]);
  }

  return (
    <div className="space-y-3 rounded-card border border-border/70 bg-surface/70 p-4">
      <div className="flex items-center justify-between gap-3">
        <div>
          <div className="text-sm font-semibold text-foreground">Parca Durumu</div>
          <p className="text-xs text-text-muted">
            Degisen parcayi secin. Isaretlemediginiz parcalar otomatik olarak orijinal kabul edilir.
          </p>
        </div>
        <div className="rounded-full border border-danger/20 bg-danger-bg px-3 py-1 text-xs font-semibold text-danger">
          {selectedParts.length} degisen parca
        </div>
      </div>

      <div className="grid gap-2 sm:grid-cols-2">
        {VEHICLE_PARTS.map((part) => {
          const active = selectedParts.includes(part.key);
          return (
            <button
              key={part.key}
              type="button"
              onClick={() => togglePart(part.key)}
              className={cn(
                "flex items-center justify-between rounded-btn border px-3 py-2 text-left text-sm transition",
                active
                  ? "border-danger/35 bg-danger-bg text-danger"
                  : "border-border/70 bg-surface text-text-muted hover:border-primary/30 hover:text-foreground"
              )}
            >
              <span className="font-medium">{part.label}</span>
              {active ? <Check className="h-4 w-4" /> : null}
            </button>
          );
        })}
      </div>
    </div>
  );
}
