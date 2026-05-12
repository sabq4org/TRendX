"use client";

import { useEffect, useState } from "react";
import { Loader2 } from "lucide-react";
import { api } from "@/lib/api";
import type { Survey, Topic } from "@/lib/types";
import { CoverImagePicker } from "./CoverImagePicker";

// EditSurveyModal — same constraint as polls: question/option ids are
// referenced by the cast answers, so we only mutate the safe metadata
// fields. Use delete if the question set needs to change.

export function EditSurveyModal({
  token,
  survey,
  onClose,
  onSaved,
  onDeleted,
}: {
  token: string;
  survey: Survey;
  onClose: () => void;
  onSaved: (survey: Survey) => void;
  onDeleted: () => void;
}) {
  const [title, setTitle] = useState(survey.title);
  const [description, setDescription] = useState(survey.description ?? "");
  const [imageUrl, setImageUrl] = useState(survey.image_url ?? "");
  const [topicId, setTopicId] = useState<string>(survey.topic_id ?? "");
  const initialExpiresLocal = survey.expires_at
    ? toLocalInput(new Date(survey.expires_at))
    : "";
  const [expiresAt, setExpiresAt] = useState(initialExpiresLocal);

  const [topics, setTopics] = useState<Topic[]>([]);
  const [submitting, setSubmitting] = useState(false);
  const [confirmingDelete, setConfirmingDelete] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api.topics(token).then(setTopics).catch(() => setTopics([]));
  }, [token]);

  const canSubmit = title.trim().length >= 4 && !submitting;

  async function submit() {
    if (!canSubmit) return;
    setSubmitting(true);
    setError(null);
    try {
      const payload: Parameters<typeof api.updateSurvey>[2] = {
        title: title.trim(),
        description: description.trim() || undefined,
        image_url: imageUrl.trim() || null,
        topic_id: topicId || null,
      };
      if (expiresAt && expiresAt !== initialExpiresLocal) {
        const next = new Date(expiresAt);
        if (Number.isNaN(next.getTime()) || next.getTime() <= Date.now()) {
          setError("تاريخ الإغلاق يجب أن يكون في المستقبل.");
          setSubmitting(false);
          return;
        }
        payload.expires_at = next.toISOString();
      }
      const res = await api.updateSurvey(token, survey.id, payload);
      onSaved(res.survey);
    } catch (e) {
      setError(e instanceof Error ? e.message : "تعذّر حفظ التعديلات.");
      setSubmitting(false);
    }
  }

  async function doDelete() {
    setSubmitting(true);
    setError(null);
    try {
      await api.deleteSurvey(token, survey.id);
      onDeleted();
    } catch (e) {
      setError(e instanceof Error ? e.message : "تعذّر حذف الاستبيان.");
      setSubmitting(false);
      setConfirmingDelete(false);
    }
  }

  return (
    <div className="space-y-6">
      <Field label="عنوان الاستبيان" required>
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          className="w-full px-4 py-3 rounded-chip bg-canvas-well text-[15px] font-medium text-ink outline-none focus:ring-2 focus:ring-brand-500/40 transition"
        />
      </Field>

      <Field label="الوصف">
        <textarea
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          rows={3}
          className="w-full px-4 py-3 rounded-chip bg-canvas-well text-[14px] text-ink outline-none focus:ring-2 focus:ring-brand-500/40 transition resize-none"
        />
      </Field>

      <Field label="صورة الغلاف">
        <CoverImagePicker value={imageUrl} onChange={setImageUrl} />
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

        <Field label="تاريخ الإغلاق">
          <input
            type="datetime-local"
            value={expiresAt}
            onChange={(e) => setExpiresAt(e.target.value)}
            className="w-full px-4 py-3 rounded-chip bg-canvas-well text-[14px] font-medium text-ink outline-none focus:ring-2 focus:ring-brand-500/40 transition"
          />
        </Field>
      </div>

      <div className="rounded-chip border border-ink-line/60 bg-canvas-well/40 px-4 py-3 text-[12px] text-ink-mute leading-relaxed">
        لا يمكن تعديل الأسئلة والخيارات بعد بدء جمع الردود. إذا احتجت لتغيير
        بنية الاستبيان احذفه وأنشئ بديلاً.
      </div>

      {error && (
        <div className="px-4 py-3 rounded-chip bg-negative-soft text-negative text-[13px] font-medium">
          {error}
        </div>
      )}

      <div className="flex items-center justify-between gap-3 pt-3 border-t border-ink-line/40">
        {confirmingDelete ? (
          <div className="flex items-center gap-2">
            <span className="text-[12px] font-bold text-negative">تأكيد الحذف؟</span>
            <button
              type="button"
              onClick={doDelete}
              disabled={submitting}
              className="px-3 py-1.5 rounded-pill bg-negative text-canvas-card text-[12px] font-bold hover:bg-negative/90 transition disabled:opacity-50"
            >
              نعم، احذفه نهائيّاً
            </button>
            <button
              type="button"
              onClick={() => setConfirmingDelete(false)}
              className="px-3 py-1.5 rounded-pill bg-canvas-well text-[12px] font-bold text-ink-soft hover:bg-canvas-well/70 transition"
            >
              تراجع
            </button>
          </div>
        ) : (
          <button
            type="button"
            onClick={() => setConfirmingDelete(true)}
            className="text-[12px] font-bold text-negative hover:underline transition"
          >
            حذف الاستبيان
          </button>
        )}

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
            حفظ التعديلات
          </button>
        </div>
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

function toLocalInput(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(
    d.getHours(),
  )}:${pad(d.getMinutes())}`;
}
