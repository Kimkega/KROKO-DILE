import { createFileRoute } from "@tanstack/react-router";

function env(...names: string[]): string {
  for (const name of names) {
    const value = typeof process !== "undefined" ? process.env[name] : undefined;
    if (value) return value;
  }
  return "";
}

// In-memory cache for high-traffic image serving
interface CachedMedia {
  data: Uint8Array;
  contentType: string;
  timestamp: number;
}
const mediaCache = new Map<string, CachedMedia>();
const MAX_CACHE_AGE_MS = 60 * 60 * 1000; // 1 hour

export const Route = createFileRoute("/api/public/media/$")({
  server: {
    handlers: {
      GET: async ({ params, request }) => {
        const path = params._splat ?? "";
        if (!path || path.includes("..")) return new Response("Not found", { status: 404 });

        // Serve from memory cache if fresh
        const cached = mediaCache.get(path);
        if (cached && Date.now() - cached.timestamp < MAX_CACHE_AGE_MS) {
          return new Response(cached.data, {
            headers: {
              "Content-Type": cached.contentType,
              "Cache-Control": "public, max-age=31536000, immutable",
              "X-Cache": "HIT",
            },
          });
        }

        const url = env("SUPABASE_URL", "VITE_SUPABASE_URL");
        const key = env("SUPABASE_PUBLISHABLE_KEY", "VITE_SUPABASE_PUBLISHABLE_KEY", "SUPABASE_ANON_KEY");
        if (!url || !key) {
          console.error("[media] Supabase env missing on this host");
          return new Response("Media backend not configured", { status: 500 });
        }

        const encodedPath = path.split("/").map(encodeURIComponent).join("/");
        const cleanUrl = url.replace(/\/+$/, "");
        
        const targets = [
          `${cleanUrl}/storage/v1/object/public/media/${encodedPath}`,
          `${cleanUrl}/storage/v1/object/media/${encodedPath}`,
        ];

        for (const target of targets) {
          try {
            const upstream = await fetch(target, { headers: { apikey: key } });
            if (upstream.ok && upstream.body) {
              const arrayBuffer = await upstream.arrayBuffer();
              const buffer = new Uint8Array(arrayBuffer);
              const contentType = upstream.headers.get("content-type") ?? "image/jpeg";

              // Cache in memory for high performance
              mediaCache.set(path, {
                data: buffer,
                contentType,
                timestamp: Date.now(),
              });

              return new Response(buffer, {
                headers: {
                  "Content-Type": contentType,
                  "Cache-Control": "public, max-age=31536000, immutable",
                  "X-Cache": "MISS",
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
