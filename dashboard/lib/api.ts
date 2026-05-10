import type {
  AdminUser,
  Audience,
  AudienceCriteria,
  AudienceEstimate,
  AuditLogEntry,
  AuthResponse,
  Bootstrap,
  Comment,
  CrossQuestion,
  DailyPulse,
  Heatmap,
  HeatmapDimension,
  JobsStatus,
  OpinionDNA,
  Poll,
  PollAnalytics,
  PredictionLeaderboardItem,
  PulseHistoryItem,
  SectorAIReport,
  SectorBenchmark,
  SentimentTimeline,
  Survey,
  SurveyAIReport,
  SurveyAnalytics,
  SurveyPersonas,
  Topic,
  TrendXIndex,
  User,
  UserAccuracy,
  UserStreak,
  Webhook,
  WeeklyChallenge,
} from "./types";

const API_BASE =
  process.env.NEXT_PUBLIC_TRENDX_API ?? "https://trendx-production.up.railway.app";

async function request<T>(
  path: string,
  options: {
    method?: "GET" | "POST" | "PATCH" | "DELETE";
    body?: unknown;
    token?: string | null;
  } = {},
): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    method: options.method ?? "GET",
    headers: {
      "Content-Type": "application/json",
      ...(options.token ? { Authorization: `Bearer ${options.token}` } : {}),
    },
    body: options.body ? JSON.stringify(options.body) : undefined,
    cache: "no-store",
  });
  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`${res.status}: ${text || res.statusText}`);
  }
  return res.json() as Promise<T>;
}

export const api = {
  base: API_BASE,

  signIn(email: string, password: string): Promise<AuthResponse> {
    return request("/auth/signin", { method: "POST", body: { email, password } });
  },

  profile(token: string): Promise<User> {
    return request("/profile", { token });
  },

  bootstrap(token: string): Promise<Bootstrap> {
    return request("/bootstrap", { token });
  },

  topics(token: string): Promise<Array<Topic & { is_following?: boolean }>> {
    return request("/topics", { token });
  },

  createPoll(
    token: string,
    body: {
      poll: {
        title: string;
        description?: string;
        cover_style?: string;
        topic_id?: string;
        type?: "single_choice" | "multiple_choice" | "rating" | "linear_scale";
        reward_points?: number;
        duration_days?: number;
      };
      options: Array<{ text: string }>;
    },
  ): Promise<{ poll: Poll }> {
    return request("/polls/create", { method: "POST", body, token });
  },

  createSurvey(
    token: string,
    body: {
      survey: {
        title: string;
        description?: string;
        cover_style?: string;
        topic_id?: string;
        reward_points?: number;
        duration_days?: number;
      };
      questions: Array<{
        title: string;
        type?: "single_choice" | "multiple_choice" | "rating" | "linear_scale";
        reward_points?: number;
        options: Array<{ text: string }>;
      }>;
    },
  ): Promise<{ survey: Survey }> {
    return request("/surveys/create", { method: "POST", body, token });
  },

  pollAnalytics(token: string, pollId: string): Promise<PollAnalytics> {
    return request(`/analytics/poll/${pollId}`, { token });
  },

  surveyAnalytics(token: string, surveyId: string): Promise<SurveyAnalytics> {
    return request(`/analytics/survey/${surveyId}`, { token });
  },

  surveyAIReport(token: string, surveyId: string): Promise<SurveyAIReport> {
    return request(`/surveys/${surveyId}/analytics/ai-report`, { token });
  },

  topicInsight(token: string, topicId: string): Promise<SectorAIReport> {
    return request(`/topics/${topicId}/insight`, { token });
  },

  surveyDetail(token: string, id: string): Promise<Survey> {
    return request(`/surveys/${id}`, { token });
  },

  // ----- Layer 3 -----

  pollHeatmap(
    token: string,
    pollId: string,
    x: HeatmapDimension,
    y: HeatmapDimension,
    optionId?: string,
  ): Promise<Heatmap> {
    const qs = new URLSearchParams({ x, y, ...(optionId ? { option_id: optionId } : {}) });
    return request(`/analytics/poll/${pollId}/heatmap?${qs}`, { token });
  },

  surveyHeatmap(
    token: string,
    surveyId: string,
    x: HeatmapDimension,
    y: HeatmapDimension,
    questionId?: string,
    optionId?: string,
  ): Promise<Heatmap> {
    const qs = new URLSearchParams({
      x, y,
      ...(questionId ? { question_id: questionId } : {}),
      ...(optionId ? { option_id: optionId } : {}),
    });
    return request(`/analytics/survey/${surveyId}/heatmap?${qs}`, { token });
  },

  surveyCrossQuestion(
    token: string,
    surveyId: string,
    q1: string,
    q2: string,
  ): Promise<CrossQuestion> {
    const qs = new URLSearchParams({ q1, q2 });
    return request(`/analytics/survey/${surveyId}/cross-question?${qs}`, { token });
  },

  topicSentimentTimeline(
    token: string,
    topicId: string,
    days = 30,
  ): Promise<SentimentTimeline> {
    return request(`/analytics/topic/${topicId}/sentiment-timeline?days=${days}`, { token });
  },

  sectorBenchmark(token: string, topicIds: string[]): Promise<SectorBenchmark> {
    const qs = new URLSearchParams({ topic_ids: topicIds.join(",") });
    return request(`/analytics/sectors/benchmark?${qs}`, { token });
  },

  surveyPersonas(token: string, surveyId: string, refresh = false): Promise<SurveyPersonas> {
    return request(
      `/surveys/${surveyId}/personas${refresh ? "?refresh=1" : ""}`,
      { token },
    );
  },

  // ----- Webhooks (publisher) -----

  listWebhooks(token: string): Promise<Webhook[]> {
    return request("/publisher/webhooks", { token });
  },
  createWebhook(token: string, body: { url: string; events: string[] }): Promise<Webhook> {
    return request("/publisher/webhooks", { method: "POST", body, token });
  },
  updateWebhook(
    token: string,
    id: string,
    body: { url?: string; events?: string[]; is_active?: boolean },
  ): Promise<Webhook> {
    return request(`/publisher/webhooks/${id}`, { method: "PATCH", body, token });
  },
  deleteWebhook(token: string, id: string): Promise<{ ok: boolean }> {
    return request(`/publisher/webhooks/${id}`, { method: "DELETE", token });
  },
  testWebhook(token: string, id: string): Promise<{ ok: boolean; status: number; response: string }> {
    return request(`/publisher/webhooks/${id}/test`, { method: "POST", token });
  },

  // ----- Admin -----

  adminListUsers(
    token: string,
    options: { q?: string; role?: string; tier?: string; limit?: number } = {},
  ): Promise<AdminUser[]> {
    const qs = new URLSearchParams();
    if (options.q) qs.set("q", options.q);
    if (options.role) qs.set("role", options.role);
    if (options.tier) qs.set("tier", options.tier);
    if (options.limit) qs.set("limit", String(options.limit));
    return request(`/admin/users?${qs}`, { token });
  },
  adminUpdateUser(
    token: string,
    id: string,
    body: { role?: string; tier?: string; is_premium?: boolean },
  ): Promise<User> {
    return request(`/admin/users/${id}`, { method: "PATCH", body, token });
  },
  adminAuditLog(token: string, limit = 100): Promise<AuditLogEntry[]> {
    return request(`/admin/audit-log?limit=${limit}`, { token });
  },
  adminJobsStatus(token: string): Promise<JobsStatus> {
    return request("/admin/jobs/status", { token });
  },
  adminRunSnapshots(token: string): Promise<{ ok: boolean; ranAt: string }> {
    return request("/admin/snapshots/run", { method: "POST", token });
  },

  // ----- Daily Pulse + Streak -----

  pulseToday(token: string): Promise<DailyPulse> {
    return request("/pulse/today", { token });
  },
  /**
   * Public, view-only shape — same as `pulseToday` but without
   * `user_responded` / `user_choice`. Used by the dashboard, where
   * publishers and admins should never accidentally cast a vote.
   */
  pulseTodayAnon(_token?: string): Promise<DailyPulse> {
    return request("/pulse/today/anon");
  },
  pulseRespond(
    token: string,
    body: { option_index: number; predicted_pct?: number },
  ): Promise<{
    pulse: DailyPulse;
    reward: number;
    streak: UserStreak;
    prediction_score: number | null;
  }> {
    return request("/pulse/today/respond", { method: "POST", body, token });
  },
  pulseYesterday(token: string): Promise<{ pulse: DailyPulse | null }> {
    return request("/pulse/yesterday", { token });
  },
  pulseHistory(token: string, days = 14): Promise<{ items: PulseHistoryItem[] }> {
    return request(`/pulse/history?days=${days}`, { token });
  },
  myStreak(token: string): Promise<UserStreak> {
    return request("/me/streak", { token });
  },

  // ----- Opinion DNA -----

  myDNA(token: string): Promise<OpinionDNA> {
    return request("/me/dna", { token });
  },
  refreshDNA(token: string): Promise<OpinionDNA> {
    return request("/me/dna/refresh", { method: "POST", token });
  },

  // ----- Audience Marketplace -----

  estimateAudience(token: string, criteria: AudienceCriteria): Promise<AudienceEstimate> {
    return request("/publisher/audiences/estimate", { method: "POST", body: { criteria }, token });
  },
  listAudiences(token: string): Promise<{ items: Audience[] }> {
    return request("/publisher/audiences", { token });
  },
  createAudienceApi(
    token: string,
    body: { name: string; criteria: AudienceCriteria },
  ): Promise<Audience> {
    return request("/publisher/audiences", { method: "POST", body, token });
  },

  // ----- TRENDX Index (public) -----

  trendxIndex(): Promise<TrendXIndex> {
    return request("/public/index");
  },

  // ----- Predictions -----

  predictPoll(token: string, pollId: string, predictedPct: number): Promise<{ ok: true }> {
    return request(`/polls/${pollId}/predict`, {
      method: "POST",
      body: { predicted_pct: predictedPct },
      token,
    });
  },
  myAccuracy(token: string): Promise<UserAccuracy> {
    return request("/me/accuracy", { token });
  },
  accuracyLeaderboard(token: string, limit = 25): Promise<{ items: PredictionLeaderboardItem[] }> {
    return request(`/accuracy/leaderboard?limit=${limit}`, { token });
  },

  // ----- Weekly Challenge -----

  thisWeekChallenge(token: string): Promise<WeeklyChallenge> {
    return request("/challenges/this-week", { token });
  },
  predictChallenge(token: string, id: string, predictedPct: number): Promise<{ ok: true; id: string }> {
    return request(`/challenges/${id}/predict`, {
      method: "POST",
      body: { predicted_pct: predictedPct },
      token,
    });
  },
  settleChallenge(token: string, id: string, actualPct: number): Promise<{ winners: number }> {
    return request(`/admin/challenges/${id}/settle`, {
      method: "POST",
      body: { actual_pct: actualPct },
      token,
    });
  },

  // ----- Comments (الحوار) -----

  pollComments(token: string, pollId: string, sort: "top" | "new" = "top"): Promise<{ items: Comment[] }> {
    return request(`/polls/${pollId}/comments?sort=${sort}`, { token });
  },
  postComment(token: string, pollId: string, body: string): Promise<{ id: string }> {
    return request(`/polls/${pollId}/comments`, { method: "POST", body: { body }, token });
  },
  voteComment(token: string, id: string, value: 1 | -1): Promise<{ score: number; upvotes: number; downvotes: number }> {
    return request(`/comments/${id}/vote`, { method: "POST", body: { value }, token });
  },
};
