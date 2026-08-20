import { useState } from "react";
import { cn } from "@/lib/utils";
import { mediaUrl } from "@/lib/media";

const PLACEHOLDER_SRC = "/placeholder-bag.png";

export function SmartImage({
  path,
  alt,
  className,
  ratio = "aspect-4/5",
  eager = false,
}: {
  path: string | null | undefined;
  alt: string;
  className?: string;
  ratio?: string;
  eager?: boolean;
}) {
  const [hasError, setHasError] = useState(false);
  const initialSrc = path ? mediaUrl(path) : PLACEHOLDER_SRC;
  const src = hasError ? PLACEHOLDER_SRC : initialSrc;

  return (
    <div className={cn("relative overflow-hidden rounded-sm bg-secondary", ratio, className)}>
      <img
        src={src}
        alt=""
        aria-hidden
        loading="lazy"
        className="absolute inset-0 size-full scale-110 object-cover opacity-40 blur-xl"
        onError={() => setHasError(true)}
      />
      <img
        src={src}
        alt={alt}
        loading={eager ? "eager" : "lazy"}
        decoding="async"
        onError={() => setHasError(true)}
        className="relative size-full object-contain transition-transform duration-700 group-hover:scale-105"
      />
    </div>
  );
}
