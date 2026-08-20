import { createFileRoute } from "@tanstack/react-router";

function env(...names: string[]): string {
  for (const name of names) {
    const value = typeof process !== "undefined" ? process.env[name] : undefined;
    if (value) return value;
  }
  return "";
}

export const Route = createFileRoute("/api/public/media/$")({
  server: {
    handlers: {
      GET: async ({ params }) => {
        const path = params._splat ?? "";
        if (!path || path.includes("..")) return new Response("Not found", { status: 404 });

        const url = env("SUPABASE_URL", "VITE_SUPABASE_URL");
        const key = env("SUPABASE_PUBLISHABLE_KEY", "VITE_SUPABASE_PUBLISHABLE_KEY", "SUPABASE_ANON_KEY");
        if (!url || !key) {
          console.error("[media] Supabase env missing on this host");
          return new Response("Media backend not configured", { status: 500 });
        }

        const encodedPath = path.split("/").map(encodeURIComponent).join("/");
        const cleanUrl = url.replace(/\/+$/, "");
        
        // Try public storage endpoint first, then authenticated storage endpoint
        const targets = [
          `${cleanUrl}/storage/v1/object/public/media/${encodedPath}`,
          `${cleanUrl}/storage/v1/object/media/${encodedPath}`,
        ];

        for (const target of targets) {
          try {
            const upstream = await fetch(target, { headers: { apikey: key } });
            if (upstream.ok && upstream.body) {
              return new Response(upstream.body, {
                headers: {
                  "Content-Type": upstream.headers.get("content-type") ?? "image/png",
                  "Cache-Control": "public, max-age=31536000, immutable",
                },
              });
            }
          } catch (err) {
            console.error("[media] fetch failed for target", target, err);
          }
        }

        return new Response("Not found", { status: 404 });
      },
    },
  },
});
