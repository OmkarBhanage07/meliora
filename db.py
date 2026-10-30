"""MySQL layer for Meliora: connects, creates the database and tables if missing, seeds the catalogue."""
import os
import re
import time

import mysql.connector
from mysql.connector import pooling, errorcode
from werkzeug.security import generate_password_hash

import seed_data as sd

SCHEMA_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "schema.sql")
_pool = None


def _cfg(with_database=True):
    cfg = dict(
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", "3306")),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", ""),
        charset="utf8mb4",
        connection_timeout=10,
    )
    if with_database:
        cfg["database"] = os.getenv("DB_NAME", "meliora")
    return cfg


def describe_error(err):
    """Turn a driver error into advice a person can act on."""
    cfg = _cfg()
    where = f"{cfg['host']}:{cfg['port']}"
    if getattr(err, "errno", None) == errorcode.ER_ACCESS_DENIED_ERROR:
        return f'MySQL rejected the login for user "{cfg["user"]}". Check DB_USER and DB_PASSWORD in your .env file.'
    if getattr(err, "errno", None) in (2003, 2005, 2013):
        return f"Could not reach MySQL at {where}. Is the MySQL service running, and are DB_HOST / DB_PORT correct?"
    return str(err)


def slugify(s):
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")


def _connect_server():
    """Connect without choosing a database, creating it if it does not exist yet."""
    conn = mysql.connector.connect(**_cfg(with_database=False))
    name = os.getenv("DB_NAME", "meliora").replace("`", "")
    cur = conn.cursor()
    cur.execute(f"CREATE DATABASE IF NOT EXISTS `{name}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
    conn.commit()
    cur.close()
    return conn


def get_conn():
    global _pool
    if _pool is None:
        _pool = pooling.MySQLConnectionPool(pool_name="meliora", pool_size=5, **_cfg())
    return _pool.get_connection()


def q(sql, args=(), one=False, write=False, many=False):
    """Run one query. write=True commits and returns lastrowid; many=True runs executemany."""
    conn = get_conn()
    cur = conn.cursor(dictionary=True)
    try:
        if many:
            cur.executemany(sql, args)
        else:
            cur.execute(sql, args)
        if write or many:
            conn.commit()
            return cur.lastrowid
        rows = cur.fetchall()
        return (rows[0] if rows else None) if one else rows
    finally:
        cur.close()
        conn.close()  # returns the connection to the pool


def apply_schema():
    text = open(SCHEMA_FILE, encoding="utf8").read()
    text = re.sub(r"^\s*--.*$", "", text, flags=re.M)
    statements = [s.strip() for s in re.split(r";\s*(?:\n|$)", text) if s.strip()]
    conn = get_conn()
    cur = conn.cursor()
    try:
        for st in statements:
            # CREATE DATABASE / USE are only there so schema.sql can be imported by hand.
            if re.match(r"(CREATE\s+DATABASE|USE)\b", st, re.I):
                continue
            cur.execute(st)
        conn.commit()
    finally:
        cur.close()
        conn.close()


def _add_routines(cur):
    """Insert any routine template (skin type + AM/PM) that is not in the database yet."""
    cur.execute("SELECT id, name FROM skin_types")
    skin_id = {n: i for i, n in cur.fetchall()}
    for (skin, period), (subtitle, duration, steps) in sd.ROUTINES.items():
        cur.execute("SELECT id FROM routine_templates WHERE skin_type_id=%s AND period=%s", (skin_id[skin], period))
        if cur.fetchone():
            continue
        cur.execute("INSERT INTO routine_templates (skin_type_id, period, subtitle, duration) VALUES (%s,%s,%s,%s)",
                    (skin_id[skin], period, subtitle, duration))
        tid = cur.lastrowid
        cur.executemany(
            "INSERT INTO routine_steps (template_id, position, step_name, brand_name, duration, product, why, tip)"
            " VALUES (%s,%s,%s,%s,%s,%s,%s,%s)", [(tid, i, *st) for i, st in enumerate(steps)])


def top_up_routines():
    conn = get_conn()
    cur = conn.cursor()
    try:
        _add_routines(cur)
        conn.commit()
    finally:
        cur.close()
        conn.close()


def seed_catalogue(reset=False):
    conn = get_conn()
    cur = conn.cursor()
    try:
        if reset:
            cur.execute("DELETE FROM brands")
            cur.execute("DELETE FROM skin_types")

        for name, icon, desc, *_ in sd.SKIN_TYPES:
            cur.execute("INSERT INTO skin_types (name, slug, icon, description) VALUES (%s,%s,%s,%s)",
                        (name, slugify(name), icon, desc))
        cur.execute("SELECT id, name FROM skin_types")
        skin_id = {n: i for i, n in cur.fetchall()}

        for b in sd.BRANDS:
            name, tier, cat, rating, tagline, hero, price, tags, bg, accent, show = b
            cur.execute(
                "INSERT INTO brands (name, slug, tier, category, rating, tagline, hero_product, price_level,"
                " bg_color, accent_color, show_in_directory) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)",
                (name, slugify(name), tier, cat, rating, tagline, hero, price, bg, accent, show))
            bid = cur.lastrowid
            cur.executemany("INSERT INTO brand_tags (brand_id, position, tag) VALUES (%s,%s,%s)",
                            [(bid, i, t) for i, t in enumerate(tags)])
        cur.execute("SELECT id, name FROM brands")
        brand_id = {n: i for i, n in cur.fetchall()}

        details, links = [], []
        for name, _icon, _desc, signs, concerns, products, brands in sd.SKIN_TYPES:
            sid = skin_id[name]
            details += [(sid, "sign", i, t) for i, t in enumerate(signs)]
            details += [(sid, "concern", i, t) for i, t in enumerate(concerns)]
            details += [(sid, "essential_product", i, t) for i, t in enumerate(products)]
            links += [(sid, brand_id[b], i) for i, b in enumerate(brands)]
        cur.executemany("INSERT INTO skin_type_details (skin_type_id, kind, position, text) VALUES (%s,%s,%s,%s)", details)
        cur.executemany("INSERT INTO skin_type_brands (skin_type_id, brand_id, position) VALUES (%s,%s,%s)", links)

        _add_routines(cur)
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()


def seed_demo_user():
    """Creates demo@meliora.dev with a skin type, saved brands and one saved routine. Returns True if created."""
    d = sd.DEMO_USER
    if q("SELECT id FROM users WHERE email=%s", (d["email"],), one=True):
        return False
    uid = q("INSERT INTO users (name, email, password_hash, skin_type) VALUES (%s,%s,%s,%s)",
            (d["name"], d["email"], generate_password_hash(d["password"]), d["skin_type"]), write=True)
    q("INSERT IGNORE INTO saved_brands (user_id, brand_id) SELECT %s, id FROM brands WHERE name IN (%s,%s,%s)",
      (uid, *sd.DEMO_SAVED_BRANDS), write=True)
    q("INSERT INTO saved_routines (user_id, title, content) VALUES (%s,%s,%s)", (uid, *sd.DEMO_ROUTINE), write=True)
    return True


def init_db(attempts=10, delay=3):
    """Create the database and tables if needed and seed on first run. Retries so the app can start
    before MySQL is ready (useful with Docker)."""
    last = None
    for n in range(1, attempts + 1):
        try:
            _connect_server().close()
            break
        except mysql.connector.Error as err:
            last = err
            print(f"[db] Connection attempt {n}/{attempts} failed. {describe_error(err)}")
            if getattr(err, "errno", None) == errorcode.ER_ACCESS_DENIED_ERROR or n == attempts:
                raise RuntimeError(f"Could not connect to MySQL. {describe_error(last)}") from err
            time.sleep(delay)

    apply_schema()
    if q("SELECT COUNT(*) AS n FROM brands", one=True)["n"] == 0:
        seed_catalogue()
        print("[db] Seeded skin types, brands and the oily-skin routine.")
    top_up_routines()
    if os.getenv("SEED_DEMO_DATA", "true").lower() in ("1", "true", "yes", "on"):
        if seed_demo_user():
            print(f"[db] Created the demo account ({sd.DEMO_USER['email']} / {sd.DEMO_USER['password']}).")
