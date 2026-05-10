import "../globals.css";
import type { Metadata } from "next";
import { Tajawal, Inter } from "next/font/google";

const tajawal = Tajawal({
  subsets: ["arabic", "latin"],
  weight: ["400", "500", "700", "800", "900"],
  variable: "--font-tajawal",
  display: "swap",
});

const inter = Inter({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800"],
  variable: "--font-inter",
  display: "swap",
});

export const metadata: Metadata = {
  title: "TRENDX — Report",
  description: "TRENDX printable intelligence report",
};

export default function ReportsLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ar" dir="rtl" className={`${tajawal.variable} ${inter.variable}`}>
      <body className="bg-white text-ink font-sans">
        {children}
      </body>
    </html>
  );
}
