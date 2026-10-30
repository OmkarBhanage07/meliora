-- Meliora database schema (MySQL 8+).
-- Applied automatically when the app starts; every statement is safe to run more than once.
-- You can also import it by hand:  mysql -u root -p < schema.sql

CREATE DATABASE IF NOT EXISTS meliora CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE meliora;

-- ---------- catalogue: skin types ----------

CREATE TABLE IF NOT EXISTS skin_types (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name         VARCHAR(30)  NOT NULL UNIQUE,
  slug         VARCHAR(30)  NOT NULL UNIQUE,
  icon         VARCHAR(8)   NOT NULL,
  description  VARCHAR(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS skin_type_details (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  skin_type_id  INT UNSIGNED NOT NULL,
  kind          ENUM('sign','concern','essential_product') NOT NULL,
  position      TINYINT UNSIGNED NOT NULL,
  text          VARCHAR(120) NOT NULL,
  CONSTRAINT fk_details_skin FOREIGN KEY (skin_type_id) REFERENCES skin_types(id) ON DELETE CASCADE,
  INDEX idx_details_skin_kind (skin_type_id, kind, position)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- catalogue: brands ----------

CREATE TABLE IF NOT EXISTS brands (
  id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name              VARCHAR(60)  NOT NULL UNIQUE,
  slug              VARCHAR(60)  NOT NULL UNIQUE,
  tier              ENUM('Luxury','Premium','Accessible') NOT NULL,
  category          ENUM('Skincare','Makeup') NOT NULL,
  rating            DECIMAL(2,1) NOT NULL,
  tagline           VARCHAR(120) NOT NULL,
  hero_product      VARCHAR(120) NOT NULL,
  price_level       TINYINT UNSIGNED NOT NULL COMMENT '1 ($) to 5 ($$$$$)',
  bg_color          CHAR(7)      NOT NULL,
  accent_color      CHAR(7)      NOT NULL,
  show_in_directory BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_brands_tier (tier)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS brand_tags (
  brand_id  INT UNSIGNED NOT NULL,
  position  TINYINT UNSIGNED NOT NULL,
  tag       VARCHAR(60) NOT NULL COMMENT 'the "Best for" chips',
  PRIMARY KEY (brand_id, position),
  CONSTRAINT fk_tags_brand FOREIGN KEY (brand_id) REFERENCES brands(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS skin_type_brands (
  skin_type_id  INT UNSIGNED NOT NULL,
  brand_id      INT UNSIGNED NOT NULL,
  position      TINYINT UNSIGNED NOT NULL,
  PRIMARY KEY (skin_type_id, brand_id),
  CONSTRAINT fk_stb_skin  FOREIGN KEY (skin_type_id) REFERENCES skin_types(id) ON DELETE CASCADE,
  CONSTRAINT fk_stb_brand FOREIGN KEY (brand_id)     REFERENCES brands(id)     ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- catalogue: routine templates ----------

CREATE TABLE IF NOT EXISTS routine_templates (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  skin_type_id  INT UNSIGNED NOT NULL,
  period        ENUM('am','pm') NOT NULL,
  subtitle      VARCHAR(80) NOT NULL,
  duration      VARCHAR(20) NOT NULL,
  UNIQUE KEY uq_template (skin_type_id, period),
  CONSTRAINT fk_templates_skin FOREIGN KEY (skin_type_id) REFERENCES skin_types(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS routine_steps (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  template_id  INT UNSIGNED NOT NULL,
  position     TINYINT UNSIGNED NOT NULL,
  step_name    VARCHAR(80)  NOT NULL,
  brand_name   VARCHAR(60)  NOT NULL,
  duration     VARCHAR(20)  NOT NULL,
  product      VARCHAR(120) NOT NULL,
  why          VARCHAR(255) NOT NULL,
  tip          VARCHAR(255) NOT NULL,
  CONSTRAINT fk_steps_template FOREIGN KEY (template_id) REFERENCES routine_templates(id) ON DELETE CASCADE,
  INDEX idx_steps_template (template_id, position)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- users and their data ----------

CREATE TABLE IF NOT EXISTS users (
  id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name           VARCHAR(100) NOT NULL,
  email          VARCHAR(191) NOT NULL UNIQUE,
  password_hash  VARCHAR(255) NOT NULL,
  skin_type      VARCHAR(30)  NULL COMMENT 'slug of skin_types, filled in when Mili detects it',
  created_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_users_skin FOREIGN KEY (skin_type) REFERENCES skin_types(slug) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS chat_messages (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id     INT UNSIGNED NOT NULL,
  role        ENUM('user','bot') NOT NULL,
  content     TEXT NOT NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_chat_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_chat_user (user_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS saved_routines (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id     INT UNSIGNED NOT NULL,
  title       VARCHAR(150) NOT NULL,
  content     TEXT NOT NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_routines_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS saved_brands (
  user_id     INT UNSIGNED NOT NULL,
  brand_id    INT UNSIGNED NOT NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, brand_id),
  CONSTRAINT fk_saved_user  FOREIGN KEY (user_id)  REFERENCES users(id)  ON DELETE CASCADE,
  CONSTRAINT fk_saved_brand FOREIGN KEY (brand_id) REFERENCES brands(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------- seed data ----------
SET NAMES utf8mb4;

INSERT INTO skin_types (name, slug, icon, description) VALUES
  ('Normal', 'normal', '✨', 'Balanced oil and moisture with few concerns.'),
  ('Oily', 'oily', '💧', 'Excess sebum production leads to shine, enlarged pores, and a higher tendency for breakouts and blackheads.'),
  ('Dry', 'dry', '🌸', 'Low oil and water levels cause tightness, flaking, and dullness.'),
  ('Combination', 'combination', '🌿', 'An oily T-zone with normal or dry cheeks.'),
  ('Sensitive', 'sensitive', '🌷', 'Reacts easily with redness, stinging, or itching.');

INSERT INTO brands (name, slug, tier, category, rating, tagline, hero_product, price_level, bg_color, accent_color, show_in_directory) VALUES
  ('La Mer', 'la-mer', 'Luxury', 'Skincare', 4.9, 'The Science of the Sea', 'Crème de la Mer', 5, '#eef2f8', '#1a1512', 1),
  ('SK-II', 'sk-ii', 'Luxury', 'Skincare', 4.8, 'Unlock Radiant Skin', 'Facial Treatment Essence', 5, '#fdeeee', '#c2185b', 1),
  ('Tatcha', 'tatcha', 'Premium', 'Skincare', 4.8, 'Japanese Beauty Rituals', 'The Water Cream', 4, '#fcf0f7', '#c2185b', 1),
  ('Drunk Elephant', 'drunk-elephant', 'Premium', 'Skincare', 4.7, 'Clean, Compatible Beauty', 'T.L.C. Framboos Serum', 4, '#fdf1e6', '#c2410c', 1),
  ('NARS', 'nars', 'Premium', 'Makeup', 4.8, 'Bold, Unapologetic Beauty', 'Sheer Glow Foundation', 3, '#f1f1f3', '#1a1512', 1),
  ('Charlotte Tilbury', 'charlotte-tilbury', 'Premium', 'Makeup', 4.9, 'Hollywood Glamour', 'Magic Cream', 3, '#fdeeee', '#c2185b', 1),
  ('The Ordinary', 'the-ordinary', 'Accessible', 'Skincare', 4.6, 'Clinical Formulations', 'Niacinamide 10% + Zinc 1%', 1, '#f3f3f3', '#1a1512', 1),
  ('CeraVe', 'cerave', 'Accessible', 'Skincare', 4.7, 'Developed with Dermatologists', 'Moisturising Cream', 2, '#eaf2fd', '#1d4ed8', 1),
  ('Paula''s Choice', 'paula-s-choice', 'Accessible', 'Skincare', 4.7, 'Science-Backed Skincare', '2% BHA Liquid Exfoliant', 3, '#f3f3f3', '#1a1512', 0);

INSERT INTO brand_tags (brand_id, position, tag) VALUES
  ((SELECT id FROM brands WHERE name='La Mer'), 0, 'Dry skin'),
  ((SELECT id FROM brands WHERE name='La Mer'), 1, 'Anti-aging'),
  ((SELECT id FROM brands WHERE name='La Mer'), 2, 'Barrier repair'),
  ((SELECT id FROM brands WHERE name='SK-II'), 0, 'All skin types'),
  ((SELECT id FROM brands WHERE name='SK-II'), 1, 'Brightening'),
  ((SELECT id FROM brands WHERE name='SK-II'), 2, 'Anti-aging'),
  ((SELECT id FROM brands WHERE name='Tatcha'), 0, 'Normal skin'),
  ((SELECT id FROM brands WHERE name='Tatcha'), 1, 'Sensitive skin'),
  ((SELECT id FROM brands WHERE name='Tatcha'), 2, 'Hydration'),
  ((SELECT id FROM brands WHERE name='Drunk Elephant'), 0, 'Combination skin'),
  ((SELECT id FROM brands WHERE name='Drunk Elephant'), 1, 'Brightening'),
  ((SELECT id FROM brands WHERE name='Drunk Elephant'), 2, 'Active ingredients'),
  ((SELECT id FROM brands WHERE name='NARS'), 0, 'All skin tones'),
  ((SELECT id FROM brands WHERE name='NARS'), 1, 'Long-wear'),
  ((SELECT id FROM brands WHERE name='NARS'), 2, 'Editorial looks'),
  ((SELECT id FROM brands WHERE name='Charlotte Tilbury'), 0, 'Dry skin'),
  ((SELECT id FROM brands WHERE name='Charlotte Tilbury'), 1, 'Dewy finish'),
  ((SELECT id FROM brands WHERE name='Charlotte Tilbury'), 2, 'Natural glam'),
  ((SELECT id FROM brands WHERE name='The Ordinary'), 0, 'Oily skin'),
  ((SELECT id FROM brands WHERE name='The Ordinary'), 1, 'Beginners'),
  ((SELECT id FROM brands WHERE name='The Ordinary'), 2, 'Active ingredients'),
  ((SELECT id FROM brands WHERE name='CeraVe'), 0, 'Sensitive skin'),
  ((SELECT id FROM brands WHERE name='CeraVe'), 1, 'Dry skin'),
  ((SELECT id FROM brands WHERE name='CeraVe'), 2, 'Barrier repair'),
  ((SELECT id FROM brands WHERE name='Paula''s Choice'), 0, 'Oily skin'),
  ((SELECT id FROM brands WHERE name='Paula''s Choice'), 1, 'Acne-prone skin'),
  ((SELECT id FROM brands WHERE name='Paula''s Choice'), 2, 'Exfoliation');

INSERT INTO skin_type_details (skin_type_id, kind, position, text) VALUES
  ((SELECT id FROM skin_types WHERE name='Normal'), 'sign', 0, 'Even texture'),
  ((SELECT id FROM skin_types WHERE name='Normal'), 'sign', 1, 'Small pores'),
  ((SELECT id FROM skin_types WHERE name='Normal'), 'sign', 2, 'Rarely breaks out'),
  ((SELECT id FROM skin_types WHERE name='Normal'), 'sign', 3, 'Comfortable all day'),
  ((SELECT id FROM skin_types WHERE name='Normal'), 'concern', 0, 'Maintaining balance'),
  ((SELECT id FROM skin_types WHERE name='Normal'), 'concern', 1, 'Sun protection'),
  ((SELECT id FROM skin_types WHERE name='Normal'), 'concern', 2, 'Prevention'),
  ((SELECT id FROM skin_types WHERE name='Normal'), 'essential_product', 0, 'Gentle gel cleanser'),
  ((SELECT id FROM skin_types WHERE name='Normal'), 'essential_product', 1, 'Vitamin C serum'),
  ((SELECT id FROM skin_types WHERE name='Normal'), 'essential_product', 2, 'Light moisturizer with SPF'),
  ((SELECT id FROM skin_types WHERE name='Oily'), 'sign', 0, 'Shiny forehead and nose'),
  ((SELECT id FROM skin_types WHERE name='Oily'), 'sign', 1, 'Enlarged pores'),
  ((SELECT id FROM skin_types WHERE name='Oily'), 'sign', 2, 'Frequent breakouts'),
  ((SELECT id FROM skin_types WHERE name='Oily'), 'sign', 3, 'Thick texture'),
  ((SELECT id FROM skin_types WHERE name='Oily'), 'concern', 0, 'Oil control'),
  ((SELECT id FROM skin_types WHERE name='Oily'), 'concern', 1, 'Minimizing pores'),
  ((SELECT id FROM skin_types WHERE name='Oily'), 'concern', 2, 'Preventing acne'),
  ((SELECT id FROM skin_types WHERE name='Oily'), 'concern', 3, 'Mattifying'),
  ((SELECT id FROM skin_types WHERE name='Oily'), 'essential_product', 0, 'Foaming salicylic cleanser'),
  ((SELECT id FROM skin_types WHERE name='Oily'), 'essential_product', 1, 'Niacinamide serum'),
  ((SELECT id FROM skin_types WHERE name='Oily'), 'essential_product', 2, 'Oil-free SPF moisturizer'),
  ((SELECT id FROM skin_types WHERE name='Dry'), 'sign', 0, 'Tight after washing'),
  ((SELECT id FROM skin_types WHERE name='Dry'), 'sign', 1, 'Flaky patches'),
  ((SELECT id FROM skin_types WHERE name='Dry'), 'sign', 2, 'Dull complexion'),
  ((SELECT id FROM skin_types WHERE name='Dry'), 'sign', 3, 'Fine lines show easily'),
  ((SELECT id FROM skin_types WHERE name='Dry'), 'concern', 0, 'Hydration'),
  ((SELECT id FROM skin_types WHERE name='Dry'), 'concern', 1, 'Barrier repair'),
  ((SELECT id FROM skin_types WHERE name='Dry'), 'concern', 2, 'Flaking'),
  ((SELECT id FROM skin_types WHERE name='Dry'), 'concern', 3, 'Dullness'),
  ((SELECT id FROM skin_types WHERE name='Dry'), 'essential_product', 0, 'Cream cleanser'),
  ((SELECT id FROM skin_types WHERE name='Dry'), 'essential_product', 1, 'Hyaluronic acid serum'),
  ((SELECT id FROM skin_types WHERE name='Dry'), 'essential_product', 2, 'Rich ceramide moisturizer'),
  ((SELECT id FROM skin_types WHERE name='Combination'), 'sign', 0, 'Shiny T-zone'),
  ((SELECT id FROM skin_types WHERE name='Combination'), 'sign', 1, 'Dry cheeks'),
  ((SELECT id FROM skin_types WHERE name='Combination'), 'sign', 2, 'Mixed pore size'),
  ((SELECT id FROM skin_types WHERE name='Combination'), 'sign', 3, 'Occasional breakouts'),
  ((SELECT id FROM skin_types WHERE name='Combination'), 'concern', 0, 'Balancing zones'),
  ((SELECT id FROM skin_types WHERE name='Combination'), 'concern', 1, 'Pore care'),
  ((SELECT id FROM skin_types WHERE name='Combination'), 'concern', 2, 'Hydration'),
  ((SELECT id FROM skin_types WHERE name='Combination'), 'concern', 3, 'Texture'),
  ((SELECT id FROM skin_types WHERE name='Combination'), 'essential_product', 0, 'Gentle gel cleanser'),
  ((SELECT id FROM skin_types WHERE name='Combination'), 'essential_product', 1, 'Niacinamide serum'),
  ((SELECT id FROM skin_types WHERE name='Combination'), 'essential_product', 2, 'Light gel-cream moisturizer'),
  ((SELECT id FROM skin_types WHERE name='Sensitive'), 'sign', 0, 'Redness'),
  ((SELECT id FROM skin_types WHERE name='Sensitive'), 'sign', 1, 'Stinging with products'),
  ((SELECT id FROM skin_types WHERE name='Sensitive'), 'sign', 2, 'Easily irritated'),
  ((SELECT id FROM skin_types WHERE name='Sensitive'), 'sign', 3, 'Visible flushing'),
  ((SELECT id FROM skin_types WHERE name='Sensitive'), 'concern', 0, 'Calming'),
  ((SELECT id FROM skin_types WHERE name='Sensitive'), 'concern', 1, 'Barrier repair'),
  ((SELECT id FROM skin_types WHERE name='Sensitive'), 'concern', 2, 'Redness'),
  ((SELECT id FROM skin_types WHERE name='Sensitive'), 'concern', 3, 'Fragrance-free care'),
  ((SELECT id FROM skin_types WHERE name='Sensitive'), 'essential_product', 0, 'Fragrance-free cleanser'),
  ((SELECT id FROM skin_types WHERE name='Sensitive'), 'essential_product', 1, 'Soothing serum'),
  ((SELECT id FROM skin_types WHERE name='Sensitive'), 'essential_product', 2, 'Ceramide moisturizer');

INSERT INTO skin_type_brands (skin_type_id, brand_id, position) VALUES
  ((SELECT id FROM skin_types WHERE name='Normal'), (SELECT id FROM brands WHERE name='CeraVe'), 0),
  ((SELECT id FROM skin_types WHERE name='Normal'), (SELECT id FROM brands WHERE name='The Ordinary'), 1),
  ((SELECT id FROM skin_types WHERE name='Normal'), (SELECT id FROM brands WHERE name='La Mer'), 2),
  ((SELECT id FROM skin_types WHERE name='Oily'), (SELECT id FROM brands WHERE name='The Ordinary'), 0),
  ((SELECT id FROM skin_types WHERE name='Oily'), (SELECT id FROM brands WHERE name='Paula''s Choice'), 1),
  ((SELECT id FROM skin_types WHERE name='Oily'), (SELECT id FROM brands WHERE name='CeraVe'), 2),
  ((SELECT id FROM skin_types WHERE name='Dry'), (SELECT id FROM brands WHERE name='CeraVe'), 0),
  ((SELECT id FROM skin_types WHERE name='Dry'), (SELECT id FROM brands WHERE name='La Mer'), 1),
  ((SELECT id FROM skin_types WHERE name='Dry'), (SELECT id FROM brands WHERE name='Tatcha'), 2),
  ((SELECT id FROM skin_types WHERE name='Combination'), (SELECT id FROM brands WHERE name='Drunk Elephant'), 0),
  ((SELECT id FROM skin_types WHERE name='Combination'), (SELECT id FROM brands WHERE name='The Ordinary'), 1),
  ((SELECT id FROM skin_types WHERE name='Combination'), (SELECT id FROM brands WHERE name='Tatcha'), 2),
  ((SELECT id FROM skin_types WHERE name='Sensitive'), (SELECT id FROM brands WHERE name='CeraVe'), 0),
  ((SELECT id FROM skin_types WHERE name='Sensitive'), (SELECT id FROM brands WHERE name='Tatcha'), 1),
  ((SELECT id FROM skin_types WHERE name='Sensitive'), (SELECT id FROM brands WHERE name='La Mer'), 2);

INSERT INTO routine_templates (skin_type_id, period, subtitle, duration) VALUES
  ((SELECT id FROM skin_types WHERE name='Oily'), 'am', 'Morning — for oily skin', '5–8 min'),
  ((SELECT id FROM skin_types WHERE name='Oily'), 'pm', 'Evening — for oily skin', '6–9 min');

INSERT INTO routine_steps (template_id, position, step_name, brand_name, duration, product, why, tip) VALUES
  ((SELECT t.id FROM routine_templates t JOIN skin_types k ON k.id=t.skin_type_id WHERE k.name='Oily' AND t.period='am'), 0, 'Gentle Foaming Cleanser', 'CeraVe', '60 sec', 'Foaming Facial Cleanser', 'Remove overnight buildup and excess oil without stripping', 'Use lukewarm water — hot water strips your moisture barrier.'),
  ((SELECT t.id FROM routine_templates t JOIN skin_types k ON k.id=t.skin_type_id WHERE k.name='Oily' AND t.period='am'), 1, 'Balancing Toner', 'Paula''s Choice', '30 sec', 'Skin Balancing Toner', 'Prep skin so serums absorb evenly', 'Pat it in with clean hands rather than a cotton pad.'),
  ((SELECT t.id FROM routine_templates t JOIN skin_types k ON k.id=t.skin_type_id WHERE k.name='Oily' AND t.period='am'), 2, 'Niacinamide Serum', 'The Ordinary', '30 sec', 'Niacinamide 10% + Zinc 1%', 'Regulate oil and minimize the look of pores', 'Start every other day if your skin is new to niacinamide.'),
  ((SELECT t.id FROM routine_templates t JOIN skin_types k ON k.id=t.skin_type_id WHERE k.name='Oily' AND t.period='am'), 3, 'Oil-Free Moisturizer', 'Neutrogena', '30 sec', 'Hydro Boost Water Gel', 'Hydrate without adding shine', 'Oily skin still needs moisture — do not skip it.'),
  ((SELECT t.id FROM routine_templates t JOIN skin_types k ON k.id=t.skin_type_id WHERE k.name='Oily' AND t.period='am'), 4, 'Sunscreen SPF 50', 'EltaMD', '30 sec', 'UV Clear Broad-Spectrum SPF 46', 'Protect against UV damage and dark marks', 'Apply two finger-lengths and reapply every two hours outdoors.'),
  ((SELECT t.id FROM routine_templates t JOIN skin_types k ON k.id=t.skin_type_id WHERE k.name='Oily' AND t.period='pm'), 0, 'Oil Cleanser', 'Banila Co', '60 sec', 'Clean It Zero', 'Melt off sunscreen and makeup', 'Massage onto dry skin before adding water.'),
  ((SELECT t.id FROM routine_templates t JOIN skin_types k ON k.id=t.skin_type_id WHERE k.name='Oily' AND t.period='pm'), 1, 'Foaming Cleanser', 'CeraVe', '60 sec', 'Foaming Facial Cleanser', 'Second cleanse to clear remaining residue', 'Rinse thoroughly with lukewarm water.'),
  ((SELECT t.id FROM routine_templates t JOIN skin_types k ON k.id=t.skin_type_id WHERE k.name='Oily' AND t.period='pm'), 2, 'Salicylic Acid Exfoliant', 'Paula''s Choice', '30 sec', '2% BHA Liquid Exfoliant', 'Unclog pores and smooth texture', 'Use 2–3 nights a week, then build up.'),
  ((SELECT t.id FROM routine_templates t JOIN skin_types k ON k.id=t.skin_type_id WHERE k.name='Oily' AND t.period='pm'), 3, 'Gel Moisturizer', 'Neutrogena', '30 sec', 'Hydro Boost Water Gel', 'Lock in hydration overnight', 'Use a thin layer so pores stay clear.');

SELECT 'Done' AS status, (SELECT COUNT(*) FROM brands) AS brands, (SELECT COUNT(*) FROM skin_types) AS skin_types, (SELECT COUNT(*) FROM routine_steps) AS routine_steps;
