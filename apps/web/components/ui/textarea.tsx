import * as React from "react";

import { cn } from "@/lib/utils";

export interface TextareaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {}

const Textarea = React.forwardRef<HTMLTextAreaElement, TextareaProps>(({ className, ...props }, ref) => (
  <textarea
    ref={ref}
    className={cn(
      "flex min-h-[112px] w-full rounded-btn border border-border/85 bg-surface/90 px-3.5 py-3 text-sm text-foreground shadow-soft backdrop-blur-md transition-all duration-150",
      "placeholder:text-text-muted",
      "hover:border-border-strong hover:bg-surface",
      "focus-visible:outline-none focus-visible:border-primary focus-visible:shadow-ring",
      "disabled:cursor-not-allowed disabled:opacity-50",
      "resize-y",
      className
    )}
    {...props}
  />
));
Textarea.displayName = "Textarea";

export { Textarea };
