DO $$ 
BEGIN 
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'app_role') THEN 
    CREATE TYPE public.app_role AS ENUM ('admin','staff','user'); 
  END IF; 
END $$;

CREATE TABLE IF NOT EXISTS public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  role public.app_role NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);
GRANT SELECT ON public.user_roles TO authenticated;
GRANT ALL ON public.user_roles TO service_role;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "own roles readable" ON public.user_roles;
CREATE POLICY "own roles readable" ON public.user_roles FOR SELECT TO authenticated USING (user_id = auth.uid());

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;

CREATE OR REPLACE FUNCTION public.touch_updated_at() RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

CREATE TABLE IF NOT EXISTS public.categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text NOT NULL UNIQUE,
  description text,
  image_url text,
  sort_order int NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.categories TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.categories TO authenticated;
GRANT ALL ON public.categories TO service_role;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "categories public read" ON public.categories;
CREATE POLICY "categories public read" ON public.categories FOR SELECT USING (true);
DROP POLICY IF EXISTS "categories admin write" ON public.categories;
CREATE POLICY "categories admin write" ON public.categories FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));

CREATE TABLE IF NOT EXISTS public.products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text NOT NULL UNIQUE,
  description text,
  price numeric(12,2) NOT NULL DEFAULT 0,
  compare_at_price numeric(12,2),
  category_id uuid REFERENCES public.categories(id) ON DELETE SET NULL,
  material text,
  colors text[] NOT NULL DEFAULT '{}',
  stock int NOT NULL DEFAULT 0,
  featured boolean NOT NULL DEFAULT false,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
DROP TRIGGER IF EXISTS products_touch ON public.products;
CREATE TRIGGER products_touch BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
GRANT SELECT ON public.products TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.products TO authenticated;
GRANT ALL ON public.products TO service_role;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "products public read" ON public.products;
CREATE POLICY "products public read" ON public.products FOR SELECT USING (true);
DROP POLICY IF EXISTS "products admin write" ON public.products;
CREATE POLICY "products admin write" ON public.products FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));

CREATE TABLE IF NOT EXISTS public.product_images (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  url text NOT NULL,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.product_images TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.product_images TO authenticated;
GRANT ALL ON public.product_images TO service_role;
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "product images public read" ON public.product_images;
CREATE POLICY "product images public read" ON public.product_images FOR SELECT USING (true);
DROP POLICY IF EXISTS "product images admin write" ON public.product_images;
CREATE POLICY "product images admin write" ON public.product_images FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));

CREATE TABLE IF NOT EXISTS public.couriers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  kind text NOT NULL DEFAULT 'courier',
  phone text,
  notes text,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.couriers TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.couriers TO authenticated;
GRANT ALL ON public.couriers TO service_role;
ALTER TABLE public.couriers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "couriers public read" ON public.couriers;
CREATE POLICY "couriers public read" ON public.couriers FOR SELECT USING (true);
DROP POLICY IF EXISTS "couriers admin write" ON public.couriers;
CREATE POLICY "couriers admin write" ON public.couriers FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));

CREATE TABLE IF NOT EXISTS public.shipping_zones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  county text NOT NULL UNIQUE,
  fee numeric(12,2) NOT NULL DEFAULT 0,
  eta text,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.shipping_zones TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.shipping_zones TO authenticated;
GRANT ALL ON public.shipping_zones TO service_role;
ALTER TABLE public.shipping_zones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "zones public read" ON public.shipping_zones;
CREATE POLICY "zones public read" ON public.shipping_zones FOR SELECT USING (true);
DROP POLICY IF EXISTS "zones admin write" ON public.shipping_zones;
CREATE POLICY "zones admin write" ON public.shipping_zones FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));

CREATE TABLE IF NOT EXISTS public.site_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_name text NOT NULL DEFAULT 'KROKO DILE',
  tagline text DEFAULT 'Luxury leather bags, made for the bold.',
  logo_url text,
  whatsapp_number text DEFAULT '254700000000',
  contact_phone text,
  contact_email text,
  instagram_url text,
  facebook_url text,
  tiktok_url text,
  x_url text,
  free_shipping_threshold numeric(12,2) NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now()
);
DROP TRIGGER IF EXISTS site_settings_touch ON public.site_settings;
CREATE TRIGGER site_settings_touch BEFORE UPDATE ON public.site_settings FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
GRANT SELECT ON public.site_settings TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.site_settings TO authenticated;
GRANT ALL ON public.site_settings TO service_role;
ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "settings public read" ON public.site_settings;
CREATE POLICY "settings public read" ON public.site_settings FOR SELECT USING (true);
DROP POLICY IF EXISTS "settings admin write" ON public.site_settings;
CREATE POLICY "settings admin write" ON public.site_settings FOR ALL TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));

CREATE TABLE IF NOT EXISTS public.mpesa_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  environment text NOT NULL DEFAULT 'sandbox',
  short_code text,
  paybill text,
  party_b text,
  passkey text,
  consumer_key text,
  consumer_secret text,
  account_reference text DEFAULT 'KROKODILE',
  callback_url text,
  enabled boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now()
);
DROP TRIGGER IF EXISTS mpesa_config_touch ON public.mpesa_config;
CREATE TRIGGER mpesa_config_touch BEFORE UPDATE ON public.mpesa_config FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
GRANT ALL ON public.mpesa_config TO service_role;
ALTER TABLE public.mpesa_config ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_code text NOT NULL UNIQUE,
  customer_name text NOT NULL,
  email text NOT NULL,
  phone text NOT NULL,
  county text,
  sub_county text,
  ward text,
  town text,
  address_notes text,
  subtotal numeric(12,2) NOT NULL DEFAULT 0,
  shipping_fee numeric(12,2) NOT NULL DEFAULT 0,
  total numeric(12,2) NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'pending',
  payment_status text NOT NULL DEFAULT 'pending',
  payment_method text NOT NULL DEFAULT 'mpesa',
  mpesa_receipt text,
  checkout_request_id text,
  merchant_request_id text,
  payment_message text,
  courier_id uuid REFERENCES public.couriers(id) ON DELETE SET NULL,
  tracking_ref text,
  admin_notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
DROP TRIGGER IF EXISTS orders_touch ON public.orders;
CREATE TRIGGER orders_touch BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE INDEX IF NOT EXISTS orders_checkout_request_idx ON public.orders(checkout_request_id);
GRANT SELECT, UPDATE ON public.orders TO authenticated;
GRANT ALL ON public.orders TO service_role;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "orders admin read" ON public.orders;
CREATE POLICY "orders admin read" ON public.orders FOR SELECT TO authenticated USING (public.has_role(auth.uid(),'admin'));
DROP POLICY IF EXISTS "orders admin update" ON public.orders;
CREATE POLICY "orders admin update" ON public.orders FOR UPDATE TO authenticated
  USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));

CREATE TABLE IF NOT EXISTS public.order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id uuid REFERENCES public.products(id) ON DELETE SET NULL,
  name text NOT NULL,
  unit_price numeric(12,2) NOT NULL DEFAULT 0,
  quantity int NOT NULL DEFAULT 1,
  image_url text,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.order_items TO authenticated;
GRANT ALL ON public.order_items TO service_role;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "order items admin read" ON public.order_items;
CREATE POLICY "order items admin read" ON public.order_items FOR SELECT TO authenticated USING (public.has_role(auth.uid(),'admin'));

CREATE TABLE IF NOT EXISTS public.order_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  status text NOT NULL,
  note text,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.order_events TO authenticated;
GRANT ALL ON public.order_events TO service_role;
ALTER TABLE public.order_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "order events admin read" ON public.order_events;
CREATE POLICY "order events admin read" ON public.order_events FOR SELECT TO authenticated USING (public.has_role(auth.uid(),'admin'));

INSERT INTO public.site_settings (site_name) VALUES ('KROKO DILE') ON CONFLICT DO NOTHING;

INSERT INTO public.categories (name, slug, description, sort_order) VALUES
  ('Men','men','Briefcases, weekenders and crocodile-grain totes for men.',1),
  ('Women','women','Handbags, clutches and shoulder bags in gold-toned leather.',2),
  ('Travel','travel','Duffels and cabin bags built for the long haul.',3),
  ('Accessories','accessories','Wallets, belts and small leather goods.',4)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.couriers (name, kind) VALUES
  ('G4S Courier','courier'),('Wells Fargo Courier','courier'),('Fargo Courier','courier'),
  ('Aramex Kenya','courier'),('DHL Kenya','courier'),('FedEx Kenya','courier'),
  ('Posta Kenya (EMS)','courier'),('Speedaf Express','courier'),('Sendy','courier'),
  ('Pickup Mtaani','courier'),('Glovo Kenya','courier'),('Bolt Send','courier'),
  ('Uber Connect','courier'),('Rider Africa','courier'),('Tuma Kenya','courier'),
  ('Easy Coach Parcels','sacco'),('Modern Coast Parcels','sacco'),('Mash Poa Parcels','sacco'),
  ('Guardian Angel Sacco','sacco'),('Super Metro Sacco','sacco'),('2NK Sacco','sacco'),
  ('Kukena Sacco','sacco'),('Chania Genesis Sacco','sacco'),('Neno Sacco','sacco'),
  ('North Rift Shuttle','sacco'),('Transline Classic','sacco'),('Climax Coaches','sacco'),
  ('Coast Bus','sacco'),('Tahmeed Coach','sacco'),('Prestige Shuttle','sacco'),
  ('4NTE Sacco','sacco'),('Kijabe Line','sacco'),('Ena Coach','sacco'),
  ('Nairobiâ€“Kisumu SGR Cargo','sacco'),('Madaraka Express Cargo','sacco')
ON CONFLICT DO NOTHING;
REVOKE EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO authenticated, service_role;
CREATE POLICY "media admin read" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'media' AND public.has_role(auth.uid(),'admin'));
CREATE POLICY "media admin insert" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'media' AND public.has_role(auth.uid(),'admin'));
CREATE POLICY "media admin update" ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'media' AND public.has_role(auth.uid(),'admin'));
CREATE POLICY "media admin delete" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'media' AND public.has_role(auth.uid(),'admin'));
-- products: low stock threshold
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS low_stock_threshold integer NOT NULL DEFAULT 3;

-- site settings: whatsapp follow-up template
ALTER TABLE public.site_settings ADD COLUMN IF NOT EXISTS whatsapp_template text;

-- guest advertising purchases
CREATE TABLE IF NOT EXISTS public.ads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ad_code text NOT NULL UNIQUE,
  advertiser_name text NOT NULL,
  email text NOT NULL,
  phone text NOT NULL,
  title text NOT NULL,
  body text,
  image_url text,
  target_url text,
  placement text NOT NULL DEFAULT 'home_banner',
  days integer NOT NULL DEFAULT 7,
  amount numeric NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'pending',
  payment_status text NOT NULL DEFAULT 'pending',
  payment_message text,
  mpesa_receipt text,
  checkout_request_id text,
  merchant_request_id text,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.ads TO authenticated;
GRANT SELECT ON public.ads TO anon;
GRANT ALL ON public.ads TO service_role;
ALTER TABLE public.ads ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ads public read live" ON public.ads FOR SELECT TO anon, authenticated
  USING (status = 'approved' AND payment_status = 'paid' AND (ends_at IS NULL OR ends_at > now()));
CREATE POLICY "ads admin write" ON public.ads FOR ALL TO authenticated
  USING (has_role(auth.uid(), 'admin'::app_role)) WITH CHECK (has_role(auth.uid(), 'admin'::app_role));
CREATE TRIGGER ads_touch BEFORE UPDATE ON public.ads FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- brand authenticity certificates
CREATE TABLE IF NOT EXISTS public.certificates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  serial text,
  product_id uuid REFERENCES public.products(id) ON DELETE SET NULL,
  product_name text,
  order_id uuid REFERENCES public.orders(id) ON DELETE SET NULL,
  issued_to text,
  notes text,
  status text NOT NULL DEFAULT 'active',
  scans integer NOT NULL DEFAULT 0,
  last_scanned_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.certificates TO authenticated;
GRANT ALL ON public.certificates TO service_role;
ALTER TABLE public.certificates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "certificates admin all" ON public.certificates FOR ALL TO authenticated
  USING (has_role(auth.uid(), 'admin'::app_role)) WITH CHECK (has_role(auth.uid(), 'admin'::app_role));
-- site settings additions
ALTER TABLE public.site_settings
  ADD COLUMN IF NOT EXISTS public_base_url text,
  ADD COLUMN IF NOT EXISTS courier_contact_note text;

-- order additions
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS courier_contact text,
  ADD COLUMN IF NOT EXISTS delivery_note_no text;

-- certificates link to a real order
ALTER TABLE public.certificates
  ADD COLUMN IF NOT EXISTS order_code text,
  ADD COLUMN IF NOT EXISTS buyer_name text,
  ADD COLUMN IF NOT EXISTS paid_at timestamptz;

-- SMTP configuration (service role only)
CREATE TABLE IF NOT EXISTS public.smtp_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  host text,
  port integer NOT NULL DEFAULT 587,
  secure boolean NOT NULL DEFAULT false,
  username text,
  password text,
  from_name text,
  from_email text,
  reply_to text,
  enabled boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT ALL ON public.smtp_config TO service_role;
ALTER TABLE public.smtp_config ENABLE ROW LEVEL SECURITY;

-- Email templates
CREATE TABLE IF NOT EXISTS public.email_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text NOT NULL UNIQUE,
  label text NOT NULL,
  subject text NOT NULL,
  body text NOT NULL,
  enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.email_templates TO authenticated;
GRANT ALL ON public.email_templates TO service_role;
ALTER TABLE public.email_templates ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins read email templates" ON public.email_templates;
CREATE POLICY "Admins read email templates" ON public.email_templates
  FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin'));

DROP TRIGGER IF EXISTS smtp_config_touch ON public.smtp_config;
CREATE TRIGGER smtp_config_touch BEFORE UPDATE ON public.smtp_config
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
DROP TRIGGER IF EXISTS email_templates_touch ON public.email_templates;
CREATE TRIGGER email_templates_touch BEFORE UPDATE ON public.email_templates
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

INSERT INTO public.email_templates (key, label, subject, body) VALUES
  ('order_placed', 'Order placed', 'Order {{order_code}} received â€” {{site_name}}',
   'Hello {{customer_name}},

We have received your order {{order_code}}.

{{items}}

Total: {{total}}
Payment: {{payment_status}}

If payment did not go through you can complete it here: {{pay_url}}

Thank you,
{{site_name}}'),
  ('payment_received', 'Payment received', 'Payment confirmed for {{order_code}}',
   'Hello {{customer_name}},

We have received {{total}} for order {{order_code}}. M-Pesa code: {{mpesa_receipt}}.

Track your delivery: {{track_url}}

{{site_name}}'),
  ('payment_failed', 'Payment not completed', 'Complete your payment for {{order_code}}',
   'Hello {{customer_name}},

Your payment for order {{order_code}} was not completed.

Retry securely here: {{pay_url}}

{{site_name}}'),
  ('order_packed', 'Order packed', 'Order {{order_code}} is packed',
   'Hello {{customer_name}},

Order {{order_code}} has been packed and is being prepared for dispatch.

{{site_name}}'),
  ('courier_assigned', 'Courier assigned', 'Courier assigned for {{order_code}}',
   'Hello {{customer_name}},

{{courier}} will handle delivery of order {{order_code}}. Reference: {{tracking_ref}}.
Courier contact: {{courier_contact}}

Track: {{track_url}}

{{site_name}}'),
  ('in_transit', 'Out for delivery', 'Order {{order_code}} is on the way',
   'Hello {{customer_name}},

Order {{order_code}} is in transit with {{courier}} ({{tracking_ref}}).

Track: {{track_url}}

{{site_name}}'),
  ('delivered', 'Delivered', 'Order {{order_code}} delivered',
   'Hello {{customer_name}},

Order {{order_code}} has been delivered. Thank you for choosing {{site_name}}.

Verify your authenticity card: {{verify_url}}'),
  ('cancelled', 'Order cancelled', 'Order {{order_code}} cancelled',
   'Hello {{customer_name}},

Order {{order_code}} has been cancelled. Talk to us if this is unexpected.

{{site_name}}')
ON CONFLICT (key) DO NOTHING;
-- 1. Allow anonymous read of the media bucket so images work on any host without a service key
DROP POLICY IF EXISTS "media public read" ON storage.objects;
CREATE POLICY "media public read" ON storage.objects
  FOR SELECT TO anon, authenticated USING (bucket_id = 'media');

-- 2. Certificates carry buyer + delivery detail
ALTER TABLE public.certificates
  ADD COLUMN IF NOT EXISTS customer_email text,
  ADD COLUMN IF NOT EXISTS customer_phone text,
  ADD COLUMN IF NOT EXISTS delivery_address text,
  ADD COLUMN IF NOT EXISTS assigned_at timestamptz;

CREATE UNIQUE INDEX IF NOT EXISTS certificates_code_key ON public.certificates (code);

-- 3. Every product automatically gets an authenticity certificate on creation
CREATE OR REPLACE FUNCTION public.gen_certificate_code()
RETURNS text
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  alphabet text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  part1 text := '';
  part2 text := '';
  i int;
BEGIN
  FOR i IN 1..4 LOOP
    part1 := part1 || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
    part2 := part2 || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
  END LOOP;
  RETURN 'KD-' || part1 || '-' || part2;
END;
$$;

CREATE OR REPLACE FUNCTION public.products_issue_certificate()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_code text;
  tries int := 0;
BEGIN
  LOOP
    new_code := public.gen_certificate_code();
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.certificates WHERE code = new_code) OR tries > 10;
    tries := tries + 1;
  END LOOP;

  INSERT INTO public.certificates (code, serial, product_id, product_name, status, notes)
  VALUES (
    new_code,
    to_char(now(), 'YYYY') || '-' || upper(substr(replace(NEW.id::text, '-', ''), 1, 6)),
    NEW.id,
    NEW.name,
    'active',
    'Auto-issued when the product was created.'
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS products_issue_certificate ON public.products;
CREATE TRIGGER products_issue_certificate
  AFTER INSERT ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.products_issue_certificate();

INSERT INTO public.certificates (code, serial, product_id, product_name, status, notes)
SELECT public.gen_certificate_code(),
       to_char(now(), 'YYYY') || '-' || upper(substr(replace(p.id::text, '-', ''), 1, 6)),
       p.id, p.name, 'active', 'Auto-issued backfill.'
FROM public.products p
WHERE NOT EXISTS (SELECT 1 FROM public.certificates c WHERE c.product_id = p.id);
REVOKE EXECUTE ON FUNCTION public.products_issue_certificate() FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.gen_certificate_code() FROM anon, authenticated, public;
-- 1. Ads: stop exposing advertiser contact details publicly
DROP POLICY IF EXISTS "ads public read live" ON public.ads;

CREATE OR REPLACE VIEW public.ads_public
WITH (security_invoker = off) AS
SELECT id, title, body, image_url, target_url, placement, starts_at, ends_at
FROM public.ads
WHERE status = 'approved'
  AND payment_status = 'paid'
  AND (starts_at IS NULL OR starts_at <= now())
  AND (ends_at IS NULL OR ends_at > now());

GRANT SELECT ON public.ads_public TO anon, authenticated;

-- 2. Couriers: hide phone numbers from the public
DROP POLICY IF EXISTS "couriers public read" ON public.couriers;

CREATE OR REPLACE VIEW public.couriers_public
WITH (security_invoker = off) AS
SELECT id, name, kind, active
FROM public.couriers
WHERE active = true;

GRANT SELECT ON public.couriers_public TO anon, authenticated;

-- 3. Lock down security definer helpers that end users must never call
REVOKE ALL ON FUNCTION public.gen_certificate_code() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.products_issue_certificate() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.touch_updated_at() FROM PUBLIC, anon, authenticated;

-- 4. SEO configuration
CREATE TABLE IF NOT EXISTS public.seo_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  default_title text NOT NULL DEFAULT 'KROKO DILE â€” Luxury Leather Bags in Kenya',
  title_suffix text DEFAULT ' | KROKO DILE',
  default_description text NOT NULL DEFAULT 'Hand-finished luxury leather bags for men and women. M-Pesa checkout and countrywide delivery in Kenya.',
  default_keywords text DEFAULT 'luxury bags Kenya, leather handbags Nairobi, men bags Kenya, women handbags',
  og_image_url text,
  canonical_base_url text,
  google_site_verification text,
  bing_site_verification text,
  robots_extra text,
  twitter_handle text,
  organization_name text DEFAULT 'KROKO DILE',
  organization_logo_url text,
  sitemap_enabled boolean NOT NULL DEFAULT true,
  indexing_enabled boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT ON public.seo_settings TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.seo_settings TO authenticated;
GRANT ALL ON public.seo_settings TO service_role;
ALTER TABLE public.seo_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "seo settings public read" ON public.seo_settings FOR SELECT USING (true);
CREATE POLICY "seo settings admin write" ON public.seo_settings FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE TRIGGER seo_settings_touch BEFORE UPDATE ON public.seo_settings
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

INSERT INTO public.seo_settings (id) SELECT gen_random_uuid()
WHERE NOT EXISTS (SELECT 1 FROM public.seo_settings);

-- 5. Per-page SEO mapping (sitemap + meta overrides)
CREATE TABLE IF NOT EXISTS public.seo_pages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  path text NOT NULL UNIQUE,
  label text NOT NULL,
  title text,
  description text,
  keywords text,
  priority numeric NOT NULL DEFAULT 0.6,
  changefreq text NOT NULL DEFAULT 'weekly',
  in_sitemap boolean NOT NULL DEFAULT true,
  indexed boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT ON public.seo_pages TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.seo_pages TO authenticated;
GRANT ALL ON public.seo_pages TO service_role;
ALTER TABLE public.seo_pages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "seo pages public read" ON public.seo_pages FOR SELECT USING (true);
CREATE POLICY "seo pages admin write" ON public.seo_pages FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE TRIGGER seo_pages_touch BEFORE UPDATE ON public.seo_pages
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

INSERT INTO public.seo_pages (path, label, title, description, priority, changefreq, sort_order) VALUES
  ('/', 'Home', 'KROKO DILE â€” Luxury Leather Bags for Men & Women in Kenya', 'Hand-finished luxury bags from Nairobi. Pay with M-Pesa, delivered to every county in Kenya.', 1.0, 'daily', 1),
  ('/shop', 'Shop', 'Shop Luxury Leather Bags â€” KROKO DILE', 'Browse handcrafted leather bags for men and women. Filter by category, price and material.', 0.9, 'daily', 2),
  ('/verify', 'Verify authenticity', 'Verify Your KROKO DILE Authenticity Certificate', 'Scan or enter your certificate code to confirm your bag is a genuine KROKO DILE piece.', 0.7, 'monthly', 3),
  ('/track', 'Track order', 'Track Your KROKO DILE Order', 'Track your order with the email and phone number used at checkout.', 0.6, 'weekly', 4),
  ('/advertise', 'Advertise', 'Advertise on KROKO DILE', 'Buy a banner placement on Kenya''s luxury leather store.', 0.4, 'monthly', 5),
  ('/terms', 'Terms & Policies', 'Terms, Privacy & Delivery Policy â€” KROKO DILE', 'Our terms of sale, privacy policy, delivery, returns and payment terms.', 0.3, 'yearly', 6)
ON CONFLICT (path) DO NOTHING;

-- 6. FAQ content for search engines (FAQPage rich results)
CREATE TABLE IF NOT EXISTS public.faqs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question text NOT NULL,
  answer text NOT NULL,
  category text NOT NULL DEFAULT 'general',
  sort_order integer NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT ON public.faqs TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.faqs TO authenticated;
GRANT ALL ON public.faqs TO service_role;
ALTER TABLE public.faqs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "faqs public read" ON public.faqs FOR SELECT USING (active = true);
CREATE POLICY "faqs admin write" ON public.faqs FOR ALL TO authenticated
  USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE TRIGGER faqs_touch BEFORE UPDATE ON public.faqs
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

INSERT INTO public.faqs (question, answer, category, sort_order) VALUES
  ('Are KROKO DILE bags genuine leather?', 'Yes. Every bag is cut and stitched by hand from full-grain leather in Nairobi, and ships with a unique authenticity certificate you can verify online.', 'product', 1),
  ('How do I pay?', 'Checkout uses M-Pesa Express (STK push). Enter your phone number, approve the prompt, and your receipt is generated instantly. If a payment fails you can retry from your order page.', 'payment', 2),
  ('Do you deliver outside Nairobi?', 'We deliver to every county, sub-county and ward in Kenya through our courier and matatu SACCO partners. Shipping fees are shown at checkout.', 'delivery', 3),
  ('How long does delivery take?', 'Nairobi orders arrive within 24-48 hours. Upcountry deliveries typically take 2-4 working days depending on the courier.', 'delivery', 4),
  ('How do I verify my bag is original?', 'Scan the QR code on your authenticity card, or enter the KD- code on our Verify page. You will see the buyer name, order and payment date.', 'authenticity', 5),
  ('Can I return or exchange a bag?', 'Unused bags in original packaging can be exchanged within 7 days of delivery. Contact us with your order code to arrange it.', 'returns', 6)
ON CONFLICT DO NOTHING;

-- 7. Storage: scope public media reads to public content prefixes only
DROP POLICY IF EXISTS "media public read" ON storage.objects;
CREATE POLICY "media public prefixes read" ON storage.objects FOR SELECT TO anon, authenticated
USING (
  bucket_id = 'media'
  AND (storage.foldername(name))[1] IN ('products', 'branding', 'ads', 'categories', 'public')
);
DROP VIEW IF EXISTS public.ads_public;
DROP VIEW IF EXISTS public.couriers_public;

-- Ads: public may read live adverts, but only the display columns (no email/phone)
REVOKE SELECT ON public.ads FROM anon;
GRANT SELECT (id, title, body, image_url, target_url, placement, starts_at, ends_at, status, payment_status)
  ON public.ads TO anon;
CREATE POLICY "ads public read live" ON public.ads FOR SELECT TO anon
USING (status = 'approved' AND payment_status = 'paid' AND (ends_at IS NULL OR ends_at > now()));

-- Couriers: public may read the directory, but not phone numbers
REVOKE SELECT ON public.couriers FROM anon, authenticated;
GRANT SELECT (id, name, kind, active, created_at) ON public.couriers TO anon;
GRANT SELECT (id, name, kind, active, created_at, notes, phone) ON public.couriers TO authenticated;
CREATE POLICY "couriers public read" ON public.couriers FOR SELECT TO anon USING (active = true);
CREATE POLICY "couriers staff read" ON public.couriers FOR SELECT TO authenticated USING (true);
