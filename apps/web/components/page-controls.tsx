import { Button } from "@/components/ui/button";

export function PageControls({ page, count, onChange }: { page: number; count: number; onChange: (page: number) => void }) {
  if (page === 0 && count < 50) return null;
  return <nav aria-label="Sayfalar" className="my-5 flex items-center justify-center gap-4">
    <Button variant="outline" disabled={page === 0} onClick={() => onChange(page - 1)}>Önceki</Button>
    <span className="text-sm text-text-muted">Sayfa {page + 1}</span>
    <Button variant="outline" disabled={count < 50} onClick={() => onChange(page + 1)}>Sonraki</Button>
  </nav>;
}
