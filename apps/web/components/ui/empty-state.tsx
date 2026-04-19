import { LucideIcon } from "lucide-react";
import { ReactNode } from "react";

import { Button } from "./button";

interface EmptyStateProps {
  icon?: LucideIcon;
  title: string;
  description?: string;
  action?: {
    label: string;
    onClick: () => void;
  };
  children?: ReactNode;
  className?: string;
}

export function EmptyState({
  icon: Icon,
  title,
  description,
  action,
  children,
  className = "",
}: EmptyStateProps) {
  return (
    <div className={`flex flex-col items-center justify-center rounded-2xl border border-border/70 bg-surface/75 px-4 py-12 text-center backdrop-blur-sm ${className}`}>
      {Icon && (
        <div className="mb-5 flex h-14 w-14 items-center justify-center rounded-2xl border border-border bg-surface-2">
          <Icon className="h-6 w-6 text-text-muted" strokeWidth={1.75} />
        </div>
      )}

      <h3 className="mb-1.5 text-title-md text-foreground">{title}</h3>

      {description && (
        <p className="mb-6 max-w-md text-body-md text-text-muted">{description}</p>
      )}

      {action && (
        <Button onClick={action.onClick} size="default">
          {action.label}
        </Button>
      )}

      {children}
    </div>
  );
}
