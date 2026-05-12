"use client";

// Cover-image picker used by `CreatePollModal` and `CreateSurveyModal`.
// Two paths to set the cover:
//
//   1. Pick a file → we client-side resize/recompress to keep bandwidth
//      reasonable, then POST it as multipart to `/api/upload` (a
//      Next.js route backed by Vercel Blob). The route returns a public
//      CDN URL which is what we store on the poll/survey row.
//   2. Paste a remote URL (Unsplash, ministry CDN, etc.) — verbatim.
//
// Either path resolves to a single short `image_url` string. The iOS
// app's `TrendXEditorialCover` renders the URL via `AsyncImage` and
// falls back to the topic gradient when the field is empty.

import { useRef, useState } from "react";
import { Upload, X, Image as ImageIcon, Link as LinkIcon, Loader2 } from "lucide-react";
import { useAuth } from "@/lib/auth";

const MAX_DIMENSION = 1600;
const JPEG_QUALITY = 0.85;

export function CoverImagePicker({
  value,
  onChange,
}: {
  value: string;
  onChange: (next: string) => void;
}) {
  const { token } = useAuth();
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const [mode, setMode] = useState<"file" | "url">(
    value.startsWith("http") ? "url" : "file",
  );
  const [error, setError] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);

  async function handleFile(file: File) {
    setError(null);
    if (!file.type.startsWith("image/")) {
      setError("الملف يجب أن يكون صورة (JPEG / PNG / WebP).");
      return;
    }
    if (!token) {
      setError("يجب تسجيل الدخول لرفع الصور.");
      return;
    }
    setUploading(true);
    try {
      const optimized = await resizeForUpload(file);
      const form = new FormData();
      form.append("file", optimized, optimized.name);
      const res = await fetch("/api/upload", {
        method: "POST",
        headers: { Authorization: `Bearer ${token}` },
        body: form,
      });
      const json = (await res.json().catch(() => ({}))) as {
        url?: string;
        error?: string;
      };
      if (!res.ok || !json.url) {
        throw new Error(json.error ?? "تعذّر رفع الصورة.");
      }
      onChange(json.url);
    } catch (e) {
      setError(e instanceof Error ? e.message : "تعذّر رفع الصورة.");
    } finally {
      setUploading(false);
    }
  }

  function clear() {
    onChange("");
    setError(null);
    if (fileInputRef.current) fileInputRef.current.value = "";
  }

  return (
    <div className="space-y-3">
      <div className="flex items-center gap-2">
        <ModePill
          icon={<ImageIcon size={12} />}
          label="رفع صورة"
          active={mode === "file"}
          onClick={() => setMode("file")}
        />
        <ModePill
          icon={<LinkIcon size={12} />}
          label="رابط صورة"
          active={mode === "url"}
          onClick={() => setMode("url")}
        />
      </div>

      {/* Preview */}
      {value && (
        <div className="relative w-full h-44 rounded-chip overflow-hidden bg-canvas-well">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={value}
            alt="معاينة الغلاف"
            className="w-full h-full object-cover"
          />
          <button
            type="button"
            onClick={clear}
            className="absolute top-2 end-2 w-8 h-8 rounded-pill bg-black/60 hover:bg-black/80 text-white grid place-items-center transition"
            aria-label="إزالة الصورة"
          >
            <X size={14} />
          </button>
        </div>
      )}

      {/* File mode */}
      {mode === "file" && !value && (
        <button
          type="button"
          onClick={() => fileInputRef.current?.click()}
          disabled={uploading}
          className="w-full h-32 rounded-chip border-2 border-dashed border-ink-line hover:border-brand-500/60 hover:bg-brand-50/40 transition grid place-items-center text-ink-soft disabled:opacity-60"
        >
          <div className="flex flex-col items-center gap-2">
            {uploading ? (
              <Loader2 size={20} className="text-brand-600 animate-spin" />
            ) : (
              <Upload size={20} className="text-ink-mute" />
            )}
            <span className="text-[13px] font-bold">
              {uploading ? "جاري الرفع…" : "اضغط لاختيار صورة"}
            </span>
            <span className="text-[11px] text-ink-mute">
              يُفضّل ≥ 1600×900 — سنضغطها ونرفعها على CDN تلقائياً
            </span>
          </div>
        </button>
      )}

      <input
        ref={fileInputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        className="hidden"
        onChange={(e) => {
          const f = e.target.files?.[0];
          if (f) void handleFile(f);
        }}
      />

      {/* URL mode */}
      {mode === "url" && (
        <input
          type="url"
          value={value}
          onChange={(e) => onChange(e.target.value.trim())}
          placeholder="https://images.unsplash.com/..."
          className="w-full px-4 py-3 rounded-chip bg-canvas-well text-[14px] text-ink placeholder:text-ink-mute outline-none focus:ring-2 focus:ring-brand-500/40 transition"
        />
      )}

      {error && (
        <div className="px-3 py-2 rounded-chip bg-negative-soft text-negative text-[12px] font-medium">
          {error}
        </div>
      )}
    </div>
  );
}

function ModePill({
  icon,
  label,
  active,
  onClick,
}: {
  icon: React.ReactNode;
  label: string;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-pill text-[12px] font-bold transition ${
        active
          ? "bg-brand-600 text-canvas-card"
          : "bg-canvas-well text-ink-soft hover:bg-brand-50"
      }`}
    >
      {icon}
      {label}
    </button>
  );
}

/// Resize the user-picked file so the longest edge is ≤ `MAX_DIMENSION`
/// and re-encode as JPEG. We do this client-side so the bytes that hit
/// `/api/upload` are already optimized — saves bandwidth and blob
/// storage, and the dashboard preview is snappier.
async function resizeForUpload(file: File): Promise<File> {
  const url = URL.createObjectURL(file);
  try {
    const img = await loadImage(url);
    const longest = Math.max(img.naturalWidth, img.naturalHeight);
    // If the source is already within budget AND already JPEG, ship it
    // through untouched to preserve quality.
    if (longest <= MAX_DIMENSION && file.type === "image/jpeg") {
      return file;
    }
    const scale = longest > MAX_DIMENSION ? MAX_DIMENSION / longest : 1;
    const w = Math.round(img.naturalWidth * scale);
    const h = Math.round(img.naturalHeight * scale);

    const canvas = document.createElement("canvas");
    canvas.width = w;
    canvas.height = h;
    const ctx = canvas.getContext("2d");
    if (!ctx) throw new Error("canvas-unavailable");
    ctx.drawImage(img, 0, 0, w, h);
    const blob: Blob = await new Promise((resolve, reject) => {
      canvas.toBlob(
        (b) => (b ? resolve(b) : reject(new Error("encode-failed"))),
        "image/jpeg",
        JPEG_QUALITY,
      );
    });
    return new File([blob], renameAsJpeg(file.name), {
      type: "image/jpeg",
      lastModified: Date.now(),
    });
  } finally {
    URL.revokeObjectURL(url);
  }
}

function renameAsJpeg(name: string) {
  const idx = name.lastIndexOf(".");
  const base = idx >= 0 ? name.slice(0, idx) : name;
  return `${base || "cover"}.jpg`;
}

function loadImage(src: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = reject;
    img.src = src;
  });
}
