/**
 * Thin wrapper around OpenAI's /v1/responses endpoint.
 * Always falls back to the provided default if the call fails so a missing
 * key or transient outage never breaks user-facing flows.
 */

export type AIResult<T extends Record<string, unknown>> = T & {
  latencyMs?: number;
  modelUsed?: string;
  promptVersion?: string;
};

export async function aiJSON<T extends Record<string, unknown>>(
  options: {
    system: string;
    input: unknown;
    fallback: T;
    promptVersion: string;
  },
): Promise<AIResult<T>> {
  const apiKey = process.env.OPENAI_API_KEY;
  const model = process.env.OPENAI_MODEL ?? "gpt-4o-mini";

  if (!apiKey) {
    return { ...options.fallback, modelUsed: "fallback", promptVersion: options.promptVersion };
  }

  const started = Date.now();
  try {
    const response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        input: [
          { role: "system", content: options.system },
          { role: "user", content: JSON.stringify(options.input) },
        ],
      }),
    });

    if (!response.ok) {
      console.warn(`[ai] non-200 response: ${response.status}`);
      return { ...options.fallback, modelUsed: "fallback", promptVersion: options.promptVersion };
    }

    const payload = (await response.json()) as { output_text?: string };
    const parsed = JSON.parse(payload.output_text ?? "{}") as T;
    return {
      ...parsed,
      latencyMs: Date.now() - started,
      modelUsed: model,
      promptVersion: options.promptVersion,
    };
  } catch (error) {
    console.warn("[ai] request failed:", error);
    return { ...options.fallback, modelUsed: "fallback", promptVersion: options.promptVersion };
  }
}
