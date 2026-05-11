/**
 * Event domain helpers + DTO.
 *
 * Events are public happenings — a ministry's seasonal festival, a
 * sports day, an industry conference. iOS renders a Saudi map driven
 * by `cityBreakdown` so participants light up where they are.
 */

import type { Event, EventResponse, User } from "@prisma/client";
import { prisma } from "../db.js";
import { userDTO } from "./dto.js";

type EventWithPublisher = Event & {
  publisher?: User | null;
};

export function eventDTO(
  e: EventWithPublisher,
  options: { viewerStatus?: string | null; cityBreakdown?: { city: string; count: number }[] } = {},
) {
  return {
    id: e.id,
    title: e.title,
    description: e.description,
    banner_image: e.bannerImage,
    category: e.category,
    status: e.status,
    starts_at: e.startsAt.toISOString(),
    ends_at: e.endsAt?.toISOString() ?? null,
    city: e.city,
    venue: e.venue,
    lat: e.lat !== null && e.lat !== undefined ? Number(e.lat) : null,
    lng: e.lng !== null && e.lng !== undefined ? Number(e.lng) : null,
    rsvp_count: e.rsvpCount,
    attending_count: e.attendingCount,
    publisher: e.publisher ? userDTO(e.publisher) : null,
    viewer_status: options.viewerStatus ?? null,
    city_breakdown: options.cityBreakdown ?? [],
    created_at: e.createdAt.toISOString(),
    updated_at: e.updatedAt.toISOString(),
  };
}

/**
 * Aggregated city counts for the Saudi map. Top 12 cities by
 * `attending` responses. Empty array when no one has RSVPed yet.
 */
export async function eventCityBreakdown(eventId: string) {
  const rows = await prisma.eventResponse.groupBy({
    by: ["city"],
    where: {
      eventId,
      status: "attending",
      city: { not: null },
    },
    _count: { _all: true },
    orderBy: { _count: { city: "desc" } },
    take: 12,
  });
  return rows
    .filter((r) => r.city !== null)
    .map((r) => ({ city: r.city as string, count: r._count._all }));
}

/**
 * Upsert (set/change) the viewer's RSVP. Keeps the counters in sync
 * inside a single transaction.
 */
export async function rsvpEvent(
  eventId: string,
  userId: string,
  status: "attending" | "maybe" | "not_attending",
) {
  const event = await prisma.event.findUnique({ where: { id: eventId } });
  if (!event) {
    throw Object.assign(new Error("Event not found"), { httpStatus: 404 });
  }

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { city: true },
  });

  const existing = await prisma.eventResponse.findUnique({
    where: { eventId_userId: { eventId, userId } },
  });

  // Counter deltas.
  let rsvpDelta = 0;
  let attendingDelta = 0;
  if (existing) {
    if (existing.status === "attending" && status !== "attending") attendingDelta = -1;
    if (existing.status !== "attending" && status === "attending") attendingDelta = 1;
  } else {
    rsvpDelta = 1;
    if (status === "attending") attendingDelta = 1;
  }

  await prisma.$transaction([
    prisma.eventResponse.upsert({
      where: { eventId_userId: { eventId, userId } },
      create: { eventId, userId, status, city: user?.city ?? null },
      update: { status, city: user?.city ?? existing?.city ?? null },
    }),
    prisma.event.update({
      where: { id: eventId },
      data: {
        rsvpCount: { increment: rsvpDelta },
        attendingCount: { increment: attendingDelta },
      },
    }),
  ]);

  return prisma.event.findUnique({
    where: { id: eventId },
    include: { publisher: true },
  });
}
