import { PrismaClient } from "@prisma/client";
import { hashPassword, makeSalt } from "./auth.js";

const prisma = new PrismaClient();

const TOPICS = [
  { name: "اجتماعية", slug: "social",   icon: "person.3.fill",             color: "blue",   followersCount: 45,  postsCount: 16 },
  { name: "إعلام",    slug: "media",    icon: "newspaper.fill",            color: "purple", followersCount: 84,  postsCount: 10 },
  { name: "اقتصاد",   slug: "economy",  icon: "chart.line.uptrend.xyaxis", color: "green",  followersCount: 120, postsCount: 25 },
  { name: "رياضة",    slug: "sports",   icon: "sportscourt.fill",          color: "orange", followersCount: 200, postsCount: 42 },
  { name: "تقنية",    slug: "tech",     icon: "cpu.fill",                  color: "blue",   followersCount: 156, postsCount: 33 },
  { name: "صحة",      slug: "health",   icon: "heart.fill",                color: "red",    followersCount: 89,  postsCount: 18 },
];

const GIFTS = [
  { name: "قسيمة قهوة", brandName: "Dose Cafe",     category: "مقاهي",   pointsRequired: 120, valueInRiyal: 20, isAvailable: true },
  { name: "بطاقة تسوق", brandName: "TRENDX Market", category: "تسوق",    pointsRequired: 240, valueInRiyal: 50, isAvailable: true },
  { name: "حلوى فاخرة", brandName: "Sweet Box",     category: "حلويات",  pointsRequired: 180, valueInRiyal: 35, isAvailable: true },
];

async function main(): Promise<void> {
  console.log("[seed] upserting topics…");
  for (const topic of TOPICS) {
    await prisma.topic.upsert({
      where: { name: topic.name },
      create: topic,
      update: {
        slug: topic.slug,
        icon: topic.icon,
        color: topic.color,
      },
    });
  }

  console.log("[seed] upserting gifts…");
  for (const gift of GIFTS) {
    await prisma.gift.upsert({
      where: { name_brandName: { name: gift.name, brandName: gift.brandName } },
      create: gift,
      update: {
        category: gift.category,
        pointsRequired: gift.pointsRequired,
        valueInRiyal: gift.valueInRiyal,
        isAvailable: gift.isAvailable,
      },
    });
  }

  // Government showcase account: وزارة الإعلام (Ministry of Media).
  // Acts as the live demo of the government profile layout — formal
  // green frame, Islamic-pattern banner, official badge, sample bio.
  // Password is rotated by Mizan post-launch; the seed keeps the
  // account fresh on every deploy without overwriting the password.
  console.log("[seed] upserting government showcase account…");
  const moiaEmail = "moia@trendx.sa";
  // Public, stable URL for the Saudi national emblem (palm + crossed
  // swords) from Wikipedia Commons. Used as the avatar for وزارة
  // الإعلام so the profile carries the real institutional mark
  // instead of the SwiftUI programmatic fallback.
  const saudiEmblemURL = "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0d/Emblem_of_Saudi_Arabia.svg/512px-Emblem_of_Saudi_Arabia.svg.png";
  const existingMoia = await prisma.user.findUnique({ where: { email: moiaEmail } });
  if (!existingMoia) {
    const salt = makeSalt();
    const passwordHash = await hashPassword("ChangeMe-TRENDX-Beta!", salt);
    await prisma.user.create({
      data: {
        email: moiaEmail,
        passwordHash,
        passwordSalt: salt,
        name: "وزارة الإعلام",
        avatarInitial: "وم",
        avatarUrl: saudiEmblemURL,
        handle: "moia",
        bio: "الحساب الرسمي لوزارة الإعلام في المملكة العربية السعودية — صوت رسمي على نبض الرأي.",
        accountType: "government",
        isVerified: true,
        role: "publisher",
        tier: "enterprise",
        country: "SA",
        city: "الرياض",
      },
    });
  } else {
    await prisma.user.update({
      where: { email: moiaEmail },
      data: {
        name: "وزارة الإعلام",
        handle: "moia",
        avatarUrl: saudiEmblemURL,
        bio: "الحساب الرسمي لوزارة الإعلام في المملكة العربية السعودية — صوت رسمي على نبض الرأي.",
        accountType: "government",
        isVerified: true,
        role: "publisher",
        tier: "enterprise",
      },
    });
  }

  // ---------------------------------------------------------------
  // Sample content from وزارة الإعلام so the timeline / radar shows
  // real activity from the moment a user signs up and follows the
  // ministry. Idempotent — each item is keyed by a stable title so
  // re-running the seed doesn't create duplicates.
  // ---------------------------------------------------------------
  const moia = await prisma.user.findUnique({ where: { email: moiaEmail } });
  const mediaTopic = await prisma.topic.findUnique({ where: { name: "إعلام" } });
  if (moia && mediaTopic) {
    console.log("[seed] upserting وزارة الإعلام sample content…");

    type SamplePoll = {
      title: string;
      description: string;
      voterAudience: "public" | "verified" | "verified_citizen";
      rewardPoints: number;
      options: string[];
    };

    const samplePolls: SamplePoll[] = [
      {
        title: "ما أكثر منصة إعلامية تستخدمها يومياً؟",
        description: "نقيس عادات الجمهور السعودي مع المحتوى الإعلامي الرقمي.",
        voterAudience: "public",
        rewardPoints: 30,
        options: ["X (تويتر)", "Snapchat", "YouTube", "TikTok", "أخرى"],
      },
      {
        title: "ما رأيك بمستوى الإنتاج الإعلامي السعودي خلال 2026؟",
        description: "استطلاع للحسابات الموثّقة فقط — صوت الخبراء والإعلاميين.",
        voterAudience: "verified",
        rewardPoints: 45,
        options: ["تطوّر ملحوظ", "تحسّن نسبي", "ثابت", "يحتاج جهداً أكبر"],
      },
      {
        title: "هل تفضّل قراءة الأخبار من المصادر الرسمية مباشرة؟",
        description: "استطلاع وطني — يحتاج حساباً موثّقاً ببيانات كاملة (مدينة، عمر، جنس).",
        voterAudience: "verified_citizen",
        rewardPoints: 60,
        options: ["نعم دائماً", "أحياناً", "نادراً", "لا أعتمد عليها"],
      },
    ];

    for (const sp of samplePolls) {
      const existing = await prisma.poll.findFirst({
        where: { publisherId: moia.id, title: sp.title },
      });
      if (existing) continue;
      await prisma.poll.create({
        data: {
          publisherId: moia.id,
          title: sp.title,
          description: sp.description,
          authorName: moia.name,
          authorAvatar: moia.avatarInitial,
          authorIsVerified: true,
          topicId: mediaTopic.id,
          type: "single_choice",
          status: "active",
          voterAudience: sp.voterAudience,
          rewardPoints: sp.rewardPoints,
          durationDays: 14,
          expiresAt: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
          options: {
            create: sp.options.map((text, idx) => ({ text, displayOrder: idx })),
          },
        },
      });
    }

    // Survey: "تجربة المواطن مع الإعلام الرقمي"
    const surveyTitle = "تجربة المواطن مع الإعلام الرقمي";
    const surveyExisting = await prisma.survey.findFirst({
      where: { publisherId: moia.id, title: surveyTitle },
    });
    if (!surveyExisting) {
      await prisma.survey.create({
        data: {
          publisherId: moia.id,
          title: surveyTitle,
          description: "5 أسئلة تساعدنا على فهم تجربتك مع الإعلام السعودي وتطويره معاً.",
          topicId: mediaTopic.id,
          status: "active",
          rewardPoints: 120,
          durationDays: 30,
          expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
          questions: {
            create: [
              {
                title: "كم ساعة تستهلك المحتوى الإعلامي يومياً؟",
                type: "single_choice",
                displayOrder: 0,
                rewardPoints: 20,
                options: {
                  create: [
                    { text: "أقل من ساعة", displayOrder: 0 },
                    { text: "1-3 ساعات", displayOrder: 1 },
                    { text: "3-5 ساعات", displayOrder: 2 },
                    { text: "أكثر من 5 ساعات", displayOrder: 3 },
                  ],
                },
              },
              {
                title: "ما المصدر الذي تثق به أكثر؟",
                type: "single_choice",
                displayOrder: 1,
                rewardPoints: 25,
                options: {
                  create: [
                    { text: "وكالة الأنباء السعودية (واس)", displayOrder: 0 },
                    { text: "الصحف الرسمية", displayOrder: 1 },
                    { text: "القنوات الرسمية", displayOrder: 2 },
                    { text: "حسابات الجهات على X", displayOrder: 3 },
                  ],
                },
              },
              {
                title: "هل ترى أن المحتوى الإعلامي السعودي يعكس هويّتنا؟",
                type: "single_choice",
                displayOrder: 2,
                rewardPoints: 25,
                options: {
                  create: [
                    { text: "نعم بقوة", displayOrder: 0 },
                    { text: "إلى حدّ ما", displayOrder: 1 },
                    { text: "ضعيف", displayOrder: 2 },
                  ],
                },
              },
              {
                title: "ما القطاع الذي تتمنّى تغطية إعلامية أكثر له؟",
                type: "single_choice",
                displayOrder: 3,
                rewardPoints: 25,
                options: {
                  create: [
                    { text: "الثقافة والفنون", displayOrder: 0 },
                    { text: "الرياضة المحلية", displayOrder: 1 },
                    { text: "الاقتصاد والاستثمار", displayOrder: 2 },
                    { text: "الشباب وريادة الأعمال", displayOrder: 3 },
                  ],
                },
              },
              {
                title: "هل تشارك المحتوى الذي تجده مفيداً؟",
                type: "single_choice",
                displayOrder: 4,
                rewardPoints: 25,
                options: {
                  create: [
                    { text: "دائماً", displayOrder: 0 },
                    { text: "أحياناً", displayOrder: 1 },
                    { text: "نادراً", displayOrder: 2 },
                  ],
                },
              },
            ],
          },
        },
      });
    }

    // Event: ملتقى الإعلام السعودي 2026
    const eventTitle = "ملتقى الإعلام السعودي 2026";
    const eventExisting = await prisma.event.findFirst({
      where: { publisherId: moia.id, title: eventTitle },
    });
    if (!eventExisting) {
      await prisma.event.create({
        data: {
          publisherId: moia.id,
          title: eventTitle,
          description: "ملتقى يجمع نخبة من الإعلاميين والمختصين لمناقشة مستقبل القطاع. شارك حضورك واترك بصمتك على خريطة الحضور.",
          category: "cultural",
          status: "upcoming",
          startsAt: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000),
          endsAt: new Date(Date.now() + 12 * 24 * 60 * 60 * 1000),
          city: "الرياض",
          venue: "مركز الملك فهد الثقافي",
          lat: 24.7136,
          lng: 46.6753,
        },
      });
    }

    // Story: الإعلام في رؤية 2030
    const storyTitle = "الإعلام في رؤية 2030";
    const storyExisting = await prisma.story.findFirst({
      where: { publisherId: moia.id, title: storyTitle },
    });
    if (!storyExisting) {
      await prisma.story.create({
        data: {
          publisherId: moia.id,
          title: storyTitle,
          description: "سلسلة استطلاعات نتابع فيها رأي الجمهور حول تحوّلات الإعلام في رؤية المملكة 2030.",
          coverStyle: "media",
          isFeatured: true,
          isPinned: true,
          status: "active",
          startsAt: new Date(),
          endsAt: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000),
        },
      });
    }
  }

  const [topicCount, giftCount, govCount, moiaPolls] = await Promise.all([
    prisma.topic.count(),
    prisma.gift.count(),
    prisma.user.count({ where: { accountType: "government" } }),
    moia ? prisma.poll.count({ where: { publisherId: moia.id } }) : 0,
  ]);
  console.log(`[seed] done. topics=${topicCount} gifts=${giftCount} gov=${govCount} moia_polls=${moiaPolls}`);
}

main()
  .catch((error) => {
    console.error("[seed] failed:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
