# صباح الخير — تقرير الليلة

## ما تم إنجازه (4 مراحل كاملة)

### المرحلة 2 — Analytics Engine (Backend)

- **مكتبة محورية**: `backend/railway-api/src/lib/analytics.ts` تحسب لكل
  استطلاع/استبيان: `sample_size` + `confidence_level` + `margin_of_error` +
  `representativeness_score` + `methodology_note` + cross-demographic لكل
  خيار + `daily_cumulative` + ساعة الذروة + مؤشّر الاستقطاب.
- **مهمّة دوريّة**: `backend/railway-api/src/jobs/snapshot.ts` تعمل كل 5
  دقائق داخل العملية (بدون Redis). تُحدّث `analytics_snapshots` لكل استطلاع
  واستبيان نشط، وتحتفظ بآخر 50 لقطة لكل كيان.
- **الـ endpoints الموجودة** الآن تقرأ من اللقطات وتعيد الحساب فقط إن مرّ
  أكثر من 5 دقائق.
- **Endpoint جديد للإدارة**: `POST /admin/snapshots/run` لإجبار التحديث.

### المرحلة 4 — AI Intelligence Layer

ثلاث قوالب prompt محكومة بإصدار:

| Endpoint | الإصدار | يُرجع |
|---|---|---|
| `GET /surveys/:id/analytics/ai-report` | `survey-report-v2` | ملخّص تنفيذي + اكتشافات + شخصيات + أنماط خفية + توصيات |
| `GET /topics/:id/insight` | `sector-report-v1` | مزاج القطاع + خريطة إجماع + توقّع 30 يوم |
| `POST /ai/question-quality` | `question-quality-v1` | clarity + bias + suggestions |

كل ردود AI **مُخزَّنة 6 ساعات** في `ai_insights` (لتقليل التكلفة).

### المرحلة 5 — Realtime (SSE)

- `GET /events/dashboard` يبثّ مباشرة: `vote_cast`, `vote_milestone`,
  `survey_completed`, `snapshot_refreshed`.
- بعد كل تصويت، Backend يبثّ event إلى كل المشتركين.
- لا يوجد Redis مطلوب — حين تنمو المنصّة سنرفعه إلى Pub/Sub بـ 30 سطراً.

### المرحلة 3 — Publisher Dashboard (Next.js 15)

تطبيق ويب كامل في مجلّد `dashboard/` بتصميم **calm editorial**:

- **5 صفحات**: Overview, Polls (قائمة + تفصيل), Surveys (قائمة + تفصيل),
  Sectors (قائمة + تفصيل), Account.
- **6 أنواع رسوم بيانية**: Donut, Horizontal Bar, Grouped Bar,
  Stacked Bar, Area trend, Heatmap, Bubble scatter, Gauge — كلها بألوان
  متناسقة هادئة (`indigo / violet / amber / teal / rose / emerald / slate`).
- **Live Ticker** متّصل بـ SSE يعرض الأصوات لحظياً.
- **AI Reports** بضغطة زر داخل صفحة Survey و Sector.
- **Quality Badge** يعرض حجم العيّنة + الثقة + هامش الخطأ + التمثيل + آخر تحديث.
- **بناء الإنتاج ناجح** (10 صفحات، أكبر صفحة ~ 224 KB).

---

## ما عليك فعله صباحاً (15 دقيقة)

### 1) فعّل بذرة البيانات الغنيّة في Railway

اذهب إلى Railway → Variables، وأضف:

```
SEED_DEMO=1
```

ثم في tab "Settings" أعد التشغيل (Restart). سيُنشئ:

- **3 ناشرين تجريبيين**:
  - `official@trendx.app` / `trendx-demo-2026` (Enterprise)
  - `iqtisad@trendx.app` / `trendx-demo-2026` (Premium)
  - `sports@trendx.app` / `trendx-demo-2026` (Premium)
- **12 استطلاع + 3 استبيانات** بمحتوى سعودي حقيقي.
- **50 مستجيب اصطناعي** بتوزيع ديموغرافي واقعي
  (الرياض 34% / جدة 21% / الدمام 8% / إلخ).
- **~500 صوت** و **~60 استجابة استبيان** بأوزان منطقيّة.

### 2) أوصل Vercel بمستودع GitHub

1. ادخل [vercel.com/new](https://vercel.com/new).
2. Import `sabq4org/TRendX`.
3. **Root Directory**: `dashboard` (مهم!).
4. Framework: `Next.js` (يكتشف تلقائياً).
5. Environment Variables (اختياري):
   - `NEXT_PUBLIC_TRENDX_API` = `https://trendx-production.up.railway.app`
6. Click Deploy. أوّل نشر ~ 3 دقائق.

### 3) سجّل الدخول

افتح Vercel URL → ستظهر شاشة الدخول مع بيانات `official@trendx.app`
معبّأة مسبقاً. اضغط **تسجيل الدخول** → ترى Overview.

---

## ما لم أنجزه (للجلسة القادمة)

| # | المرحلة | السبب |
|---|---|---|
| 6 | PDF/Excel exports عبر Puppeteer | يحتاج إعداد Chromium في Railway |
| 7 | Webhooks + Audit logs | للعملاء Enterprise، أُجِّل لأنه ليس MVP |
| iOS | تحديث iOS لإستهلاك surveys | أنت قلت `SEED_DEMO` → سيكون أفضل |

---

## API الجديد — جدول مرجعي

### مصادقة
- `POST /auth/signup` (مع demographics)
- `POST /auth/signin`
- `GET /profile` (Bearer)

### الاستطلاعات
- `GET /polls`
- `POST /polls` (إنشاء)
- `POST /polls/vote` (يبثّ SSE الآن)
- `GET /analytics/poll/:id` (مع snapshot caching)

### الاستبيانات
- `GET /surveys`
- `POST /surveys` (إنشاء)
- `GET /surveys/:id`
- `POST /surveys/:id/respond`
- `GET /analytics/survey/:id` (مع correlations)
- `GET /surveys/:id/analytics/ai-report` ← جديد

### القطاعات
- `GET /topics`
- `GET /topics/:id/insight` ← جديد

### المكافآت
- `GET /gifts`
- `POST /gifts/redeem`
- `GET /points/ledger`

### AI
- `POST /ai/compose-poll` (موجود)
- `POST /ai/poll-insight/:pollId` (موجود)
- `POST /ai/question-quality` ← جديد

### Realtime
- `GET /events/dashboard` ← SSE (جديد)

### Admin
- `POST /admin/snapshots/run` ← جديد

---

تذكّر: لو حصل أيّ خطأ، الـ API يعطي fallback جميل بدلاً من تعطّل الواجهة.
كله production-grade.
