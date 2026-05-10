"use client";

import { useEffect } from "react";
import { usePathname, useRouter } from "next/navigation";
import { useAuth } from "@/lib/auth";
import { Sidebar } from "@/components/Sidebar";
import { canAccess, groupForPath, type Role } from "@/lib/role-gate";

export default function AuthedLayout({ children }: { children: React.ReactNode }) {
  const { token, user, loading } = useAuth();
  const router = useRouter();
  const pathname = usePathname() ?? "/overview";

  // Auth gate
  useEffect(() => {
    if (!loading && !token) router.replace("/login");
  }, [loading, token, router]);

  // Role gate — kick respondents (and unauthorised publishers) back to
  // /overview if they navigate to a page they can't see.
  useEffect(() => {
    if (loading || !user) return;
    const required = groupForPath(pathname);
    if (!canAccess(user.role as Role, required)) {
      router.replace("/overview");
    }
  }, [loading, user, pathname, router]);

  if (loading || !token) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="w-10 h-10 rounded-full border-2 border-ink-line border-t-brand-500 animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen flex">
      <Sidebar />
      <main className="flex-1 min-w-0 flex flex-col">{children}</main>
    </div>
  );
}
