export const VEHICLE_PARTS = [
  { key: "hood", label: "Kaput" },
  { key: "roof", label: "Tavan" },
  { key: "trunk_lid", label: "Bagaj Kapagi" },
  { key: "left_front_fender", label: "Sol On Camurluk" },
  { key: "left_front_door", label: "Sol On Kapi" },
  { key: "left_rear_door", label: "Sol Arka Kapi" },
  { key: "left_rear_fender", label: "Sol Arka Camurluk" },
  { key: "right_front_fender", label: "Sag On Camurluk" },
  { key: "right_front_door", label: "Sag On Kapi" },
  { key: "right_rear_door", label: "Sag Arka Kapi" },
  { key: "right_rear_fender", label: "Sag Arka Camurluk" },
  { key: "front_bumper", label: "On Tampon" },
  { key: "rear_bumper", label: "Arka Tampon" },
] as const;

export type VehiclePartKey = (typeof VEHICLE_PARTS)[number]["key"];

export const VEHICLE_PART_LABELS: Record<string, string> = Object.fromEntries(
  VEHICLE_PARTS.map((item) => [item.key, item.label])
);
