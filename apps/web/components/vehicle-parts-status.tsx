import { VEHICLE_PARTS } from "@/components/vehicle-parts";
import { cn } from "@/lib/utils";

type VehiclePartsStatusProps = {
  changedParts?: string[] | null;
};

export function VehiclePartsStatus({ changedParts }: VehiclePartsStatusProps) {
  const changedSet = new Set((changedParts || []).filter(Boolean));

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <h3 className="text-title-md font-semibold text-foreground">Parca Durumu</h3>
        <div className="flex items-center gap-2 text-xs">
          <span className="rounded-full border border-danger/20 bg-danger-bg px-2 py-1 font-semibold text-danger">
            Degisen
          </span>
          <span className="rounded-full border border-border/70 bg-surface-2 px-2 py-1 font-semibold text-text-muted">
            Orijinal
          </span>
        </div>
      </div>

      <div className="grid gap-2 sm:grid-cols-2">
        {VEHICLE_PARTS.map((part) => {
          const isChanged = changedSet.has(part.key);
          return (
            <div
              key={part.key}
              className={cn(
                "rounded-btn border px-3 py-2 text-sm",
                isChanged ? "border-danger/25 bg-danger-bg text-danger" : "border-border/70 bg-surface-2/60 text-foreground"
              )}
            >
              <div className="font-medium">{part.label}</div>
              <div className="text-xs">{isChanged ? "Degisen" : "Orijinal"}</div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
