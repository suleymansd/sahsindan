import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";

import { cn } from "@/lib/utils";

const badgeVariants = cva(
  "inline-flex items-center gap-1 rounded-full border px-2.5 py-0.5 text-[11px] font-semibold tracking-[0.01em] backdrop-blur-sm",
  {
    variants: {
      variant: {
        default: "border-primary/20 bg-primary-light text-primary",
        success: "border-success/20 bg-success-bg text-success",
        warning: "border-warning/24 bg-warning-bg text-warning",
        danger: "border-danger/24 bg-danger-bg text-danger",
        info: "border-info/24 bg-info-bg text-info",
        neutral: "border-border bg-surface-2 text-text-muted",
        outline: "border-border bg-surface text-foreground",
        solid: "border-transparent bg-primary text-primary-foreground",
        "solid-accent": "border-transparent bg-accent text-accent-foreground",
      },
      size: {
        sm: "px-2 py-0.5 text-[10px]",
        md: "px-2.5 py-0.5 text-[11px]",
        lg: "px-3 py-1 text-xs",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "md",
    },
  }
);

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

function Badge({ className, variant, size, ...props }: BadgeProps) {
  return <div className={cn(badgeVariants({ variant, size, className }))} {...props} />;
}

export { Badge, badgeVariants };
