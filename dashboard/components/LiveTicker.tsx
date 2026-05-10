"use client";

import { useEffect, useState } from "react";
import { Activity, Zap } from "lucide-react";
import { fmtInt } from "@/lib/format";

type Event =
  | { type: "vote_cast"; pollId: string; pollTitle: string; city: string | null; deviceType: string; total: number; ts: number }
  | { type: "vote_milestone"; pollId: string; pollTitle: string; total: number; milestone: number; ts: number };

const API_BASE =
  process.env.NEXT_PUBLIC_TRENDX_API ?? "https://trendx-production.up.railway.app";

export function LiveTicker() {
  const [events, setEvents] = useState<Event[]>([]);
  const [connected, setConnected] = useState(false);

  useEffect(() => {
    const source = new EventSource(`${API_BASE}/events/dashboard`);
    source.addEventListener("ready", () => setConnected(true));

    const ingest = (raw: string) => {
      try {
        const parsed = JSON.parse(raw);
        setEvents((prev) => [{ ...parsed, ts: Date.now() }, ...prev].slice(0, 12));
      } catch {/* ignore */}
    };

    source.addEventListener("vote_cast", (ev) => ingest((ev as MessageEvent).data));
    source.addEventListener("vote_milestone", (ev) => ingest((ev as MessageEvent).data));
    source.onerror = () => setConnected(false);

    return () => source.close();
  }, []);

  return (
    <div className="bg-canvas-card rounded-card shadow-card p-6 h-full flex flex-col">
      <div className="flex items-center justify-between mb-5">
        <div>
          <div className="text-eyebrow text-brand-600 mb-1.5">REAL TIME</div>
          <h3 className="text-base font-display font-bold text-ink flex items-center gap-2">
            <Activity size={16} className="text-brand-500" />
            النبض الحيّ
          </h3>
        </div>
        <span
          className={`text-[10px] font-bold px-2.5 py-1 rounded-pill flex items-center gap-1.5 ${
            connected ? "bg-positive-soft text-positive" : "bg-canvas-well text-ink-mute"
          }`}
        >
          <span className={`w-1.5 h-1.5 rounded-full ${connected ? "bg-positive animate-pulse" : "bg-ink-mute"}`} />
          {connected ? "متّصل" : "بانتظار"}
        </span>
      </div>

      {events.length === 0 ? (
        <div className="flex-1 dotgrid rounded-chip flex flex-col items-center justify-center text-center py-12">
          <Zap size={28} className="text-ink-ghost mb-3" />
          <p className="text-xs text-ink-mute">بانتظار أوّل صوت يصل لحظياً…</p>
        </div>
      ) : (
        <ul className="space-y-2 max-h-[360px] overflow-y-auto -mx-2 px-2">
          {events.map((event, i) => (
            <li
              key={`${event.ts}-${i}`}
              className="flex items-start gap-3 p-3 rounded-chip hover:bg-canvas-well/60 transition group animate-fade-up"
            >
              <span
                className={`shrink-0 w-2 h-2 rounded-full mt-2 ${
                  event.type === "vote_milestone"
                    ? "bg-accent-500 shadow-[0_0_0_3px_rgba(250,124,18,0.25)]"
                    : "bg-brand-500"
                }`}
              />
              <div className="min-w-0 flex-1">
                <div className="text-[13px] text-ink font-medium leading-snug truncate">
                  {event.pollTitle}
                </div>
                <div className="text-[11px] text-ink-mute mt-1 flex items-center gap-2 flex-wrap">
                  {event.type === "vote_milestone" ? (
                    <>
                      <span className="font-bold text-accent-700">
                        وصل إلى {fmtInt(event.milestone)} صوت
                      </span>
                    </>
                  ) : (
                    <>
                      <span>صوت من {(event as Extract<Event, { type: "vote_cast" }>).city ?? "غير محدد"}</span>
                      <span>•</span>
                      <span className="tabular">{fmtInt(event.total)} مجموع</span>
                    </>
                  )}
                </div>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
