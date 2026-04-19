import { redirect } from "next/navigation";

export default function LegacyListingDetail({ params }: { params: { id: string } }) {
  redirect(`/ilanlar/${params.id}`);
}
