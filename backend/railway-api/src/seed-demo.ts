/**
 * Optional rich demo seeder. Runs only when SEED_DEMO=1 is set on Railway,
 * so it never accidentally pollutes a real publisher's data.
 *
 * Generates a believable Saudi-context dataset:
 *  - 3 publishers (TRENDX Official, Al Iqtisad, TRENDX Sports)
 *  - 12 polls covering tech / economy / sports / social / health
 *  - 3 multi-question surveys
 *  - ~500 simulated votes with weighted demographics
 *  - ~60 survey responses
 *
 * Idempotent: every entity is keyed by a deterministic email/title so the
 * job is safe to re-run.
 */

import {
  PrismaClient,
  type Gender,
  type DeviceType,
  type Prisma,
} from "@prisma/client";
import { hashPassword, makeSalt } from "./auth.js";

const prisma = new PrismaClient();

// --- Publishers --------------------------------------------------------------

const PUBLISHERS = [
  {
    email: "official@trendx.app",
    name: "TRENDX Official",
    avatarInitial: "T",
    tier: "enterprise" as const,
    role: "publisher" as const,
    city: "الرياض",
    region: "الرياض",
    gender: "unspecified" as const,
    birthYear: 1995,
  },
  {
    email: "iqtisad@trendx.app",
    name: "الاقتصاد",
    avatarInitial: "ا",
    tier: "premium" as const,
    role: "publisher" as const,
    city: "الرياض",
    region: "الرياض",
    gender: "unspecified" as const,
    birthYear: 1990,
  },
  {
    email: "sports@trendx.app",
    name: "TRENDX Sports",
    avatarInitial: "S",
    tier: "premium" as const,
    role: "publisher" as const,
    city: "جدة",
    region: "مكة المكرمة",
    gender: "unspecified" as const,
    birthYear: 1988,
  },
];

// --- Topics ------------------------------------------------------------------

type TopicSlug =
  | "tech" | "economy" | "sports" | "social" | "media" | "health";

// --- Polls (12 — distributed across topics) ----------------------------------

const POLLS: Array<{
  publisherEmail: string;
  topicSlug: TopicSlug;
  title: string;
  description?: string;
  options: string[];
  rewardPoints: number;
  isFeatured?: boolean;
  isBreaking?: boolean;
  weights: number[]; // distribution probabilities (sum to 1)
}> = [
  {
    publisherEmail: "official@trendx.app",
    topicSlug: "tech",
    title: "هل ترى أن الذكاء الاصطناعي سيغيّر سوق العمل في المملكة خلال 5 سنوات؟",
    description: "تقييم رؤية الجمهور لتأثير AI على الوظائف",
    options: ["نعم، تغيير جذري", "تغيير متوسط", "تغيير محدود", "لا أتوقع تغييراً"],
    rewardPoints: 60,
    isFeatured: true,
    weights: [0.51, 0.30, 0.13, 0.06],
  },
  {
    publisherEmail: "official@trendx.app",
    topicSlug: "tech",
    title: "أيّ تقنية ترى أنها الأكثر تأثيراً على حياتك اليومية اليوم؟",
    options: ["الذكاء الاصطناعي", "الواقع المعزّز", "السيارات الذاتية", "إنترنت الأشياء"],
    rewardPoints: 45,
    weights: [0.62, 0.14, 0.10, 0.14],
  },
  {
    publisherEmail: "iqtisad@trendx.app",
    topicSlug: "economy",
    title: "ما تقييمك لجاذبية المملكة الاستثمارية مقارنةً بنهاية 2025؟",
    description: "بناءً على المؤشرات الكلية وحركة الأسواق",
    options: ["تحسّن قوي", "تحسّن متوسط", "بقيت مستقرة", "تراجعت قليلاً"],
    rewardPoints: 55,
    isBreaking: true,
    weights: [0.46, 0.32, 0.16, 0.06],
  },
  {
    publisherEmail: "iqtisad@trendx.app",
    topicSlug: "economy",
    title: "ما القفزة الأبرز التي تعكس التحوّل الاقتصادي في المملكة؟",
    options: [
      "الريادة في البنية التحتية",
      "نمو التدفقات الأجنبية",
      "تراجع خروج رؤوس الأموال",
      "صعود الأداء الاقتصادي العالمي",
    ],
    rewardPoints: 60,
    weights: [0.41, 0.27, 0.14, 0.18],
  },
  {
    publisherEmail: "iqtisad@trendx.app",
    topicSlug: "economy",
    title: "هل تتوقّع ارتفاعاً إضافياً في أسعار العقار خلال 2026؟",
    options: ["ارتفاع قوي", "ارتفاع طفيف", "استقرار", "تراجع طفيف"],
    rewardPoints: 50,
    weights: [0.38, 0.36, 0.18, 0.08],
  },
  {
    publisherEmail: "sports@trendx.app",
    topicSlug: "sports",
    title: "من سيتأهل لنصف نهائي دوري أبطال آسيا 2026؟",
    options: ["الهلال", "النصر", "الاتحاد", "الأهلي"],
    rewardPoints: 50,
    isFeatured: true,
    weights: [0.34, 0.31, 0.21, 0.14],
  },
  {
    publisherEmail: "sports@trendx.app",
    topicSlug: "sports",
    title: "أيّ نجم أجنبي أضاف أكثر للدوري السعودي هذا الموسم؟",
    options: ["كريستيانو رونالدو", "نيمار", "بنزيما", "محرز"],
    rewardPoints: 45,
    weights: [0.42, 0.18, 0.26, 0.14],
  },
  {
    publisherEmail: "official@trendx.app",
    topicSlug: "social",
    title: "ما الأهم في إجازة العيد بنظرك؟",
    options: ["الزيارات العائلية", "السفر", "الأنشطة الترفيهية", "الراحة في المنزل"],
    rewardPoints: 35,
    weights: [0.55, 0.18, 0.16, 0.11],
  },
  {
    publisherEmail: "official@trendx.app",
    topicSlug: "social",
    title: "ما أكثر منصة تستخدمها للحصول على الأخبار؟",
    options: ["تويتر / X", "تيليجرام", "واتساب", "المواقع الإخبارية"],
    rewardPoints: 30,
    weights: [0.46, 0.14, 0.22, 0.18],
  },
  {
    publisherEmail: "official@trendx.app",
    topicSlug: "media",
    title: "هل أصبح المحتوى الرقمي أهم من القنوات التقليدية؟",
    options: ["نعم بفارق كبير", "تقاربت المنصّتان", "التقليدية لا تزال أهم"],
    rewardPoints: 40,
    weights: [0.62, 0.28, 0.10],
  },
  {
    publisherEmail: "official@trendx.app",
    topicSlug: "health",
    title: "هل تثق بقرار طبي يصدره الذكاء الاصطناعي بدون مراجعة بشرية؟",
    options: ["نعم، أثق", "بحذر، أحتاج مراجعة", "لا، لا أثق"],
    rewardPoints: 50,
    weights: [0.18, 0.55, 0.27],
  },
  {
    publisherEmail: "iqtisad@trendx.app",
    topicSlug: "tech",
    title: "هل تتوقّع أن تصبح العملات المشفّرة مقبولة رسمياً في المملكة قريباً؟",
    options: ["نعم خلال سنتين", "نعم لكن بضوابط", "لا أتوقّع ذلك"],
    rewardPoints: 50,
    weights: [0.22, 0.46, 0.32],
  },
];

// --- Surveys (3) -------------------------------------------------------------

const SURVEYS: Array<{
  publisherEmail: string;
  topicSlug: TopicSlug;
  title: string;
  description: string;
  rewardPoints: number;
  questions: Array<{
    title: string;
    options: string[];
    weights: number[];
  }>;
}> = [
  {
    publisherEmail: "official@trendx.app",
    topicSlug: "tech",
    title: "الذكاء الاصطناعي في حياتنا اليومية",
    description: "دراسة شاملة لتأثير AI على المجتمع السعودي",
    rewardPoints: 150,
    questions: [
      {
        title: "كم ساعة يومياً تستخدم أدوات AI؟",
        options: ["أقل من ساعة", "1-3 ساعات", "أكثر من 3 ساعات"],
        weights: [0.36, 0.45, 0.19],
      },
      {
        title: "ما تأثير AI على إنتاجيتك المهنية؟",
        options: ["زاد كثيراً", "تحسّن طفيف", "لم يتغيّر", "أثّر سلباً"],
        weights: [0.44, 0.35, 0.13, 0.08],
      },
      {
        title: "هل تقلق من تأثير AI على سوق العمل؟",
        options: ["قلق شديد", "قلق متوسط", "لست قلقاً", "متفائل جداً"],
        weights: [0.26, 0.37, 0.29, 0.08],
      },
      {
        title: "في أيّ مجال ترى التحوّل الأكبر بفعل AI؟",
        options: ["الصحة والطب", "التعليم", "الأعمال والاقتصاد", "الإعلام"],
        weights: [0.33, 0.30, 0.22, 0.15],
      },
      {
        title: "ما مدى استعدادك للدفع مقابل أدوات AI؟",
        options: ["مستعد إذا كانت قيمة عادلة", "اشتراك مدفوع", "النماذج المجانية فقط", "لست مستعداً"],
        weights: [0.39, 0.24, 0.22, 0.15],
      },
    ],
  },
  {
    publisherEmail: "iqtisad@trendx.app",
    topicSlug: "economy",
    title: "نبض الاقتصاد السعودي 2026",
    description: "قياس ثقة الأفراد في الاقتصاد المحلي وفرص الاستثمار",
    rewardPoints: 130,
    questions: [
      {
        title: "ما توقعك لأداء الاقتصاد السعودي في 2026؟",
        options: ["نمو قوي", "نمو متوسط", "استقرار", "تباطؤ"],
        weights: [0.42, 0.38, 0.14, 0.06],
      },
      {
        title: "أيّ قطاع تتوقّع أن يقود النمو؟",
        options: ["الترفيه والسياحة", "التقنية", "الطاقة المتجدّدة", "الصناعة"],
        weights: [0.31, 0.34, 0.21, 0.14],
      },
      {
        title: "هل تخطّط للاستثمار في أصول جديدة هذا العام؟",
        options: ["نعم بقوّة", "ربما", "لا"],
        weights: [0.34, 0.46, 0.20],
      },
      {
        title: "ما مصدر القلق الاقتصادي الأبرز لديك؟",
        options: ["التضخم", "أسعار العقار", "البطالة", "لا قلق محدّد"],
        weights: [0.37, 0.33, 0.20, 0.10],
      },
    ],
  },
  {
    publisherEmail: "sports@trendx.app",
    topicSlug: "sports",
    title: "مستقبل الرياضة السعودية",
    description: "آراء حول الاستثمارات الرياضية الكبرى وتأثيرها",
    rewardPoints: 120,
    questions: [
      {
        title: "هل غيّرت استقطابات النجوم العالميين تجربتك في متابعة الدوري؟",
        options: ["تغيّرت كثيراً", "تغيّر طفيف", "لم تتغيّر"],
        weights: [0.58, 0.27, 0.15],
      },
      {
        title: "ما أهم رياضة بنظرك بعد كرة القدم؟",
        options: ["كرة السلة", "التنس", "الفورمولا 1", "ألعاب الفنون القتالية"],
        weights: [0.18, 0.16, 0.42, 0.24],
      },
      {
        title: "هل تتوقّع أن تستضيف المملكة نهائيات كأس العالم 2034 بنجاح كبير؟",
        options: ["بنجاح قياسي", "بنجاح جيد", "ستواجه تحديات"],
        weights: [0.62, 0.30, 0.08],
      },
      {
        title: "كم مرّة تحضر مباراة في الملعب؟",
        options: ["شهرياً", "كل 3 أشهر", "نادراً", "لم أحضر"],
        weights: [0.24, 0.31, 0.30, 0.15],
      },
    ],
  },
];

// --- Demographics distribution (Saudi-realistic) -----------------------------

const CITY_WEIGHTS: Array<[string, string, number]> = [
  ["الرياض", "الرياض", 0.34],
  ["جدة", "مكة المكرمة", 0.21],
  ["مكة المكرمة", "مكة المكرمة", 0.07],
  ["المدينة المنورة", "المدينة المنورة", 0.05],
  ["الدمام", "الشرقية", 0.08],
  ["الخبر", "الشرقية", 0.05],
  ["الطائف", "مكة المكرمة", 0.04],
  ["أبها", "عسير", 0.03],
  ["تبوك", "تبوك", 0.03],
  ["بريدة", "القصيم", 0.04],
  ["حائل", "حائل", 0.02],
  ["نجران", "نجران", 0.02],
  ["جازان", "جازان", 0.02],
];

const AGE_BUCKETS: Array<[number, number, number]> = [
  // [minAge, maxAge, weight]
  [18, 24, 0.22],
  [25, 34, 0.41],
  [35, 44, 0.22],
  [45, 54, 0.10],
  [55, 75, 0.05],
];

const GENDER_WEIGHTS: Array<[Gender, number]> = [
  ["male", 0.62],
  ["female", 0.36],
  ["unspecified", 0.02],
];

const DEVICE_WEIGHTS: Array<[DeviceType, number]> = [
  ["ios", 0.58],
  ["android", 0.31],
  ["ipad", 0.06],
  ["web", 0.05],
];

// --- Helpers -----------------------------------------------------------------

function pickWeighted<T>(items: Array<readonly [T, number]>): T {
  const total = items.reduce((acc, [, w]) => acc + w, 0);
  let r = Math.random() * total;
  for (const [value, weight] of items) {
    r -= weight;
    if (r <= 0) return value;
  }
  return items[items.length - 1][0];
}

function pickCity(): { city: string; region: string } {
  const target = Math.random();
  let acc = 0;
  for (const [city, region, weight] of CITY_WEIGHTS) {
    acc += weight;
    if (target <= acc) return { city, region };
  }
  return { city: "الرياض", region: "الرياض" };
}

function pickAgeBucket(): { birthYear: number; ageGroup: string } {
  const target = Math.random();
  let acc = 0;
  for (const [minAge, maxAge, weight] of AGE_BUCKETS) {
    acc += weight;
    if (target <= acc) {
      const age = Math.floor(minAge + Math.random() * (maxAge - minAge));
      const birthYear = new Date().getUTCFullYear() - age;
      const ageGroup =
        age <= 24 ? "18-24" :
        age <= 34 ? "25-34" :
        age <= 44 ? "35-44" :
        age <= 54 ? "45-54" : "55+";
      return { birthYear, ageGroup };
    }
  }
  return { birthYear: 1995, ageGroup: "25-34" };
}

function pickWeightedIndex(weights: number[]): number {
  const total = weights.reduce((acc, w) => acc + w, 0);
  let r = Math.random() * total;
  for (let i = 0; i < weights.length; i += 1) {
    r -= weights[i];
    if (r <= 0) return i;
  }
  return weights.length - 1;
}

function randomInt(min: number, max: number): number {
  return Math.floor(min + Math.random() * (max - min));
}

// --- Main --------------------------------------------------------------------

async function main(): Promise<void> {
  console.log("[seed-demo] starting…");

  // 1) Publishers
  const publisherIdByEmail = new Map<string, string>();
  for (const pub of PUBLISHERS) {
    const salt = makeSalt();
    const passwordHash = await hashPassword("trendx-demo-2026", salt);
    const user = await prisma.user.upsert({
      where: { email: pub.email },
      update: {
        name: pub.name,
        role: pub.role,
        tier: pub.tier,
        city: pub.city,
        region: pub.region,
      },
      create: {
        email: pub.email,
        name: pub.name,
        avatarInitial: pub.avatarInitial,
        passwordHash,
        passwordSalt: salt,
        role: pub.role,
        tier: pub.tier,
        gender: pub.gender,
        birthYear: pub.birthYear,
        city: pub.city,
        region: pub.region,
        country: "SA",
        deviceType: "web",
      },
    });
    publisherIdByEmail.set(pub.email, user.id);
    console.log(`[seed-demo] publisher: ${pub.name} (${user.id.slice(0, 8)})`);
  }

  // 2) Resolve topic IDs (created by base seed)
  const topicBySlug = new Map<TopicSlug, string>();
  const topicRows = await prisma.topic.findMany();
  for (const t of topicRows) {
    if (
      t.slug === "tech" ||
      t.slug === "economy" ||
      t.slug === "sports" ||
      t.slug === "social" ||
      t.slug === "media" ||
      t.slug === "health"
    ) {
      topicBySlug.set(t.slug as TopicSlug, t.id);
    }
  }

  // 3) Polls + options
  const pollsCreated: Array<{
    id: string;
    optionIds: string[];
    title: string;
    weights: number[];
  }> = [];

  for (const draft of POLLS) {
    const publisherId = publisherIdByEmail.get(draft.publisherEmail);
    const topicId = topicBySlug.get(draft.topicSlug);
    if (!publisherId) continue;

    const existing = await prisma.poll.findFirst({
      where: { title: draft.title },
      include: { options: { orderBy: { displayOrder: "asc" } } },
    });

    if (existing) {
      pollsCreated.push({
        id: existing.id,
        optionIds: existing.options.map((o) => o.id),
        title: existing.title,
        weights: draft.weights,
      });
      continue;
    }

    const expiresAt = new Date(Date.now() + 14 * 24 * 60 * 60 * 1000);
    const poll = await prisma.poll.create({
      data: {
        publisherId,
        title: draft.title,
        description: draft.description ?? null,
        authorName: PUBLISHERS.find((p) => p.email === draft.publisherEmail)!.name,
        authorAvatar: PUBLISHERS.find((p) => p.email === draft.publisherEmail)!.avatarInitial,
        authorIsVerified: true,
        topicId,
        topicTags: [draft.topicSlug],
        type: "single_choice",
        rewardPoints: draft.rewardPoints,
        durationDays: 14,
        expiresAt,
        isFeatured: draft.isFeatured ?? false,
        isBreaking: draft.isBreaking ?? false,
        options: {
          create: draft.options.map((text, idx) => ({ text, displayOrder: idx })),
        },
      },
      include: { options: { orderBy: { displayOrder: "asc" } } },
    });
    console.log(`[seed-demo] poll: ${poll.title.slice(0, 40)}…`);
    pollsCreated.push({
      id: poll.id,
      optionIds: poll.options.map((o) => o.id),
      title: poll.title,
      weights: draft.weights,
    });
  }

  // 4) Synthetic respondents (50) — single corpus shared across votes/responses
  const RESPONDENT_COUNT = 50;
  const respondentIds: string[] = [];
  const respondentMeta: Array<{
    id: string;
    gender: Gender;
    city: string;
    region: string;
    birthYear: number;
    ageGroup: string;
    deviceType: DeviceType;
  }> = [];

  for (let i = 0; i < RESPONDENT_COUNT; i += 1) {
    const email = `demo-respondent-${i + 1}@trendx.demo`;
    const gender = pickWeighted(GENDER_WEIGHTS);
    const { city, region } = pickCity();
    const { birthYear, ageGroup } = pickAgeBucket();
    const deviceType = pickWeighted(DEVICE_WEIGHTS);

    const salt = makeSalt();
    const passwordHash = await hashPassword(`demo-${i}`, salt);
    const user = await prisma.user.upsert({
      where: { email },
      update: {
        gender,
        city,
        region,
        birthYear,
        deviceType,
      },
      create: {
        email,
        name: `مستخدم تجريبي ${i + 1}`,
        avatarInitial: "م",
        passwordHash,
        passwordSalt: salt,
        gender,
        city,
        region,
        country: "SA",
        birthYear,
        deviceType,
        role: "respondent",
      },
    });
    respondentIds.push(user.id);
    respondentMeta.push({
      id: user.id,
      gender,
      city,
      region,
      birthYear,
      ageGroup,
      deviceType,
    });
  }
  console.log(`[seed-demo] ${RESPONDENT_COUNT} synthetic respondents ready.`);

  // 5) Votes — sample 30-45 voters per poll
  let totalVotes = 0;
  for (const poll of pollsCreated) {
    const sampleSize = randomInt(30, 46);
    // Random shuffle (Fisher–Yates) to pick distinct respondents per poll.
    const pool = [...respondentMeta];
    for (let i = pool.length - 1; i > 0; i -= 1) {
      const j = Math.floor(Math.random() * (i + 1));
      [pool[i], pool[j]] = [pool[j], pool[i]];
    }
    const voters = pool.slice(0, sampleSize);

    for (const voter of voters) {
      const optionIdx = pickWeightedIndex(poll.weights);
      const optionId = poll.optionIds[optionIdx];
      try {
        await prisma.vote.create({
          data: {
            pollId: poll.id,
            optionId,
            userId: voter.id,
            deviceType: voter.deviceType,
            city: voter.city,
            region: voter.region,
            country: "SA",
            gender: voter.gender,
            ageGroup: voter.ageGroup,
            secondsToVote: randomInt(6, 60),
            votedAt: new Date(Date.now() - randomInt(0, 14 * 24 * 60 * 60) * 1000),
          },
        });
        await prisma.pollOption.update({
          where: { id: optionId },
          data: { votesCount: { increment: 1 } },
        });
        await prisma.poll.update({
          where: { id: poll.id },
          data: { totalVotes: { increment: 1 } },
        });
        totalVotes += 1;
      } catch {
        // Unique (poll, user) constraint hit on re-runs — skip silently.
      }
    }
  }
  console.log(`[seed-demo] ${totalVotes} votes cast across ${pollsCreated.length} polls.`);

  // 6) Surveys + questions
  for (const draft of SURVEYS) {
    const publisherId = publisherIdByEmail.get(draft.publisherEmail);
    const topicId = topicBySlug.get(draft.topicSlug);
    if (!publisherId) continue;

    const existing = await prisma.survey.findFirst({ where: { title: draft.title } });
    if (existing) {
      console.log(`[seed-demo] survey already exists: ${draft.title.slice(0, 30)}…`);
      continue;
    }

    const expiresAt = new Date(Date.now() + 21 * 24 * 60 * 60 * 1000);
    const survey = await prisma.survey.create({
      data: {
        publisherId,
        title: draft.title,
        description: draft.description,
        topicId,
        topicTags: [draft.topicSlug],
        rewardPoints: draft.rewardPoints,
        durationDays: 21,
        expiresAt,
        questions: {
          create: draft.questions.map((q, qIdx) => ({
            title: q.title,
            type: "single_choice",
            displayOrder: qIdx,
            rewardPoints: 25,
            options: {
              create: q.options.map((text, oIdx) => ({ text, displayOrder: oIdx })),
            },
          })),
        },
      },
      include: {
        questions: {
          orderBy: { displayOrder: "asc" },
          include: { options: { orderBy: { displayOrder: "asc" } } },
        },
      },
    });
    console.log(`[seed-demo] survey: ${survey.title.slice(0, 40)}… (${survey.questions.length} qs)`);

    // 7) Survey responses — sample ~25 respondents per survey
    const sampleSize = randomInt(20, 30);
    const pool = [...respondentMeta];
    for (let i = pool.length - 1; i > 0; i -= 1) {
      const j = Math.floor(Math.random() * (i + 1));
      [pool[i], pool[j]] = [pool[j], pool[i]];
    }
    const responders = pool.slice(0, sampleSize);

    let completedCount = 0;
    for (const responder of responders) {
      const isComplete = Math.random() < 0.78; // 78% completion rate baseline
      const startedAt = new Date(Date.now() - randomInt(0, 21 * 24 * 60 * 60) * 1000);
      const completionSeconds = randomInt(150, 320);

      type AnswerSeed = { questionId: string; optionId: string; secondsToAnswer: number };
      const answersData: AnswerSeed[] =
        survey.questions
          .filter(() => isComplete || Math.random() < 0.6)
          .map((q, qIdx): AnswerSeed | null => {
            const draftQuestion = draft.questions[qIdx];
            if (!draftQuestion || !q.options[0]) return null;
            const optionIdx = pickWeightedIndex(draftQuestion.weights);
            const option = q.options[Math.min(optionIdx, q.options.length - 1)];
            return {
              questionId: q.id,
              optionId: option.id,
              secondsToAnswer: randomInt(8, 45),
            };
          })
          .filter((x): x is AnswerSeed => x !== null);

      try {
        await prisma.surveyResponse.create({
          data: {
            surveyId: survey.id,
            userId: responder.id,
            isComplete,
            startedAt,
            completedAt: isComplete ? new Date(startedAt.getTime() + completionSeconds * 1000) : null,
            completionSeconds: isComplete ? completionSeconds : null,
            deviceType: responder.deviceType,
            city: responder.city,
            region: responder.region,
            country: "SA",
            gender: responder.gender,
            ageGroup: responder.ageGroup,
            answers: { create: answersData },
          },
        });

        // Update option vote counts
        for (const ans of answersData) {
          if (ans.optionId) {
            await prisma.surveyQuestionOption.update({
              where: { id: ans.optionId },
              data: { votesCount: { increment: 1 } },
            });
          }
        }

        if (isComplete) completedCount += 1;
      } catch {
        // unique (survey, user) — skip on retry
      }
    }

    await prisma.survey.update({
      where: { id: survey.id },
      data: {
        totalResponses: responders.length,
        totalCompletes: completedCount,
        avgCompletionSeconds: 235,
      },
    });
    console.log(`[seed-demo]   ${responders.length} responses (${completedCount} completed).`);
  }

  console.log("[seed-demo] complete.");
}

main()
  .catch((error) => {
    console.error("[seed-demo] failed:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
