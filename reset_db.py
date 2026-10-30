"""Wipe and re-seed the catalogue:  python reset_db.py
Users' saved brands are cleared too (they point at brand ids); accounts, chats and saved routines are kept."""
from dotenv import load_dotenv

load_dotenv()
from db import init_db, seed_catalogue, seed_demo_user  # noqa: E402

init_db()
seed_catalogue(reset=True)
seed_demo_user()
print("Catalogue reset and re-seeded.")
