/** Formatters used across the dashboard. Locale fixed to ar-SA so the numbers
 *  read naturally to the publisher. */

const FORMATTER_INT = new Intl.NumberFormat("ar-SA");
const FORMATTER_PCT = new Intl.NumberFormat("ar-SA", {
  style: "percent",
  maximumFractionDigits: 1,
});
const FORMATTER_REL = new Intl.RelativeTimeFormat("ar-SA", { numeric: "auto" });

export function fmtInt(n: number): string {
  return FORMATTER_INT.format(Math.round(n));
}

export function fmtPct(n: number): string {
  return FORMATTER_PCT.format(n / 100);
}

export function fmtPctRaw(n: number, digits = 1): string {
  return `${n.toFixed(digits)}%`;
}

export function fmtSeconds(n: number | null | undefined): string {
  if (n === null || n === undefined) return "—";
  if (n < 60) return `${Math.round(n)} ث`;
  const m = Math.floor(n / 60);
  const s = Math.round(n % 60);
  return `${m}:${s.toString().padStart(2, "0")} د`;
}

export function fmtRelativeNow(iso: string): string {
  const seconds = Math.round((new Date(iso).getTime() - Date.now()) / 1000);
  const abs = Math.abs(seconds);
  if (abs < 60) return FORMATTER_REL.format(seconds, "second");
  if (abs < 3600) return FORMATTER_REL.format(Math.round(seconds / 60), "minute");
  if (abs < 86400) return FORMATTER_REL.format(Math.round(seconds / 3600), "hour");
  return FORMATTER_REL.format(Math.round(seconds / 86400), "day");
}

const GENDER_LABEL: Record<string, string> = {
  male: "ذكور",
  female: "إناث",
  other: "أخرى",
  unspecified: "غير محدد",
};
export function genderLabel(key: string): string {
  return GENDER_LABEL[key] ?? key;
}

const DEVICE_LABEL: Record<string, string> = {
  ios: "iPhone",
  ipad: "iPad",
  android: "Android",
  web: "متصفّح",
  unknown: "غير معروف",
};
export function deviceLabel(key: string): string {
  return DEVICE_LABEL[key] ?? key;
}
