# Meliora

Flask + MySQL. The database sets itself up: on start, `app.py` creates the `meliora` database and
all tables (from `schema.sql`) if they are missing, then seeds the skin types, brands and the
oily-skin routine on first run.

## Run it
1. Start MySQL 8 (or MariaDB).
2. `cp .env.example .env` and put your MySQL password in `DB_PASSWORD`.
3. `pip install -r requirements.txt`
4. `python app.py`  →  http://127.0.0.1:5000

Demo login: `demo@meliora.dev` / `DemoPass123` (set `SEED_DEMO_DATA=false` to skip it).
Re-seed the catalogue any time with `python reset_db.py`.

## Tables
| Table | Purpose |
|---|---|
| skin_types, skin_type_details | Normal/Oily/Dry/Combination/Sensitive with signs, concerns, essential products |
| brands, brand_tags | Brand directory (tier, rating, hero product, "best for" tags) |
| skin_type_brands | Which brands are recommended for which skin type |
| routine_templates, routine_steps | AM/PM routines (oily is seeded) |
| users | Accounts; `skin_type` is filled in when Mili detects it |
| chat_messages, saved_routines | Per-user chat history and saved routines |
| saved_brands | Brands a user has favourited |

## API
`/api/register` `/api/login` `/api/logout` `/api/me` `/api/chat` `/api/chat/history`
`/api/routines` (GET/POST) · `/api/brands[?tier=Luxury]` · `/api/skin-types`
`/api/routine-templates/<skin>` · `/api/favorites` (GET) · `/api/favorites/<brand-slug>` (POST/DELETE)
