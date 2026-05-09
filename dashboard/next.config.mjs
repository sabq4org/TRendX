/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Bind the dashboard to the deployed Railway API at build time. Override
  // with NEXT_PUBLIC_TRENDX_API at deploy time when the URL changes.
  env: {
    NEXT_PUBLIC_TRENDX_API:
      process.env.NEXT_PUBLIC_TRENDX_API ?? "https://trendx-production.up.railway.app",
  },
};

export default nextConfig;
