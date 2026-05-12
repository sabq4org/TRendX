/**
 * Handle (@username) normalization, validation, and reservation
 * lookup.
 *
 * Rules:
 *  - Strip a leading '@'.
 *  - Lowercase for storage and comparison.
 *  - 3..20 chars, ASCII alphanumeric + underscore.
 *  - Reserved handles in `reserved_handles` can only be claimed by an
 *    admin operation (separate endpoint). A regular signup or profile
 *    update that tries to take one is rejected.
 *  - Existing handle on another user → conflict.
 */

import { prisma } from "../db.js";

const HANDLE_RE = /^[a-z0-9_]{3,20}$/;

export function normalizeHandle(input: string): string {
  return input.trim().replace(/^@+/, "").toLowerCase();
}

export type HandleCheck =
  | { ok: true; handle: string }
  | { ok: false; reason: "invalid" | "reserved" | "taken"; message: string };

/**
 * Validate a candidate handle for the given user. `ownerId` lets a user
 * keep their existing handle on a profile update without a "taken"
 * false-positive.
 */
export async function validateHandle(
  raw: string,
  ownerId?: string,
): Promise<HandleCheck> {
  const handle = normalizeHandle(raw);

  if (!HANDLE_RE.test(handle)) {
    return {
      ok: false,
      reason: "invalid",
      message:
        "المعرّف يجب أن يكون من 3 إلى 20 حرفاً، أحرف لاتينية أو أرقام أو شرطة سفلية فقط.",
    };
  }

  // Ownership shortcut: if the requester *already* holds this handle,
  // accept the request without consulting the reservation list. Without
  // this the Ministry of Media (handle "moia") cannot save its own
  // profile because "moia" is reserved-for the Ministry of Media — the
  // reservation check would reject the legitimate owner.
  const existing = await prisma.user.findUnique({ where: { handle } });
  if (existing && ownerId && existing.id === ownerId) {
    return { ok: true, handle };
  }

  const reserved = await prisma.reservedHandle.findUnique({
    where: { handle },
  });
  if (reserved) {
    return {
      ok: false,
      reason: "reserved",
      message: `هذا المعرّف محجوز لـ${reserved.reservedFor ?? "جهة رسمية"} — لا يمكن استخدامه.`,
    };
  }

  if (existing && existing.id !== ownerId) {
    return {
      ok: false,
      reason: "taken",
      message: "هذا المعرّف محجوز من قِبل مستخدم آخر.",
    };
  }

  return { ok: true, handle };
}
