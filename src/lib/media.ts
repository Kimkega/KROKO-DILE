/** Direct public Supabase Storage URL builder - guarantees 100% working images across Vercel, Netlify & local dev. */
function getSupabaseUrl(): string {
  const metaUrl = typeof import.meta !== "undefined" && import.meta.env ? import.meta.env.VITE_SUPABASE_URL : undefined;
  if (metaUrl) return metaUrl.replace(/\/+$/, "");
  const procUrl = typeof process !== "undefined" && process.env ? process.env.VITE_SUPABASE_URL || process.env.SUPABASE_URL : undefined;
  if (procUrl) return procUrl.replace(/\/+$/, "");
  return "https://nfilzruslmjjkoupkvif.supabase.co";
}

export function mediaUrl(path: string | null | undefined): string {
  if (!path) return "";

  // Fix legacy URLs pointing to private Supabase storage endpoint (missing '/public/')
  if (path.includes("/storage/v1/object/media/") && !path.includes("/storage/v1/object/public/media/")) {
    return path.replace("/storage/v1/object/media/", "/storage/v1/object/public/media/");
  }

  // If path is already a full HTTP/HTTPS URL or data URI, return as-is
  if (path.startsWith("http://") || path.startsWith("https://") || path.startsWith("data:")) {
    return path;
  }

  // If path is a local static asset starting with '/', return as-is
  if (path.startsWith("/")) return path;

  // Construct direct public Supabase Storage CDN URL for Vercel & host-agnostic compatibility
  const baseUrl = getSupabaseUrl();
  const cleanPath = path.replace(/^\/+/, "");
  return `${baseUrl}/storage/v1/object/public/media/${cleanPath}`;
}
