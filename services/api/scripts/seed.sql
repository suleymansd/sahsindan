BEGIN;

INSERT INTO users (email, phone, password_hash, role, status, trust_score, response_time_minutes_avg, last_login_at, created_at)
VALUES
  ('admin@trustmarket.local', '5550000001', '$2y$12$t0iRZYhpfo5O/miJ3SgGS.nc3HEkFU5l/N3ElB8bdGO1mpRKdvxz6', 'ADMIN'::userrole, 'ACTIVE'::userstatus, 70, 30, NOW() - INTERVAL '1 day', NOW()),
  ('mod@trustmarket.local', '5550000002', '$2y$12$Wr2uK6cfO1uMb7/cDgNmX.j.2Y.FzMYMyCNUGFQiRJh71fOoyLY7G', 'MODERATOR'::userrole, 'ACTIVE'::userstatus, 60, 60, NOW() - INTERVAL '2 days', NOW()),
  ('user1@trustmarket.local', '5550000003', '$2y$12$RGhVHFJ7zT4HHSPltXJDHO/BBg0RtflN5s0jX7vz9E/L64bFxziA6', 'USER_VERIFIED'::userrole, 'ACTIVE'::userstatus, 50, 120, NOW() - INTERVAL '3 days', NOW()),
  ('seller1@trustmarket.local', '5550000004', '$2y$12$RGhVHFJ7zT4HHSPltXJDHO/BBg0RtflN5s0jX7vz9E/L64bFxziA6', 'USER_VERIFIED'::userrole, 'ACTIVE'::userstatus, 50, 90, NOW() - INTERVAL '1 day', NOW()),
  ('pending@trustmarket.local', '5550000005', '$2y$12$RGhVHFJ7zT4HHSPltXJDHO/BBg0RtflN5s0jX7vz9E/L64bFxziA6', 'USER_PENDING'::userrole, 'ACTIVE'::userstatus, 0, NULL, NULL, NOW()),
  ('verified@test.com', '5550000099', '$2b$12$E2c956QmaMOHw9LGUkbAgOZMWpW1sHGmYwkqrV.nIf22llQ2XFrEC', 'USER_VERIFIED'::userrole, 'ACTIVE'::userstatus, 90, 20, NOW() - INTERVAL '1 day', NOW())
ON CONFLICT DO NOTHING;

INSERT INTO profiles (user_id, name, city, profession_category, profession_verified)
SELECT id, 'Admin', 'ISTANBUL', 'Operations', true FROM users WHERE email='admin@trustmarket.local'
ON CONFLICT (user_id) DO NOTHING;
INSERT INTO profiles (user_id, name, city, profession_category, profession_verified)
SELECT id, 'Moderator', 'ISTANBUL', 'Compliance', true FROM users WHERE email='mod@trustmarket.local'
ON CONFLICT (user_id) DO NOTHING;
INSERT INTO profiles (user_id, name, city, profession_category, profession_verified)
SELECT id, 'Aylin', 'ISTANBUL', 'Automotive', true FROM users WHERE email='user1@trustmarket.local'
ON CONFLICT (user_id) DO NOTHING;
INSERT INTO profiles (user_id, name, city, profession_category, profession_verified)
SELECT id, 'Mert', 'ISTANBUL', 'Automotive', true FROM users WHERE email='seller1@trustmarket.local'
ON CONFLICT (user_id) DO NOTHING;
INSERT INTO profiles (user_id, name, city, profession_category, profession_verified)
SELECT id, 'Kemal', 'ISTANBUL', NULL, false FROM users WHERE email='pending@trustmarket.local'
ON CONFLICT (user_id) DO NOTHING;
INSERT INTO profiles (user_id, name, city, profession_category, profession_verified)
SELECT id, 'Verified Demo', 'ISTANBUL', 'Automotive', true FROM users WHERE email='verified@test.com'
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO system_settings (stale_days, confirm_window_days, fees, city_lock)
SELECT 30, 7, '{"listing_fee":0}'::json, 'ISTANBUL'
WHERE NOT EXISTS (SELECT 1 FROM system_settings);

WITH seller AS (
  SELECT id AS seller_id FROM users WHERE email='seller1@trustmarket.local'
), series AS (
  SELECT generate_series(1,50) AS i
), brand_models AS (
  SELECT 
    unnest(ARRAY['Alfa Romeo','Audi','BMW','Chevrolet','Fiat','Ford','Honda','Hyundai','Mercedes','Nissan','Opel','Peugeot','Renault','Seat','Skoda','Toyota','Volkswagen','Volvo']) AS brand,
    unnest(ARRAY['Giulia','A4','3 Series','Cruze','Egea','Focus','Civic','i20','C200','Sentra','Corsa','308','Megane','Leon','Octavia','Corolla','Golf','S60']) AS model
)
INSERT INTO listings (state, stale_state, title, description, price, city, district, owner_id, last_confirmed_at, created_at, updated_at)
SELECT
  CASE
    WHEN i % 10 = 0 THEN 'SOLD'::listingstate
    WHEN i % 15 = 0 THEN 'ARCHIVED'::listingstate
    ELSE 'PUBLISHED'::listingstate
  END,
  CASE WHEN i % 20 = 0 THEN 'NEEDS_CONFIRMATION'::stalestate ELSE NULL END,
  bm.brand || ' ' || bm.model || ' ' || (2015 + (i % 9))::text,
  CASE 
    WHEN i % 3 = 0 THEN 'Sıfır ayarında, bakımlı, hasarsız araç. Tüm servis kayıtları mevcut.'
    WHEN i % 3 = 1 THEN 'Özenle kullanılmış, düzenli bakımlı. İkinci el piyasasında temiz araç.'
    ELSE 'Aile arabası, az kullanılmış. Garantili, ekspertizli.'
  END,
  300000 + (i * 15000) + ((i % 5) * 50000),
  'ISTANBUL',
  (ARRAY['Kadikoy','Besiktas','Sisli','Beyoglu','Uskudar','Maltepe','Bakirkoy','Atasehir'])[(i % 8) + 1],
  seller.seller_id,
  NOW() - ((i % 30) || ' days')::interval,
  NOW() - ((i % 30) || ' days')::interval,
  NOW() - ((i % 30) || ' days')::interval
FROM series, seller
CROSS JOIN LATERAL (
  SELECT brand, model FROM brand_models ORDER BY brand, model OFFSET (i % (SELECT count(*) FROM brand_models)) LIMIT 1
) bm
WHERE NOT EXISTS (SELECT 1 FROM listings);

WITH brand_models AS (
  SELECT
    row_number() OVER () AS idx,
    unnest(ARRAY['Alfa Romeo','Audi','BMW','Chevrolet','Fiat','Ford','Honda','Hyundai','Mercedes','Nissan','Opel','Peugeot','Renault','Seat','Skoda','Toyota','Volkswagen','Volvo']) AS brand,
    unnest(ARRAY['Giulia','A4','3 Series','Cruze','Egea','Focus','Civic','i20','C200','Sentra','Corsa','308','Megane','Leon','Octavia','Corolla','Golf','S60']) AS model
),
transmissions AS (SELECT unnest(ARRAY['Automatic','Manual']) AS t),
fuels AS (SELECT unnest(ARRAY['Gasoline','Diesel','Hybrid','Electric']) AS f),
colors AS (SELECT unnest(ARRAY['Black','White','Silver','Blue','Red','Grey','Green']) AS c),
listing_rows AS (
  SELECT l.id, row_number() OVER (ORDER BY l.id) AS rn
  FROM listings l
  LEFT JOIN car_details cd ON cd.listing_id = l.id
  WHERE cd.id IS NULL
)
INSERT INTO car_details (listing_id, brand, model, year, mileage, transmission, fuel, color, vin_optional)
SELECT
  l.id,
  bm.brand,
  bm.model,
  2015 + (l.rn % 9),
  20000 + (l.rn * 2000),
  t.t,
  f.f,
  c.c,
  'VIN' || lpad(l.id::text, 10, '0')
FROM listing_rows l
JOIN brand_models bm
  ON bm.idx = ((l.rn - 1) % (SELECT count(*) FROM brand_models)) + 1
CROSS JOIN LATERAL (SELECT t FROM transmissions ORDER BY random() LIMIT 1) t
CROSS JOIN LATERAL (SELECT f FROM fuels ORDER BY random() LIMIT 1) f
CROSS JOIN LATERAL (SELECT c FROM colors ORDER BY random() LIMIT 1) c;

INSERT INTO listing_photos (listing_id, s3_key, sort_order, created_at)
SELECT l.id, 'seed/listings/' || l.id || '/photo.png', 0, NOW()
FROM listings l
LEFT JOIN listing_photos p ON p.listing_id = l.id
WHERE p.id IS NULL;

WITH buyer AS (SELECT id AS buyer_id FROM users WHERE email='user1@trustmarket.local'),
     seller AS (SELECT id AS seller_id FROM users WHERE email='seller1@trustmarket.local'),
     listing AS (SELECT id AS listing_id FROM listings ORDER BY id LIMIT 1)
INSERT INTO threads (listing_id, buyer_id, seller_id, created_at, updated_at, last_message_at)
SELECT listing_id, buyer_id, seller_id, NOW(), NOW(), NOW()
FROM buyer, seller, listing
WHERE NOT EXISTS (SELECT 1 FROM threads);

INSERT INTO messages (thread_id, sender_id, body, created_at)
SELECT t.id, t.buyer_id, 'Merhaba, arac hala satilik mi?', NOW() - INTERVAL '2 hours'
FROM threads t
WHERE NOT EXISTS (SELECT 1 FROM messages);
INSERT INTO messages (thread_id, sender_id, body, created_at)
SELECT t.id, t.seller_id, 'Evet, bugun gorebilirsiniz.', NOW() - INTERVAL '90 minutes'
FROM threads t
WHERE (SELECT count(*) FROM messages) < 2;

WITH buyer AS (SELECT id AS buyer_id FROM users WHERE email='user1@trustmarket.local'),
     seller AS (SELECT id AS seller_id FROM users WHERE email='seller1@trustmarket.local'),
     listing AS (SELECT id AS listing_id FROM listings ORDER BY id LIMIT 1)
INSERT INTO appointments (listing_id, buyer_id, seller_id, status, scheduled_at, location, notes, created_at, updated_at)
SELECT listing_id, buyer_id, seller_id, 'ACCEPTED'::appointmentstatus, NOW() + INTERVAL '1 day', 'Kadikoy Sahil', 'Test drive planlandi.', NOW(), NOW()
FROM buyer, seller, listing
WHERE NOT EXISTS (SELECT 1 FROM appointments);

INSERT INTO appointment_events (appointment_id, actor_id, event_type, note, created_at)
SELECT a.id, a.seller_id, 'ACCEPTED', NULL, NOW()
FROM appointments a
WHERE NOT EXISTS (SELECT 1 FROM appointment_events);

INSERT INTO verification_requests (user_id, status, reviewer_id, reason, created_at, updated_at)
SELECT id, 'PENDING'::verificationstatus, NULL, NULL, NOW(), NOW()
FROM users WHERE email='pending@trustmarket.local'
AND NOT EXISTS (SELECT 1 FROM verification_requests WHERE user_id = (SELECT id FROM users WHERE email='pending@trustmarket.local'));

INSERT INTO verification_requests (user_id, status, reviewer_id, reason, created_at, updated_at)
SELECT id, 'APPROVED'::verificationstatus, NULL, NULL, NOW(), NOW()
FROM users WHERE email='verified@test.com'
AND NOT EXISTS (SELECT 1 FROM verification_requests WHERE user_id = (SELECT id FROM users WHERE email='verified@test.com'));

COMMIT;
