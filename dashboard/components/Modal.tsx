"use client";

import { useEffect } from "react";
import { X } from "lucide-react";

/**
 * Lightweight overlay dialog used by create-poll / create-survey screens.
 * Renders a centered card on a dimmed scrim, traps Escape, and prevents
 * background scroll while open. Scoped intentionally to this dashboard:
 * we don't want to pull a full headless-ui dependency for two surfaces.
 */
export function Modal({
  open,
  onClose,
  title,
  subtitle,
  children,
  footer,
  width = "lg",
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  subtitle?: string;
  children: React.ReactNode;
  footer?: React.ReactNode;
  width?: "md" | "lg" | "xl";
}) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    document.addEventListener("keydown", onKey);
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = prev;
    };
  }, [open, onClose]);

  if (!open) return null;

  const widthClass =
    width === "md" ? "max-w-xl" : width === "xl" ? "max-w-4xl" : "max-w-2xl";

  return (
    <div
      className="fixed inset-0 z-50 flex items-start justify-center p-6 overflow-y-auto bg-ink/40 backdrop-blur-sm"
      onClick={onClose}
    >
      <div
        className={`w-full ${widthClass} mt-12 mb-12 bg-canvas-card rounded-card shadow-card-lift overflow-hidden`}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="px-7 pt-6 pb-5 border-b border-ink-line/40 flex items-start justify-between gap-4">
          <div className="min-w-0">
            <h2 className="text-xl font-display font-black tracking-tight text-ink leading-tight">
              {title}
            </h2>
            {subtitle && (
              <p className="text-[13px] text-ink-mute mt-1.5 leading-relaxed">
                {subtitle}
              </p>
            )}
          </div>
          <button
            onClick={onClose}
            className="w-9 h-9 rounded-chip grid place-items-center border border-ink-line/60 text-ink-mute hover:bg-negative/5 hover:text-negative hover:border-negative/30 transition shrink-0"
            aria-label="إغلاق"
          >
            <X size={16} />
          </button>
        </div>

        <div className="px-7 py-6 max-h-[68vh] overflow-y-auto">{children}</div>

        {footer && (
          <div className="px-7 py-4 border-t border-ink-line/40 bg-canvas-well/40">
            {footer}
          </div>
        )}
      </div>
    </div>
  );
}
