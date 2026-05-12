// Auth-gated cover-image uploader backed by Vercel Blob.
//
// Flow: dashboard's `CoverImagePicker` POSTs `multipart/form-data` with
// a single `file` field and the user's TRENDX JWT in the Authorization
// header. We verify the token by hitting `/profile` on the Railway API
// (the only system that knows whether a token is valid), then hand the
// bytes off to Vercel Blob and return the public CDN URL.
//
// Storing real CDN URLs instead of base64 data-URIs keeps the polls /
// surveys tables small, makes /bootstrap responses fast, and offloads
// image delivery to Vercel's edge network.
//
// Required env var:
//   BLOB_READ_WRITE_TOKEN  — generated in the Vercel project's Storage
//                            tab. Never commit this value.

import { NextResponse } from "next/server";
import { put } from "@vercel/blob";

const MAX_BYTES = 5 * 1024 * 1024; // 5 MB raw upload ceiling
const ALLOWED_TYPES = new Set(["image/jpeg", "image/png", "image/webp"]);

const TRENDX_API =
  process.env.NEXT_PUBLIC_TRENDX_API ??
  "https://trendx-production.up.railway.app";

export const runtime = "nodejs";

export async function POST(request: Request) {
  // 1. Auth gate — only authenticated TRENDX publishers may upload.
  const auth = request.headers.get("authorization") ?? "";
  const token = auth.startsWith("Bearer ") ? auth.slice(7).trim() : "";
  if (!token) {
    return NextResponse.json({ error: "Missing bearer token." }, { status: 401 });
  }
  const profileRes = await fetch(`${TRENDX_API}/profile`, {
    headers: { Authorization: `Bearer ${token}` },
    cache: "no-store",
  });
  if (!profileRes.ok) {
    return NextResponse.json({ error: "Invalid or expired token." }, { status: 401 });
  }
  const profile = (await profileRes.json().catch(() => null)) as
    | { id?: string }
    | null;
  const userId = profile?.id ?? "anon";

  // 2. Multipart body — must contain a single `file`.
  let form: FormData;
  try {
    form = await request.formData();
  } catch {
    return NextResponse.json({ error: "Invalid multipart body." }, { status: 400 });
  }
  const file = form.get("file");
  if (!(file instanceof Blob)) {
    return NextResponse.json({ error: "Missing file field." }, { status: 400 });
  }

  // 3. Validate file — type + size before paying for the blob put.
  const type = file.type || "application/octet-stream";
  if (!ALLOWED_TYPES.has(type)) {
    return NextResponse.json(
      { error: "Unsupported image type. Use JPEG, PNG, or WebP." },
      { status: 415 },
    );
  }
  if (file.size === 0) {
    return NextResponse.json({ error: "Empty file." }, { status: 400 });
  }
  if (file.size > MAX_BYTES) {
    return NextResponse.json(
      { error: `File too large (max ${MAX_BYTES / 1024 / 1024} MB).` },
      { status: 413 },
    );
  }

  // 4. Upload — namespaced by user so blobs are easy to audit / clean
  // up. `addRandomSuffix` avoids collisions when the same user uploads
  // two covers in the same millisecond.
  const ext =
    type === "image/png" ? "png" : type === "image/webp" ? "webp" : "jpg";
  const path = `covers/${userId}/${Date.now()}.${ext}`;

  try {
    const blob = await put(path, file, {
      access: "public",
      contentType: type,
      addRandomSuffix: true,
    });
    return NextResponse.json({ url: blob.url });
  } catch (err) {
    const message = err instanceof Error ? err.message : "upload failed";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
