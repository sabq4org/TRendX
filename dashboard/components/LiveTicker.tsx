"use client";

import { useEffect, useState } from "react";
import { Activity } from "lucide-react";
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
      } catch {
        // ignore malformed event
      }
    };

    source.addEventListener("vote_cast", (ev) => ingest((ev as MessageEvent).data));
    source.addEventListener("vote_milestone", (ev) => ingest((ev as MessageEvent).data));
    source.onerror = () => setConnected(false);

    return () => {
      source.close();
    };
  }, []);

  return (
    <div className="bg-canvas-card rounded-card shadow-card p-5">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-sm font-bold text-ink flex items-center gap-2">
          <Activity size={15} className="text-success" />
          النبض الحيّ
        </h3>
        <span
          className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
            connected ? "bg-success/10 text-success" : "bg-ink-line text-ink-mute"
          }`}
        >
          {connected ? "متصل" : "بانتظار"}
        </span>
      </div>

      {events.length === 0 ? (
        <div className="text-xs text-ink-mute py-8 text-center">
          بانتظار أوّل صوت يصل لحظياً…
        </div>
      ) : (
        <ul className="space-y-2 max-h-72 overflow-y-auto">
          {events.map((event, i) => (
            <li
              key={`${event.ts}-${i}`}
              className="flex items-start gap-3 p-2.5 rounded-chip hover:bg-canvas-well transition"
            >
              <span
                className={`shrink-0 w-1.5 h-1.5 rounded-full mt-2 ${
                  event.type === "vote_milestone" ? "bg-warn" : "bg-brand-500"
                }`}
              />
              <div className="min-w-0 flex-1">
                <div className="text-xs text-ink truncate font-medium">{event.pollTitle}</div>
                <div className="text-[10px] text-ink-mute mt-0.5">
                  {event.type === "vote_milestone"
                    ? `الوصول إلى ${fmtInt(event.milestone)} صوت`
                    : `صوت من ${(event as Extract<Event, { type: "vote_cast" }>).city ?? "غير محدد"}  ·  ${fmtInt(event.total)} مجموع`}
                </div>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
