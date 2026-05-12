import type {
  Gift,
  Poll,
  PollOption,
  Redemption,
  Survey,
  SurveyQuestion,
  SurveyQuestionOption,
  Topic,
  User,
  Vote,
} from "@prisma/client";

// MARK: - User

export function userDTO(u: User, options: { viewerFollows?: boolean } = {}) {
  return {
    id: u.id,
    name: u.name,
    email: u.email,
    handle: u.handle,
    bio: u.bio,
    avatar_initial: u.avatarInitial,
    avatar_url: u.avatarUrl,
    banner_url: u.bannerUrl,
    phone: u.phone,
    account_type: u.accountType,
    is_verified: u.isVerified,
    role: u.role,
    tier: u.tier,
    gender: u.gender,
    birth_year: u.birthYear,
    city: u.city,
    region: u.region,
    country: u.country,
    device_type: u.deviceType,
    os_version: u.osVersion,
    points: u.points,
    coins: Number(u.coins),
    is_premium: u.isPremium,
    followed_topics: u.followedTopics,
    completed_polls: u.completedPolls,
    followers_count: u.followersCount,
    following_count: u.followingCount,
    viewer_follows: options.viewerFollows ?? false,
    joined_at: u.joinedAt.toISOString(),
    last_active_at: u.lastActiveAt.toISOString(),
    updated_at: u.updatedAt.toISOString(),
  };
}

// MARK: - Topic

export function topicDTO(t: Topic) {
  return {
    id: t.id,
    name: t.name,
    slug: t.slug,
    icon: t.icon,
    color: t.color,
    parent_id: t.parentId,
    followers_count: t.followersCount,
    posts_count: t.postsCount,
    created_at: t.createdAt.toISOString(),
  };
}

// MARK: - Poll

type PollWithRelations = Poll & {
  options?: PollOption[];
  votes?: Pick<Vote, "userId" | "optionId">[];
  topic?: Topic | null;
  publisher?:
    | Pick<User, "accountType" | "isVerified" | "handle" | "avatarUrl" | "bannerUrl">
    | null;
};

export function pollDTO(
  p: PollWithRelations,
  options: { userId?: string | null } = {},
) {
  const userVote = options.userId
    ? p.votes?.find((v) => v.userId === options.userId)
    : null;

  const total = p.totalVotes;
  const optionsOut = (p.options ?? []).map((opt) => ({
    id: opt.id,
    text: opt.text,
    display_order: opt.displayOrder,
    votes_count: opt.votesCount,
    percentage: total > 0 ? (opt.votesCount / total) * 100 : 0,
  }));

  return {
    id: p.id,
    title: p.title,
    description: p.description,
    image_url: p.imageUrl,
    cover_style: p.coverStyle,
    publisher_id: p.publisherId,
    author_name: p.authorName,
    author_avatar: p.authorAvatar,
    author_is_verified: p.authorIsVerified,
    author_account_type: p.publisher?.accountType ?? null,
    author_handle: p.publisher?.handle ?? null,
    // Publisher's current avatar/banner URLs so a poll card on the
    // home feed picks up the Ministry of Media's freshly-uploaded
    // logo without needing the poll itself to be re-published.
    author_avatar_url: p.publisher?.avatarUrl ?? null,
    author_banner_url: p.publisher?.bannerUrl ?? null,
    topic_id: p.topicId,
    topic_name: p.topic?.name ?? null,
    topic_tags: p.topicTags,
    type: p.type,
    status: p.status,
    total_votes: p.totalVotes,
    total_views: p.totalViews,
    total_shares: p.totalShares,
    total_saves: p.totalSaves,
    reward_points: p.rewardPoints,
    duration_days: p.durationDays,
    voter_audience: p.voterAudience,
    is_featured: p.isFeatured,
    is_breaking: p.isBreaking,
    ai_insight: p.aiInsight,
    user_voted_option_id: userVote?.optionId ?? null,
    is_bookmarked: false,
    shares_count: p.totalShares,
    reposts_count: 0,
    options: optionsOut,
    created_at: p.createdAt.toISOString(),
    expires_at: p.expiresAt.toISOString(),
  };
}

// MARK: - Survey

type SurveyWithRelations = Survey & {
  questions?: (SurveyQuestion & {
    options?: SurveyQuestionOption[];
  })[];
  topic?: Topic | null;
  publisher?: Pick<User, "accountType" | "isVerified" | "handle" | "name"> | null;
};

export function surveyDTO(s: SurveyWithRelations) {
  return {
    id: s.id,
    title: s.title,
    description: s.description,
    image_url: s.imageUrl,
    cover_style: s.coverStyle,
    publisher_id: s.publisherId,
    author_account_type: s.publisher?.accountType ?? null,
    author_is_verified: s.publisher?.isVerified ?? false,
    author_handle: s.publisher?.handle ?? null,
    author_name: s.publisher?.name ?? null,
    topic_id: s.topicId,
    topic_name: s.topic?.name ?? null,
    topic_tags: s.topicTags,
    status: s.status,
    reward_points: s.rewardPoints,
    duration_days: s.durationDays,
    total_responses: s.totalResponses,
    total_completes: s.totalCompletes,
    avg_completion_seconds: s.avgCompletionSeconds,
    completion_rate: s.totalResponses > 0
      ? Math.round((s.totalCompletes / s.totalResponses) * 100)
      : 0,
    questions: (s.questions ?? []).map((q) => ({
      id: q.id,
      survey_id: q.surveyId,
      title: q.title,
      description: q.description,
      type: q.type,
      display_order: q.displayOrder,
      reward_points: q.rewardPoints,
      is_required: q.isRequired,
      options: (q.options ?? []).map((o) => ({
        id: o.id,
        text: o.text,
        display_order: o.displayOrder,
        votes_count: o.votesCount,
      })),
    })),
    created_at: s.createdAt.toISOString(),
    expires_at: s.expiresAt.toISOString(),
  };
}

// MARK: - Gift

export function giftDTO(g: Gift) {
  return {
    id: g.id,
    name: g.name,
    brand_name: g.brandName,
    brand_logo: g.brandLogo,
    category: g.category,
    points_required: g.pointsRequired,
    value_in_riyal: Number(g.valueInRiyal),
    image_url: g.imageUrl,
    is_redeem_at_store: g.isRedeemAtStore,
    is_available: g.isAvailable,
    inventory_count: g.inventoryCount,
    created_at: g.createdAt.toISOString(),
  };
}

// MARK: - Redemption

export function redemptionDTO(r: Redemption) {
  return {
    id: r.id,
    user_id: r.userId,
    gift_id: r.giftId,
    gift_name: r.giftName,
    brand_name: r.brandName,
    points_spent: r.pointsSpent,
    value_in_riyal: Number(r.valueInRiyal),
    code: r.code,
    redeemed_at: r.redeemedAt.toISOString(),
  };
}
