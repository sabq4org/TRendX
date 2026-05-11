// Mirrors the snake_case JSON shapes returned by the Railway API.
// The dashboard is read-mostly so we only model what we render.

export type AccountType = "individual" | "organization" | "government";

export type User = {
  id: string;
  name: string;
  email: string;
  handle?: string | null;
  bio?: string | null;
  avatar_initial: string;
  avatar_url?: string | null;
  banner_url?: string | null;
  account_type: AccountType;
  is_verified: boolean;
  points: number;
  coins: number;
  role: "respondent" | "publisher" | "admin";
  tier: "free" | "premium" | "enterprise";
  gender?: "male" | "female" | "other" | "unspecified";
  birth_year?: number | null;
  city?: string | null;
  region?: string | null;
  country?: string;
};

export type AuthResponse = {
  access_token: string;
  refresh_token: string | null;
  user: User;
};

export type Topic = {
  id: string;
  name: string;
  slug: string;
  icon: string;
  color: string;
  followers_count: number;
  posts_count: number;
};

export type PollOption = {
  id: string;
  text: string;
  display_order: number;
  votes_count: number;
  percentage?: number;
};

export type Poll = {
  id: string;
  title: string;
  description: string | null;
  publisher_id: string | null;
  author_name: string;
  author_avatar: string;
  topic_id: string | null;
  topic_name: string | null;
  topic_tags: string[];
  type: string;
  status: "active" | "ended" | "draft";
  total_votes: number;
  total_views: number;
  reward_points: number;
  duration_days: number;
  is_featured: boolean;
  is_breaking: boolean;
  ai_insight: string | null;
  options: PollOption[];
  created_at: string;
  expires_at: string;
};

export type Survey = {
  id: string;
  title: string;
  description: string | null;
  publisher_id: string | null;
  topic_id: string | null;
  topic_name: string | null;
  status: string;
  reward_points: number;
  total_responses: number;
  total_completes: number;
  avg_completion_seconds: number;
  completion_rate: number;
  questions: Array<{
    id: string;
    title: string;
    type: string;
    options: Array<{ id: string; text: string; votes_count: number }>;
  }>;
  created_at: string;
  expires_at: string;
};

export type Bootstrap = {
  topics: Array<Topic & { is_following?: boolean }>;
  polls: Poll[];
  surveys: Survey[];
};

// ----- Analytics shapes -----

export type PollAnalytics = {
  poll_id: string;
  sample_size: number;
  confidence_level: number;
  margin_of_error: number | null;
  representativeness_score: number;
  data_freshness: string;
  methodology_note: string;

  options: Array<{ id: string; text: string; votes_count: number; percentage: number }>;
  consensus: {
    leading_option_id: string | null;
    leading_percentage: number;
    polarization_index: number;
    label: string;
  };
  breakdown: {
    by_gender: Record<string, number>;
    by_age_group: Record<string, number>;
    by_city_top: Record<string, number>;
    by_device: Record<string, number>;
  };
  cross_demographic: Array<{
    option_id: string;
    by_gender: Record<string, number>;
    by_age_group: Record<string, number>;
    by_city_top: Record<string, number>;
  }>;
  behavioral: { avg_decision_seconds: number | null; change_vote_rate_pct: number };
  timeline: {
    daily_cumulative: Array<{ day: string; cumulative_votes: number }>;
    by_hour_of_day: Record<string, number>;
    peak_hour: string | null;
  };
};

export type SurveyAnalytics = {
  survey_id: string;
  sample_size: number;
  completion_rate: number;
  avg_completion_seconds: number | null;
  confidence_level: number;
  margin_of_error: number | null;
  representativeness_score: number;
  data_freshness: string;
  methodology_note: string;
  funnel: { views: number; starts: number; completes: number };
  per_question: Array<{
    question_id: string;
    title: string;
    sample_size: number;
    options: Array<{ id: string; text: string; votes_count: number; percentage: number }>;
    consensus: { leading_pct: number; polarization: number; label: string };
    avg_seconds_to_answer: number | null;
  }>;
  breakdown: PollAnalytics["breakdown"];
  correlations: Array<{
    q1_id: string;
    q1_title: string;
    a1_text: string;
    q2_id: string;
    q2_title: string;
    a2_text: string;
    probability: number;
  }>;
};

export type SurveyAIReport = {
  cached: boolean;
  generated_at: string;
  prompt_version: string;
  model: string;
  report: {
    executive_summary: string;
    key_findings: Array<{ finding: string; supporting_stat: string }>;
    persona_profiles: Array<{
      name: string;
      traits: string[];
      percent: number;
      representative_quote: string;
    }>;
    hidden_patterns: Array<{
      pattern: string;
      probability_pct: number;
      implication: string;
    }>;
    strategic_recommendations: string[];
    sector_position: string;
  };
};

export type SectorAIReport = {
  cached: boolean;
  generated_at: string;
  prompt_version: string;
  model: string;
  polls_count?: number;
  surveys_count?: number;
  total_votes?: number;
  total_responses?: number;
  report: {
    sector_sentiment_score: number;
    sentiment_direction: "rising" | "falling" | "stable";
    consensus_map: Array<{ question: string; leading_pct: number; label: string }>;
    sector_persona: { name: string; description: string; share_pct: number };
    cross_survey_patterns: string[];
    strategic_brief: string;
    predicted_trend: string;
  };
};

// ----- Layer 3 — Deep Analytics -----

export type HeatmapDimension = "gender" | "age_group" | "city" | "device";

export type Heatmap = {
  survey_id: string | null;
  poll_id: string | null;
  question_id: string | null;
  x_dim: HeatmapDimension;
  y_dim: HeatmapDimension;
  x_keys: string[];
  y_keys: string[];
  cells: Array<{ x: string; y: string; count: number; row_pct: number }>;
  total: number;
  computed_at: string;
};

export type CrossQuestion = {
  survey_id: string;
  q1: { id: string; title: string; options: Array<{ id: string; text: string }> };
  q2: { id: string; title: string; options: Array<{ id: string; text: string }> };
  matrix: Array<Array<{
    q1_option_id: string;
    q2_option_id: string;
    count: number;
    conditional_pct: number;
  }>>;
  chi_squared: number;
  degrees_of_freedom: number;
  significance: "very_high" | "high" | "moderate" | "weak";
  sample_size: number;
  computed_at: string;
};

export type SentimentTimeline = {
  topic_id: string;
  topic_name: string;
  days: number;
  series: Array<{
    date: string;
    sentiment: number;
    sample: number;
    polls: number;
    surveys: number;
  }>;
  current_score: number;
  direction: "rising" | "falling" | "stable";
  delta_30d: number;
  computed_at: string;
};

export type SectorBenchmarkRow = {
  topic_id: string;
  topic_name: string;
  topic_slug: string;
  polls_count: number;
  surveys_count: number;
  total_votes: number;
  total_responses: number;
  avg_completion_rate: number;
  followers_count: number;
  sentiment_score: number | null;
  sentiment_direction: "rising" | "falling" | "stable" | null;
};

export type SectorBenchmark = {
  topic_ids: string[];
  rows: SectorBenchmarkRow[];
  leaders: {
    by_engagement: string | null;
    by_completion: string | null;
    by_sentiment: string | null;
    by_followers: string | null;
  };
  computed_at: string;
};

export type SurveyPersonas = {
  survey_id: string;
  k: number;
  sample_size: number;
  cached: boolean;
  generated_at: string;
  prompt_version: string;
  model: string;
  personas: Array<{
    cluster_index: number;
    size: number;
    share_pct: number;
    dominant_gender: string | null;
    dominant_age_group: string | null;
    dominant_city: string | null;
    name: string;
    description: string;
    traits: string[];
    representative_quote: string;
    modal_answers: Array<{ question_id: string; question_title: string; option_text: string }>;
  }>;
};

// ----- Webhooks -----

export type Webhook = {
  id: string;
  publisher_id: string;
  url: string;
  events: string[];
  secret: string;
  is_active: boolean;
  last_fired_at: string | null;
  failure_count: number;
  created_at: string;
};

// ----- Admin -----

export type AdminUser = {
  id: string;
  email: string;
  name: string;
  role: string;
  tier: string;
  city: string | null;
  country: string;
  gender: string;
  device_type: string;
  points: number;
  is_premium: boolean;
  joined_at: string;
  last_active_at: string;
};

export type AuditLogEntry = {
  id: string;
  actor_id: string | null;
  action: string;
  resource_type: string;
  resource_id: string | null;
  ip: string | null;
  user_agent: string | null;
  metadata: Record<string, unknown> | null;
  created_at: string;
};

export type JobsStatus = {
  snapshot: {
    computed_at: string;
    entity_type: string;
    entity_id: string;
  } | null;
  last_ai_insight: {
    generated_at: string;
    insight_type: string;
    model: string;
    latency_ms: number | null;
  } | null;
  webhooks: { total: number; active: number };
  recent_webhook_deliveries: AuditLogEntry[];
  server_time: string;
};

// ----- Daily Pulse + Streak (نبض اليوم) -----

export type DailyPulse = {
  id: string;
  pulse_date: string;
  question: string;
  description: string | null;
  options: Array<{ index: number; text: string; votes: number; percentage: number }>;
  total_responses: number;
  status: string;
  closes_at: string;
  reward_points: number;
  topic_id: string | null;
  ai_summary: string | null;
  user_responded?: boolean;
  user_choice?: number | null;
};

export type PulseHistoryItem = {
  pulse_date: string;
  question: string;
  total_responses: number;
  leading_option_text: string | null;
  leading_pct: number;
};

export type UserStreak = {
  current_streak: number;
  longest_streak: number;
  total_pulses: number;
  freezes_left: number;
  last_pulse_date?: string | null;
  status?: "active_today" | "active_yesterday" | "broken" | "never";
  is_personal_best?: boolean;
  delta?: "+1" | "kept" | "frozen" | "reset";
};

// ----- Opinion DNA -----

export type OpinionDNA = {
  computed_at: string;
  sample_size: number;
  axes: Array<{
    key: string;
    label_high: string;
    label_low: string;
    score: number;
  }>;
  archetype: { title: string; blurb: string };
  share_caption: string;
};

// ----- Audience Marketplace -----

export type AudienceCriteria = {
  gender?: string[];
  age_groups?: string[];
  cities?: string[];
  regions?: string[];
  devices?: string[];
  topic_ids?: string[];
};

export type AudienceEstimate = {
  available_count: number;
  estimated_price_sar: number;
  per_response_price_sar: number;
  median_response_minutes: number;
  representativeness: number;
  breakdown: {
    by_gender: Record<string, number>;
    by_age_group: Record<string, number>;
    by_city: Record<string, number>;
  };
};

export type Audience = {
  id: string;
  name: string;
  criteria: AudienceCriteria;
  available_count: number;
  estimated_price_sar: number;
  status: string;
  poll_id?: string | null;
  survey_id?: string | null;
  created_at: string;
};

// ----- TRENDX Index (public) -----

export type TrendXIndexMetric = {
  slug: string;
  name: string;
  value: number;
  change_24h: number;
  direction: "up" | "down" | "flat";
  sample_size: number;
  blurb: string;
};

export type TrendXIndex = {
  computed_at: string;
  composite: number;
  composite_change_24h: number;
  total_responses: number;
  metrics: TrendXIndexMetric[];
};

// ----- Predictive Accuracy + Weekly Challenge -----

export type UserAccuracy = {
  predictions: number;
  scored: number;
  average_accuracy: number;
  best_accuracy: number;
  rank_percentile: number;
};

export type PredictionLeaderboardItem = {
  user_id: string;
  name: string;
  avatar_initial: string;
  predictions: number;
  average_accuracy: number;
};

export type WeeklyChallenge = {
  id: string;
  week_start: string;
  question: string;
  description: string | null;
  metric_label: string;
  closes_at: string;
  status: string;
  target_pct: number | null;
  reward_points: number;
  total_predictions: number;
  my_prediction: { predicted_pct: number; distance: number | null; rank: number | null } | null;
};

// ----- Comments (الحوار) -----

export type Comment = {
  id: string;
  body: string;
  score: number;
  upvotes: number;
  downvotes: number;
  created_at: string;
  author_vote_option_id: string | null;
  user: { id: string; name: string; avatar_initial: string };
};
