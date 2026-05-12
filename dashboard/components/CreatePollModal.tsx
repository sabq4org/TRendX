"use client";

import { useEffect, useState } from "react";
import { Plus, Trash2, Loader2 } from "lucide-react";
import { api } from "@/lib/api";
import type { Topic } from "@/lib/types";
import { CoverImagePicker } from "./CoverImagePicker";

const MIN_OPTIONS = 2;
const MAX_OPTIONS = 6;

const POLL_TYPES = [
  { value: "single_choice",   label: "اختيار واحد" },
  { value: "multiple_choice", label: "اختيار متعدّد" },
  { value: "rating",          label: "تقييم نجمي" },
  { value: "linear_scale",    label: "مقياس خطّي" },
] as const;

const DURATION_PRESETS = [1, 3, 7, 14, 30];

export function CreatePollModal({
  token,
  onClose,
  onCreated,
}: {
  token: string;
  onClose: () => void;
  onCreated: (pollId: string) => void;
}) {
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [imageUrl, setImageUrl] = useState("");
  const [topicId, setTopicId] = useState<string>("");
  const [type, setType] = useState<typeof POLL_TYPES[number]["value"]>("single_choice");
  const [rewardPoints, setRewardPoints] = useState<number>(50);
  const [durationDays, setDurationDays] = useState<number>(7);
  const [options, setOptions] = useState<string[]>(["", ""]);

  const [topics, setTopics] = useState<Topic[]>([]);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api.topics(token).then(setTopics).catch(() => setTopics([]));
  }, [token]);

  const validOptions = options.map((o) => o.trim()).filter(Boolean);
  const canSubmit =
    title.trim().length >= 6 &&
    validOptions.length >= MIN_OPTIONS &&
    !submitting;

  async function submit() {
    if (!canSubmit) return;
    setSubmitting(true);
    setError(null);
    try {
      const res = await api.createPoll(token, {
        poll: {
          title: title.trim(),
          description: description.trim() || undefined,
          image_url: imageUrl.trim() || undefined,
          topic_id: topicId || undefined,
          type,
          reward_points: rewardPoints,
          duration_days: durationDays,
        },
        options: validOptions.map((text) => ({ text })),
      });
      onCreated(res.poll.id);
    } catch (e) {
      setError(e instanceof Error ? e.message : "تعذّر إنشاء الاستطلاع.");
      setSubmitting(false);
    }
  }

  return (
    <>
      <div className="space-y-6">
        {/* Title */}
        <Field label="عنوان الاستطلاع" required>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="مثال: ما الذي يُؤرّق جيلك حالياً؟"
            className="w-full px-4 py-3 rounded-chip bg-canvas-well text-[15px] font-medium text-ink placeholder:text-ink-mute outline-none focus:ring-2 focus:ring-brand-500/40 transition"
          />
        </Field>

        <Field label="وصف اختياري">
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            rows={2}
            placeholder="سياق إضافي يساعد المستجيب يفهم السؤال…"
            className="w-full px-4 py-3 rounded-chip bg-canvas-well text-[14px] text-ink placeholder:text-ink-mute outline-none focus:ring-2 focus:ring-brand-500/40 transition resize-none"
          />
        </Field>

        <Field label="صورة الغلاف (اختياري)">
          <CoverImagePicker value={imageUrl} onChange={setImageUrl} />
        </Field>

        {/* Topic + Type */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Field label="القطاع">
            <select
              value={topicId}
              onChange={(e) => setTopicId(e.target.value)}
              className="w-full px-4 py-3 rounded-chip bg-canvas-well text-[14px] font-medium text-ink outline-none focus:ring-2 focus:ring-brand-500/40 transition"
            >
              <option value="">— بدون تصنيف —</option>
              {topics.map((t) => (
                <option key={t.id} value={t.id}>
                  {t.name}
                </option>
              ))}
            </select>
          </Field>

          <Field label="نوع الاستطلاع">
            <select
              value={type}
              onChange={(e) => setType(e.target.value as typeof type)}
              className="w-full px-4 py-3 rounded-chip bg-canvas-well text-[14px] font-medium text-ink outline-none focus:ring-2 focus:ring-brand-500/40 transition"
            >
              {POLL_TYPES.map((t) => (
                <option key={t.value} value={t.value}>
                  {t.label}
                </option>
              ))}
            </select>
          </Field>
        </div>

        {/* Reward + Duration */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Field label={`المكافأة: ${rewardPoints} نقطة`}>
            <input
              type="range"
              min={10}
              max={500}
              step={10}
              value={rewardPoints}
              onChange={(e) => setRewardPoints(Number(e.target.value))}
              className="w-full accent-brand-600"
            />
          </Field>

          <Field label="المدّة">
            <div className="flex flex-wrap gap-2">
              {DURATION_PRESETS.map((d) => (
                <button
                  key={d}
                  type="button"
                  onClick={() => setDurationDays(d)}
                  className={`px-3 py-2 rounded-pill text-[12px] font-bold transition ${
                    durationDays === d
                      ? "bg-brand-600 text-canvas-card"
                      : "bg-canvas-well text-ink-soft hover:bg-brand-50"
                  }`}
                >
                  {d} يوم
                </button>
              ))}
            </div>
          </Field>
        </div>

        {/* Options */}
        <div>
          <div className="flex items-center justify-between mb-3">
            <label className="text-[12px] font-bold uppercase tracking-[0.14em] text-ink-soft">
              الخيارات
            </label>
            <span className="text-[11px] text-ink-mute">
              {validOptions.length} / {MAX_OPTIONS}
            </span>
          </div>

          <div className="space-y-2">
            {options.map((opt, idx) => (
              <div key={idx} className="flex items-center gap-2">
                <span className="w-7 h-7 rounded-pill bg-brand-50 text-brand-700 grid place-items-center text-[12px] font-bold tabular shrink-0">
                  {idx + 1}
                </span>
                <input
                  value={opt}
                  onChange={(e) => {
                    const next = [...options];
                    next[idx] = e.target.value;
                    setOptions(next);
                  }}
                  placeholder={`الخيار ${idx + 1}`}
                  className="flex-1 px-4 py-2.5 rounded-chip bg-canvas-well text-[14px] text-ink placeholder:text-ink-mute outline-none focus:ring-2 focus:ring-brand-500/40 transition"
                />
                {options.length > MIN_OPTIONS && (
                  <button
                    type="button"
                    onClick={() => setOptions(options.filter((_, i) => i !== idx))}
                    className="w-9 h-9 rounded-chip grid place-items-center text-ink-mute hover:bg-negative/5 hover:text-negative transition"
                    aria-label="حذف"
                  >
                    <Trash2 size={14} />
                  </button>
                )}
              </div>
            ))}
          </div>

          {options.length < MAX_OPTIONS && (
            <button
              type="button"
              onClick={() => setOptions([...options, ""])}
              className="mt-3 inline-flex items-center gap-1.5 px-3 py-1.5 rounded-pill bg-canvas-well text-[12px] font-bold text-ink-soft hover:bg-brand-50 hover:text-brand-700 transition"
            >
              <Plus size={13} />
              إضافة خيار
            </button>
          )}
        </div>

        {error && (
          <div className="px-4 py-3 rounded-chip bg-negative-soft text-negative text-[13px] font-medium">
            {error}
          </div>
        )}

        <div className="flex items-center justify-between gap-3 pt-3 border-t border-ink-line/40">
          <span className="text-[12px] text-ink-mute">
            سيظهر فوراً في تطبيق iOS بعد النشر.
          </span>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2.5 rounded-chip bg-canvas-well text-[13px] font-bold text-ink-soft hover:bg-canvas-well/70 transition"
            >
              إلغاء
            </button>
            <button
              type="button"
              onClick={submit}
              disabled={!canSubmit}
              className={`inline-flex items-center gap-2 px-5 py-2.5 rounded-chip text-[13px] font-bold transition ${
                canSubmit
                  ? "bg-brand-600 text-canvas-card hover:bg-brand-700 shadow-card"
                  : "bg-ink-line/50 text-ink-mute cursor-not-allowed"
              }`}
            >
              {submitting && <Loader2 size={14} className="animate-spin" />}
              نشر الاستطلاع
            </button>
          </div>
        </div>
      </div>
    </>
  );
}

function Field({
  label,
  required,
  children,
}: {
  label: string;
  required?: boolean;
  children: React.ReactNode;
}) {
  return (
    <label className="block">
      <span className="block text-[12px] font-bold uppercase tracking-[0.14em] text-ink-soft mb-2">
        {label}
        {required && <span className="text-negative ms-1">*</span>}
      </span>
      {children}
    </label>
  );
}
