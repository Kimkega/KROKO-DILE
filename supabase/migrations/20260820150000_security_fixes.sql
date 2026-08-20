-- SECURITY FIXES FOR CRITICAL & WARNING VULNERABILITIES

-- 1. Fix: Advertiser contact details exposed to the public
-- Revoke full table select from anon and grant ONLY public display columns
DROP POLICY IF EXISTS "ads public read live" ON public.ads;
REVOKE SELECT ON public.ads FROM anon;
GRANT SELECT (id, title, body, image_url, target_url, placement, starts_at, ends_at, status, payment_status)
  ON public.ads TO anon;
CREATE POLICY "ads public read live" ON public.ads FOR SELECT TO anon
  USING (status = 'approved' AND payment_status = 'paid' AND (starts_at IS NULL OR starts_at <= now()) AND (ends_at IS NULL OR ends_at > now()));

-- 2. Fix: Private storage bucket fully exposed via overly broad read policy
-- Restrict public media bucket read access to public asset subfolders only
DROP POLICY IF EXISTS "media public read" ON storage.objects;
DROP POLICY IF EXISTS "media public prefixes read" ON storage.objects;
CREATE POLICY "media public prefixes read" ON storage.objects FOR SELECT TO anon, authenticated
USING (
  bucket_id = 'media'
  AND (storage.foldername(name))[1] IN ('products', 'branding', 'ads', 'categories', 'public')
);

-- 3. Fix: Courier phone numbers publicly readable
-- Restrict public read access to courier names/kinds, hiding internal notes and phone numbers from anon
DROP POLICY IF EXISTS "couriers public read" ON public.couriers;
DROP POLICY IF EXISTS "couriers staff read" ON public.couriers;
REVOKE SELECT ON public.couriers FROM anon, authenticated;
GRANT SELECT (id, name, kind, active, created_at) ON public.couriers TO anon;
GRANT SELECT (id, name, kind, active, created_at, notes, phone) ON public.couriers TO authenticated;
CREATE POLICY "couriers public read" ON public.couriers FOR SELECT TO anon USING (active = true);
CREATE POLICY "couriers staff read" ON public.couriers FOR SELECT TO authenticated USING (true);

-- 4. Fix: Signed-In Users Can Execute SECURITY DEFINER Functions
-- Revoke execution of internal security definer functions from public/anon/authenticated
REVOKE ALL ON FUNCTION public.gen_certificate_code() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.products_issue_certificate() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.touch_updated_at() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.has_role(uuid, public.app_role) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO authenticated, service_role;
