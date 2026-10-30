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
