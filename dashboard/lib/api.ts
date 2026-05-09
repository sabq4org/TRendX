import type {
  AuthResponse,
  Bootstrap,
  PollAnalytics,
  SectorAIReport,
  Survey,
  SurveyAIReport,
  SurveyAnalytics,
  Topic,
  User,
} from "./types";

const API_BASE =
  process.env.NEXT_PUBLIC_TRENDX_API ?? "https://trendx-production.up.railway.app";

async function request<T>(
  path: string,
  options: { method?: "GET" | "POST"; body?: unknown; token?: string | null } = {},
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
};
