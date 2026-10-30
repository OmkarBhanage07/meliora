import os, re, html
from flask import Flask, request, jsonify, session, send_from_directory
from werkzeug.security import generate_password_hash, check_password_hash
from mysql.connector import errors as dberr
from dotenv import load_dotenv

load_dotenv()
from db import q, init_db  # noqa: E402  (after load_dotenv so .env is read first)
app = Flask(__name__, static_folder="static", static_url_path="/static")
app.secret_key = os.getenv("SECRET_KEY", "dev-only-change-me")
init_db()


# ---------- database ----------
# q() and init_db() live in db.py; init_db() creates the database/tables and seeds them on first run.


def current_user():
    uid = session.get("uid")
    return q("SELECT id,name,email,skin_type FROM users WHERE id=%s", (uid,), one=True) if uid else None


# ---------- pages ----------
@app.route("/")
def home():
    return send_from_directory("static", "meliora.html")


# ---------- auth ----------
@app.post("/api/register")
def register():
    d = request.get_json(force=True)
    name, email, pw = d.get("name", "").strip(), d.get("email", "").strip().lower(), d.get("password", "")
    if not name or not re.match(r"[^@\s]+@[^@\s]+\.[^@\s]+$", email) or len(pw) < 6:
        return jsonify(error="Enter a name, a valid email and a password of 6+ characters."), 400
    try:
        uid = q("INSERT INTO users(name,email,password_hash) VALUES(%s,%s,%s)",
                (name, email, generate_password_hash(pw)), write=True)
    except dberr.IntegrityError:
        return jsonify(error="That email is already registered."), 409
    session["uid"] = uid
    return jsonify(user=current_user())


@app.post("/api/login")
def login():
    d = request.get_json(force=True)
    u = q("SELECT * FROM users WHERE email=%s", (d.get("email", "").strip().lower(),), one=True)
    if not u or not check_password_hash(u["password_hash"], d.get("password", "")):
        return jsonify(error="Wrong email or password."), 401
    session["uid"] = u["id"]
    return jsonify(user=current_user())


@app.post("/api/logout")
def logout():
    session.clear()
    return jsonify(ok=True)


@app.get("/api/me")
def me():
    return jsonify(user=current_user())


# ---------- Mili chatbot ----------
SKIN_PLANS = {
    "oily": "For <b>oily skin</b>:<ol><li>AM: foaming salicylic cleanser (CeraVe)</li><li>10% Niacinamide serum (The Ordinary)</li><li>Oil-free SPF 50 (EltaMD)</li><li>PM: cleanse, BHA 2-3 nights a week, light gel moisturiser</li></ol>",
    "dry": "For <b>dry skin</b>:<ol><li>AM: cream cleanser (CeraVe)</li><li>Hyaluronic acid serum on damp skin</li><li>Rich ceramide moisturiser + SPF 50</li><li>PM: cleanse, moisturise, seal with a balm if flaky</li></ol>",
    "combination": "For <b>combination skin</b>:<ol><li>AM: gentle gel cleanser</li><li>Niacinamide serum</li><li>Light gel-cream moisturiser + SPF</li><li>PM: cleanse, then richer cream on cheeks only</li></ol>",
    "sensitive": "For <b>sensitive skin</b>:<ol><li>AM: fragrance-free cleanser</li><li>Soothing serum (centella / panthenol)</li><li>Ceramide moisturiser + mineral SPF</li><li>Patch-test every new product first</li></ol>",
    "normal": "For <b>normal skin</b>:<ol><li>AM: gentle gel cleanser</li><li>Vitamin C serum</li><li>Light moisturiser + SPF 50</li><li>PM: cleanse, retinol 2 nights a week</li></ol>",
}
BRANDS = {
    "cerave": "CeraVe is an accessible, dermatologist-developed brand built on ceramides. Great for dry or sensitive skin and barrier repair.",
    "the ordinary": "The Ordinary sells simple, affordable single-active serums such as niacinamide and hyaluronic acid.",
    "la mer": "La Mer is a luxury brand famous for its Creme de la Mer, a rich moisturiser best for dry skin.",
    "tatcha": "Tatcha is a premium Japanese-inspired brand with gentle, hydrating formulas.",
    "paula's choice": "Paula's Choice is known for effective BHA exfoliants, ideal for oily and acne-prone skin.",
    "drunk elephant": "Drunk Elephant is a premium brand focused on a minimal, 'clean-compatible' approach.",
}


def detect_skin(text):
    for k in SKIN_PLANS:
        if k in text:
            return k
    if re.search(r"pore|shine|greasy", text):
        return "oily"
    if re.search(r"flak|tight", text):
        return "dry"
    return None


def rule_reply(text, saved_skin):
    t = text.lower()
    for name, info in BRANDS.items():
        if name in t:
            return info
    skin = detect_skin(t)
    if skin:
        return SKIN_PLANS[skin]
    if re.search(r"routine|am|pm", t) and saved_skin:
        return SKIN_PLANS[saved_skin]
    if re.search(r"\b(hi|hello|hey)\b", t):
        return "Hi! I'm Mili, your beauty advisor. Tell me your skin type and main concern."
    return "Tell me your skin type (oily, dry, combination, sensitive or normal) and main concern, and I'll recommend a routine and brands."


def llm_reply(text, history):
    import anthropic
    client = anthropic.Anthropic()  # reads ANTHROPIC_API_KEY
    msgs = [{"role": "user" if m["role"] == "user" else "assistant", "content": m["content"]} for m in history]
    msgs.append({"role": "user", "content": text})
    r = client.messages.create(
        model="claude-sonnet-5-5", max_tokens=400,
        system="You are Mili, a warm skincare and cosmetics advisor for the Meliora website. "
               "Keep answers under 120 words. Give general guidance, not medical advice; "
               "suggest seeing a dermatologist for persistent or severe problems.",
        messages=msgs)
    return html.escape(r.content[0].text).replace("\n", "<br>")


@app.post("/api/chat")
def chat():
    text = (request.get_json(force=True).get("message") or "").strip()[:500]
    if not text:
        return jsonify(error="Say something to Mili first."), 400
    user = current_user()
    history = []
    if user:
        history = list(reversed(q("SELECT role,content FROM chat_messages WHERE user_id=%s ORDER BY id DESC LIMIT 10", (user["id"],))))
        skin = detect_skin(text.lower())
        if skin:
            q("UPDATE users SET skin_type=%s WHERE id=%s", (skin, user["id"]), write=True)
            user["skin_type"] = skin
    reply = None
    if os.getenv("ANTHROPIC_API_KEY"):
        try:
            reply = llm_reply(text, history)
        except Exception as e:
            app.logger.warning("LLM failed, using rules: %s", e)
    if reply is None:
        reply = rule_reply(text, user["skin_type"] if user else None)
    if user:
        q("INSERT INTO chat_messages(user_id,role,content) VALUES(%s,'user',%s)", (user["id"], text), write=True)
        q("INSERT INTO chat_messages(user_id,role,content) VALUES(%s,'bot',%s)", (user["id"], reply), write=True)
    return jsonify(reply=reply)


@app.get("/api/chat/history")
def chat_history():
    user = current_user()
    if not user:
        return jsonify(messages=[])
    return jsonify(messages=q("SELECT role,content FROM chat_messages WHERE user_id=%s ORDER BY id", (user["id"],)))


# ---------- saved routines ----------
@app.post("/api/routines")
def save_routine():
    user = current_user()
    if not user:
        return jsonify(error="Please sign in to save routines."), 401
    d = request.get_json(force=True)
    rid = q("INSERT INTO saved_routines(user_id,title,content) VALUES(%s,%s,%s)",
            (user["id"], d.get("title", "My routine")[:150], d.get("content", "")), write=True)
    return jsonify(id=rid)


@app.get("/api/routines")
def list_routines():
    user = current_user()
    if not user:
        return jsonify(routines=[])
    return jsonify(routines=q("SELECT id,title,content,created_at FROM saved_routines WHERE user_id=%s ORDER BY id DESC", (user["id"],)))


@app.post("/api/skin-type")
def set_skin_type():
    user = current_user()
    if not user:
        return jsonify(error="Please sign in to save your skin type."), 401
    skin = str((request.get_json(force=True) or {}).get("skin", "")).lower()
    if not q("SELECT id FROM skin_types WHERE slug=%s", (skin,), one=True):
        return jsonify(error="Unknown skin type."), 400
    q("UPDATE users SET skin_type=%s WHERE id=%s", (skin, user["id"]), write=True)
    return jsonify(ok=True, skin_type=skin)


# ---------- catalogue (brands, skin types, routine templates) ----------
def _brands(where="", args=()):
    rows = q("SELECT id,name,slug,tier,category,rating,tagline,hero_product,price_level,bg_color,accent_color "
             "FROM brands WHERE show_in_directory=1 " + where + " ORDER BY id", args)
    tags = q("SELECT brand_id,tag FROM brand_tags ORDER BY brand_id,position")
    by_brand = {}
    for t in tags:
        by_brand.setdefault(t["brand_id"], []).append(t["tag"])
    for r in rows:
        r["rating"] = float(r["rating"])
        r["tags"] = by_brand.get(r["id"], [])
    return rows


@app.get("/api/brands")
def list_brands():
    tier = request.args.get("tier")
    if tier:
        return jsonify(brands=_brands("AND tier=%s", (tier,)))
    return jsonify(brands=_brands())


@app.get("/api/skin-types")
def list_skin_types():
    skins = q("SELECT id,name,slug,icon,description FROM skin_types ORDER BY id")
    details = q("SELECT skin_type_id,kind,text FROM skin_type_details ORDER BY skin_type_id,position")
    brands = q("SELECT l.skin_type_id,b.name FROM skin_type_brands l JOIN brands b ON b.id=l.brand_id "
               "ORDER BY l.skin_type_id,l.position")
    for s in skins:
        s["signs"] = [d["text"] for d in details if d["skin_type_id"] == s["id"] and d["kind"] == "sign"]
        s["concerns"] = [d["text"] for d in details if d["skin_type_id"] == s["id"] and d["kind"] == "concern"]
        s["essentials"] = [d["text"] for d in details if d["skin_type_id"] == s["id"] and d["kind"] == "essential_product"]
        s["brands"] = [b["name"] for b in brands if b["skin_type_id"] == s["id"]]
    return jsonify(skin_types=skins)


@app.get("/api/routine-templates/<skin>")
def routine_template(skin):
    out = {}
    for t in q("SELECT t.id,t.period,t.subtitle,t.duration FROM routine_templates t "
               "JOIN skin_types s ON s.id=t.skin_type_id WHERE s.slug=%s", (skin.lower(),)):
        t["steps"] = q("SELECT step_name,brand_name,duration,product,why,tip FROM routine_steps "
                       "WHERE template_id=%s ORDER BY position", (t["id"],))
        out[t["period"]] = t
    if not out:
        return jsonify(error="No routine template for that skin type yet."), 404
    return jsonify(routines=out)


# ---------- saved brands (favourites) ----------
@app.get("/api/favorites")
def list_favorites():
    user = current_user()
    if not user:
        return jsonify(brands=[])
    return jsonify(brands=q("SELECT b.name,b.slug,b.tier,b.hero_product FROM saved_brands s "
                            "JOIN brands b ON b.id=s.brand_id WHERE s.user_id=%s ORDER BY s.created_at DESC", (user["id"],)))


@app.post("/api/favorites/<slug>")
def add_favorite(slug):
    user = current_user()
    if not user:
        return jsonify(error="Please sign in to save brands."), 401
    b = q("SELECT id FROM brands WHERE slug=%s", (slug,), one=True)
    if not b:
        return jsonify(error="Unknown brand."), 404
    q("INSERT IGNORE INTO saved_brands(user_id,brand_id) VALUES(%s,%s)", (user["id"], b["id"]), write=True)
    return jsonify(ok=True)


@app.delete("/api/favorites/<slug>")
def remove_favorite(slug):
    user = current_user()
    if not user:
        return jsonify(error="Please sign in."), 401
    q("DELETE s FROM saved_brands s JOIN brands b ON b.id=s.brand_id WHERE s.user_id=%s AND b.slug=%s",
      (user["id"], slug), write=True)
    return jsonify(ok=True)


if __name__ == "__main__":
    app.run(debug=True)
