import * as React from "react";

import { cn } from "@/lib/utils";

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {}

const Input = React.forwardRef<HTMLInputElement, InputProps>(({ className, type, ...props }, ref) => (
  <input
    ref={ref}
    type={type}
    className={cn(
      "flex h-11 w-full rounded-btn border border-border bg-surface-2 px-3.5 text-sm text-foreground transition-all duration-150",
      "placeholder:text-text-muted",
      "hover:border-border-strong hover:bg-surface",
      "focus-visible:outline-none focus-visible:border-primary focus-visible:shadow-ring",
      "disabled:cursor-not-allowed disabled:opacity-50",
      className
    )}
    {...props}
  />
));
Input.displayName = "Input";

export { Input };
