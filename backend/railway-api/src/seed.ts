import { PrismaClient } from "@prisma/client";

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

  const [topicCount, giftCount] = await Promise.all([
    prisma.topic.count(),
    prisma.gift.count(),
  ]);
  console.log(`[seed] done. topics=${topicCount} gifts=${giftCount}`);
}

main()
  .catch((error) => {
    console.error("[seed] failed:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
