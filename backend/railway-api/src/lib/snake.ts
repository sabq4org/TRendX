/**
 * Recursively renames object keys from camelCase to snake_case.
 * Decimals and Dates are preserved as-is (Prisma returns Decimal objects;
 * JSON.stringify serializes them via their .toString()).
 */
export function snake<T = unknown>(value: T): T {
  if (Array.isArray(value)) {
    return value.map(snake) as unknown as T;
  }
  if (value && typeof value === "object" && value.constructor === Object) {
    const result: Record<string, unknown> = {};
    for (const [key, v] of Object.entries(value as Record<string, unknown>)) {
      result[toSnake(key)] = snake(v);
    }
    return result as unknown as T;
  }
  return value;
}

function toSnake(input: string): string {
  return input.replace(/[A-Z]/g, (match) => `_${match.toLowerCase()}`);
}
