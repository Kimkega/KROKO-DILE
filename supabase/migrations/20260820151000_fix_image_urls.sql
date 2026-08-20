-- Migration to fix stored image URLs in database tables to use public storage endpoint
UPDATE public.product_images 
SET url = REPLACE(url, '/storage/v1/object/media/', '/storage/v1/object/public/media/') 
WHERE url LIKE '%/storage/v1/object/media/%';

UPDATE public.categories 
SET image_url = REPLACE(image_url, '/storage/v1/object/media/', '/storage/v1/object/public/media/') 
WHERE image_url LIKE '%/storage/v1/object/media/%';

UPDATE public.site_settings 
SET logo_url = REPLACE(logo_url, '/storage/v1/object/media/', '/storage/v1/object/public/media/') 
WHERE logo_url LIKE '%/storage/v1/object/media/%';

UPDATE public.ads 
SET image_url = REPLACE(image_url, '/storage/v1/object/media/', '/storage/v1/object/public/media/') 
WHERE image_url LIKE '%/storage/v1/object/media/%';
