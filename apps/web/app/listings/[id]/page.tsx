import { redirect } from "next/navigation";

export default async function LegacyListingDetail({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  redirect(`/ilanlar/${id}`);
}
