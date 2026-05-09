import { createHmac, randomBytes, scrypt as scryptCb, timingSafeEqual } from "node:crypto";
import { promisify } from "node:util";

const scrypt = promisify(scryptCb) as (
  password: string,
  salt: string,
  keylen: number,
) => Promise<Buffer>;

const KEY_LENGTH = 32;
const TOKEN_TTL_SECONDS = 60 * 60 * 24 * 30;

function base64url(buffer: Buffer | Uint8Array): string {
  return Buffer.from(buffer)
    .toString("base64")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

function base64urlDecode(input: string): Buffer {
  const padded = input.replace(/-/g, "+").replace(/_/g, "/") +
    "=".repeat((4 - (input.length % 4)) % 4);
  return Buffer.from(padded, "base64");
}

function base64urlJSON(value: unknown): string {
  return base64url(Buffer.from(JSON.stringify(value), "utf8"));
}

export function makeSalt(): string {
  return randomBytes(16).toString("hex");
}

export async function hashPassword(password: string, salt: string): Promise<string> {
  const derived = await scrypt(password, salt, KEY_LENGTH);
  return derived.toString("hex");
}

export async function verifyPassword(
  password: string,
  salt: string,
  expectedHashHex: string,
): Promise<boolean> {
  const derived = await scrypt(password, salt, KEY_LENGTH);
  const expected = Buffer.from(expectedHashHex, "hex");
  if (derived.length !== expected.length) return false;
  return timingSafeEqual(derived, expected);
}

export type JwtPayload = {
  sub: string;
  email: string;
  exp: number;
};

export function signToken(
  payload: { sub: string; email: string },
  secret: string,
): string {
  if (!secret) throw new Error("JWT_SECRET is not configured");
  const header = base64urlJSON({ alg: "HS256", typ: "JWT" });
  const body = base64urlJSON({
    ...payload,
    exp: Math.floor(Date.now() / 1000) + TOKEN_TTL_SECONDS,
  });
  const signature = signHmac(`${header}.${body}`, secret);
  return `${header}.${body}.${signature}`;
}

export function verifyToken(token: string, secret: string): JwtPayload {
  if (!secret) throw new Error("JWT_SECRET is not configured");
  const parts = token.split(".");
  if (parts.length !== 3) throw new Error("Invalid token");
  const [header, body, signature] = parts as [string, string, string];
  const expected = signHmac(`${header}.${body}`, secret);
  const a = Buffer.from(signature);
  const b = Buffer.from(expected);
  if (a.length !== b.length || !timingSafeEqual(a, b)) {
    throw new Error("Invalid token");
  }
  const payload = JSON.parse(base64urlDecode(body).toString("utf8")) as JwtPayload;
  if (payload.exp < Math.floor(Date.now() / 1000)) {
    throw new Error("Expired token");
  }
  return payload;
}

function signHmac(input: string, secret: string): string {
  return base64url(createHmac("sha256", secret).update(input).digest());
}
