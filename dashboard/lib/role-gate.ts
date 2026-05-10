/**
 * Role-based route policy for the dashboard.
 *
 * Three groups:
 *   - "everyone"        — any signed-in user (respondent, publisher, admin)
 *   - "publisher"       — publisher OR admin
 *   - "admin"           — admin only
 *
 * The dashboard is meant for publishers + administrators. Respondents
 * (the iOS audience) can still sign in to read shared, view-only pages
 * (overview, pulse, trendx-index, account, accuracy), but they don't
 * see — and can't reach — the publisher/admin tooling.
 *
 * Rules are matched longest-prefix first so `/admin/...` beats
 * `/admin` and `/sectors/compare` beats `/sectors`. Anything not
 * matched defaults to "everyone".
 */

export type Role = "respondent" | "publisher" | "admin";
export type AccessGroup = "everyone" | "publisher" | "admin";

type Rule = { prefix: string; group: AccessGroup };

const RULES: Rule[] = [
  // most specific first
  { prefix: "/admin",            group: "admin" },
  { prefix: "/audiences",        group: "publisher" },
  { prefix: "/polls",            group: "publisher" },
  { prefix: "/surveys",          group: "publisher" },
  { prefix: "/sectors",          group: "publisher" },
  // shared / read-only
  { prefix: "/overview",         group: "everyone" },
  { prefix: "/pulse",            group: "everyone" },
  { prefix: "/trendx-index",     group: "everyone" },
  { prefix: "/account",          group: "everyone" },
  { prefix: "/accuracy",         group: "everyone" },
];

export function groupForPath(pathname: string): AccessGroup {
  for (const r of RULES) {
    if (pathname === r.prefix || pathname.startsWith(r.prefix + "/")) {
      return r.group;
    }
  }
  return "everyone";
}

export function canAccess(role: Role | undefined, group: AccessGroup): boolean {
  if (!role) return false;
  if (group === "everyone") return true;
  if (group === "publisher") return role === "publisher" || role === "admin";
  return role === "admin";
}

export function landingFor(role: Role | undefined): string {
  // Everyone lands on /overview after sign-in. Respondents see a
  // tailored overview, publishers/admins see the full dashboard.
  return "/overview";
}
