// Mirrors the snake_case JSON shapes returned by the Railway API.
// The dashboard is read-mostly so we only model what we render.

export type User = {
  id: string;
  name: string;
  email: string;
  avatar_initial: string;
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
