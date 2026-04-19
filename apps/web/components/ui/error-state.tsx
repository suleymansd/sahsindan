import { AlertCircle, RefreshCw } from "lucide-react";

import { Button } from "./button";

interface ErrorStateProps {
  title?: string;
  message: string;
  onRetry?: () => void;
  retryLabel?: string;
  className?: string;
}

export function ErrorState({
  title = "Bir hata oluştu",
  message,
  onRetry,
  retryLabel = "Tekrar Dene",
  className = "",
}: ErrorStateProps) {
  return (
    <div className={`flex flex-col items-center justify-center rounded-2xl border border-danger/25 bg-danger-bg/70 px-4 py-16 text-center backdrop-blur-sm ${className}`}>
      <div className="mb-6 flex h-16 w-16 items-center justify-center rounded-full bg-danger-bg">
        <AlertCircle className="h-8 w-8 text-danger" />
      </div>

      <h3 className="mb-2 text-title-lg text-foreground">{title}</h3>

      <p className="mb-6 max-w-md text-body-md text-text-muted">{message}</p>

      {onRetry && (
        <Button onClick={onRetry} variant="outline" className="gap-2">
          <RefreshCw className="h-4 w-4" />
          {retryLabel}
        </Button>
      )}
    </div>
  );
}
