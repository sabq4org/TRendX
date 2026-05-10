"use client";

import { useEffect, useState } from "react";
import { Plus, Trash2, Loader2, GripVertical } from "lucide-react";
import { api } from "@/lib/api";
import type { Topic } from "@/lib/types";

const MIN_OPTIONS = 2;
const MAX_OPTIONS = 6;
const MAX_QUESTIONS = 12;
const DURATION_PRESETS = [3, 7, 14, 30, 60];

type QuestionDraft = {
  title: string;
  type: "single_choice" | "multiple_choice" | "rating" | "linear_scale";
  rewardPoints: number;
  options: string[];
};

function blankQuestion(): QuestionDraft {
  return {
    title: "",
    type: "single_choice",
    rewardPoints: 25,
    options: ["", ""],
  };
}

export function CreateSurveyModal({
  token,
  onClose,
  onCreated,
}: {
  token: string;
  onClose: () => void;
  onCreated: (surveyId: string) => void;
}) {
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [topicId, setTopicId] = useState<string>("");
  const [rewardPoints, setRewardPoints] = useState<number>(120);
  const [durationDays, setDurationDays] = useState<number>(14);
  const [questions, setQuestions] = useState<QuestionDraft[]>([blankQuestion()]);

  const [topics, setTopics] = useState<Topic[]>([]);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api.topics(token).then(setTopics).catch(() => setTopics([]));
  }, [token]);

  const validQuestions = questions.filter(
    (q) =>
      q.title.trim().length >= 5 &&
      q.options.map((o) => o.trim()).filter(Boolean).length >= MIN_OPTIONS,
  );

  const canSubmit =
    title.trim().length >= 6 && validQuestions.length >= 1 && !submitting;

  function updateQuestion(idx: number, patch: Partial<QuestionDraft>) {
    setQuestions((prev) => prev.map((q, i) => (i === idx ? { ...q, ...patch } : q)));
  }

  async function submit() {
    if (!canSubmit) return;
    setSubmitting(true);
    setError(null);
    try {
      const res = await api.createSurvey(token, {
        survey: {
          title: title.trim(),
          description: description.trim() || undefined,
          topic_id: topicId || undefined,
          reward_points: rewardPoints,
          duration_days: durationDays,
        },
        questions: validQuestions.map((q) => ({
          title: q.title.trim(),
          type: q.type,
          reward_points: q.rewardPoints,
          options: q.options
            .map((o) => o.trim())
            .filter(Boolean)
            .map((text) => ({ text })),
        })),
      });
      onCreated(res.survey.id);
    } catch (e) {
      setError(e instanceof Error ? e.message : "تعذّر إنشاء الاستبيان.");
      setSubmitting(false);
    }
  }

  return (
    <div className="space-y-6">
      {/* Survey meta */}
      <div className="space-y-4 pb-5 border-b border-ink-line/40">
        <Field label="عنوان الاستبيان" required>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="مثال: قراءة معمّقة لشخصية المستهلك السعودي 2026"
            className="w-full px-4 py-3 rounded-chip bg-canvas-well text-[15px] font-medium text-ink placeholder:text-ink-mute outline-none focus:ring-2 focus:ring-brand-500/40 transition"
          />
        </Field>

        <Field label="وصف الاستبيان">
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            rows={2}
            placeholder="الهدف من البحث، والجمهور المستهدف، والمدّة المتوقعة…"
            className="w-full px-4 py-3 rounded-chip bg-canvas-well text-[14px] text-ink placeholder:text-ink-mute outline-none focus:ring-2 focus:ring-brand-500/40 transition resize-none"
          />
        </Field>

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

        <Field label={`المكافأة الكلّية: ${rewardPoints} نقطة`}>
          <input
            type="range"
            min={20}
            max={1000}
            step={10}
            value={rewardPoints}
            onChange={(e) => setRewardPoints(Number(e.target.value))}
            className="w-full accent-brand-600"
          />
        </Field>
      </div>

      {/* Questions */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-[14px] font-display font-bold text-ink">
            الأسئلة
            <span className="ms-2 text-[11px] font-bold text-ink-mute">
              {validQuestions.length}/{questions.length} مكتمل
            </span>
          </h3>
          {questions.length < MAX_QUESTIONS && (
            <button
              type="button"
              onClick={() => setQuestions([...questions, blankQuestion()])}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-pill bg-brand-50 text-[12px] font-bold text-brand-700 hover:bg-brand-100 transition"
            >
              <Plus size={13} />
              سؤال جديد
            </button>
          )}
        </div>

        <div className="space-y-3">
          {questions.map((q, idx) => (
            <QuestionCard
              key={idx}
              index={idx}
              draft={q}
              canDelete={questions.length > 1}
              onChange={(patch) => updateQuestion(idx, patch)}
              onDelete={() =>
                setQuestions((prev) => prev.filter((_, i) => i !== idx))
              }
            />
          ))}
        </div>
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
            نشر الاستبيان
          </button>
        </div>
      </div>
    </div>
  );
}

function QuestionCard({
  index,
  draft,
  canDelete,
  onChange,
  onDelete,
}: {
  index: number;
  draft: QuestionDraft;
  canDelete: boolean;
  onChange: (patch: Partial<QuestionDraft>) => void;
  onDelete: () => void;
}) {
  const validCount = draft.options.map((o) => o.trim()).filter(Boolean).length;

  return (
    <div className="bg-canvas-well/60 rounded-card p-5">
      <div className="flex items-start gap-3 mb-3">
        <GripVertical size={16} className="text-ink-mute mt-2.5 shrink-0" />
        <div className="flex-1 min-w-0 space-y-3">
          <div className="flex items-center gap-2">
            <span className="px-2 py-0.5 rounded-pill bg-brand-50 text-brand-700 text-[10px] font-bold tabular">
              س{index + 1}
            </span>
            <span className="text-[10px] uppercase tracking-[0.14em] text-ink-mute font-bold">
              سؤال {draft.type === "single_choice" ? "بإجابة واحدة" : draft.type}
            </span>
          </div>

          <input
            value={draft.title}
            onChange={(e) => onChange({ title: e.target.value })}
            placeholder="نصّ السؤال…"
            className="w-full px-3 py-2.5 rounded-chip bg-canvas-card text-[14px] font-medium text-ink placeholder:text-ink-mute outline-none focus:ring-2 focus:ring-brand-500/40 transition"
          />

          <div className="space-y-2">
            {draft.options.map((opt, oIdx) => (
              <div key={oIdx} className="flex items-center gap-2">
                <span className="w-6 h-6 rounded-pill bg-canvas-card text-ink-mute grid place-items-center text-[11px] font-bold tabular shrink-0">
                  {oIdx + 1}
                </span>
                <input
                  value={opt}
                  onChange={(e) => {
                    const next = [...draft.options];
                    next[oIdx] = e.target.value;
                    onChange({ options: next });
                  }}
                  placeholder={`الخيار ${oIdx + 1}`}
                  className="flex-1 px-3 py-2 rounded-chip bg-canvas-card text-[13px] text-ink placeholder:text-ink-mute outline-none focus:ring-2 focus:ring-brand-500/40 transition"
                />
                {draft.options.length > MIN_OPTIONS && (
                  <button
                    type="button"
                    onClick={() =>
                      onChange({
                        options: draft.options.filter((_, i) => i !== oIdx),
                      })
                    }
                    className="w-7 h-7 rounded-chip grid place-items-center text-ink-mute hover:text-negative transition"
                    aria-label="حذف"
                  >
                    <Trash2 size={12} />
                  </button>
                )}
              </div>
            ))}
          </div>

          <div className="flex items-center justify-between">
            {draft.options.length < MAX_OPTIONS ? (
              <button
                type="button"
                onClick={() => onChange({ options: [...draft.options, ""] })}
                className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-pill bg-canvas-card text-[11px] font-bold text-ink-soft hover:text-brand-700 transition"
              >
                <Plus size={11} />
                خيار
              </button>
            ) : (
              <span className="text-[11px] text-ink-mute">
                وصلت أقصى عدد ({MAX_OPTIONS})
              </span>
            )}
            <span className="text-[11px] tabular text-ink-mute">
              {validCount} خيار صالح
            </span>
          </div>
        </div>

        {canDelete && (
          <button
            type="button"
            onClick={onDelete}
            className="w-8 h-8 rounded-chip grid place-items-center text-ink-mute hover:bg-negative/5 hover:text-negative transition shrink-0"
            aria-label="حذف السؤال"
          >
            <Trash2 size={14} />
          </button>
        )}
      </div>
    </div>
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
