/**
 * Post-vote comments — only after a user has voted on a poll can they
 * leave a short comment (≤ 500 chars). Comments carry the author's
 * frozen vote so the UI can label "صوّت لـ X" on each comment.
 *
 * Sort orders:
 *   - "top"  → score desc (upvotes - downvotes)
 *   - "new"  → recent
 */

import { prisma } from "../db.js";

export async function listComments(
  pollId: string,
  sort: "top" | "new" = "top",
  limit = 50,
): Promise<Array<{
  id: string;
  body: string;
  score: number;
  upvotes: number;
  downvotes: number;
  created_at: string;
  author_vote_option_id: string | null;
  user: { id: string; name: string; avatar_initial: string };
}>> {
  const rows = await prisma.pollComment.findMany({
    where: { pollId, status: "visible" },
    orderBy: sort === "top" ? [{ score: "desc" }, { createdAt: "desc" }] : { createdAt: "desc" },
    take: limit,
    include: {
      user: { select: { id: true, name: true, avatarInitial: true } },
    },
  });
  return rows.map((r) => ({
    id: r.id,
    body: r.body,
    score: r.score,
    upvotes: r.upvotes,
    downvotes: r.downvotes,
    created_at: r.createdAt.toISOString(),
    author_vote_option_id: r.authorVoteOptionId,
    user: {
      id: r.user.id,
      name: r.user.name,
      avatar_initial: r.user.avatarInitial,
    },
  }));
}

export async function postComment(
  userId: string,
  pollId: string,
  body: string,
): Promise<{ id: string }> {
  const trimmed = body.trim();
  if (trimmed.length < 2 || trimmed.length > 500) {
    throw Object.assign(new Error("body length must be 2..500"), { httpStatus: 400 });
  }
  // User must have voted on this poll first.
  const myVote = await prisma.vote.findFirst({
    where: { pollId, userId },
    select: { optionId: true },
  });
  if (!myVote) {
    throw Object.assign(new Error("must vote before commenting"), { httpStatus: 403 });
  }

  const created = await prisma.pollComment.create({
    data: {
      pollId,
      userId,
      body: trimmed,
      authorVoteOptionId: myVote.optionId,
    },
  });
  return { id: created.id };
}

export async function voteOnComment(
  userId: string,
  commentId: string,
  value: 1 | -1,
): Promise<{ score: number; upvotes: number; downvotes: number }> {
  const existing = await prisma.pollCommentVote.findUnique({
    where: { commentId_userId: { commentId, userId } },
  });

  await prisma.$transaction(async (tx) => {
    if (existing) {
      if (existing.value === value) {
        // Toggling off
        await tx.pollCommentVote.delete({
          where: { commentId_userId: { commentId, userId } },
        });
        await tx.pollComment.update({
          where: { id: commentId },
          data: {
            upvotes: value === 1 ? { decrement: 1 } : undefined,
            downvotes: value === -1 ? { decrement: 1 } : undefined,
            score: value === 1 ? { decrement: 1 } : { increment: 1 },
          },
        });
      } else {
        // Switching direction (delta of 2)
        await tx.pollCommentVote.update({
          where: { commentId_userId: { commentId, userId } },
          data: { value },
        });
        await tx.pollComment.update({
          where: { id: commentId },
          data: {
            upvotes: value === 1 ? { increment: 1 } : { decrement: 1 },
            downvotes: value === -1 ? { increment: 1 } : { decrement: 1 },
            score: value === 1 ? { increment: 2 } : { decrement: 2 },
          },
        });
      }
    } else {
      await tx.pollCommentVote.create({
        data: { commentId, userId, value },
      });
      await tx.pollComment.update({
        where: { id: commentId },
        data: {
          upvotes: value === 1 ? { increment: 1 } : undefined,
          downvotes: value === -1 ? { increment: 1 } : undefined,
          score: value === 1 ? { increment: 1 } : { decrement: 1 },
        },
      });
    }
  });

  const fresh = await prisma.pollComment.findUnique({
    where: { id: commentId },
    select: { score: true, upvotes: true, downvotes: true },
  });
  return {
    score: fresh?.score ?? 0,
    upvotes: fresh?.upvotes ?? 0,
    downvotes: fresh?.downvotes ?? 0,
  };
}
