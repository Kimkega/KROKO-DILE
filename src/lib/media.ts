/** Media stored in the `media` bucket is served through a public proxy route or direct public storage URL. */
export function mediaUrl(path: string | null | undefined): string {
  if (!path) return "";

  // Fix URLs pointing to private Supabase storage endpoint (missing '/public/')
  if (path.includes("/storage/v1/object/media/") && !path.includes("/storage/v1/object/public/media/")) {
    return path.replace("/storage/v1/object/media/", "/storage/v1/object/public/media/");
  }

  // If path is a full URL or data URI, return as-is
  if (path.startsWith("http://") || path.startsWith("https://") || path.startsWith("data:")) {
    return path;
  }

  // If path starts with root slash, return as-is
  if (path.startsWith("/")) return path;

  // Otherwise proxy relative paths
  return `/api/public/media/${path}`;
}
