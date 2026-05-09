import type { Gender } from "@prisma/client";

export type AgeGroup = "18-24" | "25-34" | "35-44" | "45-54" | "55+" | "unknown";

export function ageGroupFromBirthYear(birthYear: number | null | undefined): AgeGroup {
  if (!birthYear) return "unknown";
  const currentYear = new Date().getUTCFullYear();
  const age = currentYear - birthYear;
  if (age < 18) return "unknown";
  if (age <= 24) return "18-24";
  if (age <= 34) return "25-34";
  if (age <= 44) return "35-44";
  if (age <= 54) return "45-54";
  return "55+";
}

export function normalizeGender(input: unknown): Gender {
  if (input === "male" || input === "female" || input === "other") {
    return input as Gender;
  }
  return "unspecified";
}

const ALLOWED_DEVICE = ["ios", "ipad", "android", "web", "unknown"] as const;
export type DeviceType = (typeof ALLOWED_DEVICE)[number];

export function normalizeDevice(input: unknown): DeviceType {
  if (typeof input === "string" && (ALLOWED_DEVICE as readonly string[]).includes(input)) {
    return input as DeviceType;
  }
  return "unknown";
}
