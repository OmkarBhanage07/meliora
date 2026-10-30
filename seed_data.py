"""Catalogue data for Meliora, taken from the content already on the page."""

# name, icon, description, signs, concerns, essential products, recommended brands (in order)
SKIN_TYPES = [
    ("Normal", "✨", "Balanced oil and moisture with few concerns.",
     ["Even texture", "Small pores", "Rarely breaks out", "Comfortable all day"],
     ["Maintaining balance", "Sun protection", "Prevention"],
     ["Gentle gel cleanser", "Vitamin C serum", "Light moisturizer with SPF"],
     ["CeraVe", "The Ordinary", "La Mer"]),
    ("Oily", "💧", "Excess sebum production leads to shine, enlarged pores, and a higher tendency for breakouts and blackheads.",
     ["Shiny forehead and nose", "Enlarged pores", "Frequent breakouts", "Thick texture"],
     ["Oil control", "Minimizing pores", "Preventing acne", "Mattifying"],
     ["Foaming salicylic cleanser", "Niacinamide serum", "Oil-free SPF moisturizer"],
     ["The Ordinary", "Paula's Choice", "CeraVe"]),
    ("Dry", "🌸", "Low oil and water levels cause tightness, flaking, and dullness.",
     ["Tight after washing", "Flaky patches", "Dull complexion", "Fine lines show easily"],
     ["Hydration", "Barrier repair", "Flaking", "Dullness"],
     ["Cream cleanser", "Hyaluronic acid serum", "Rich ceramide moisturizer"],
     ["CeraVe", "La Mer", "Tatcha"]),
    ("Combination", "🌿", "An oily T-zone with normal or dry cheeks.",
     ["Shiny T-zone", "Dry cheeks", "Mixed pore size", "Occasional breakouts"],
     ["Balancing zones", "Pore care", "Hydration", "Texture"],
     ["Gentle gel cleanser", "Niacinamide serum", "Light gel-cream moisturizer"],
     ["Drunk Elephant", "The Ordinary", "Tatcha"]),
    ("Sensitive", "🌷", "Reacts easily with redness, stinging, or itching.",
     ["Redness", "Stinging with products", "Easily irritated", "Visible flushing"],
     ["Calming", "Barrier repair", "Redness", "Fragrance-free care"],
     ["Fragrance-free cleanser", "Soothing serum", "Ceramide moisturizer"],
     ["CeraVe", "Tatcha", "La Mer"]),
]

# name, tier, category, rating, tagline, hero product, price level (1-5), best-for tags, bg, accent, show_in_directory
BRANDS = [
    ("La Mer", "Luxury", "Skincare", 4.9, "The Science of the Sea", "Crème de la Mer", 5,
     ["Dry skin", "Anti-aging", "Barrier repair"], "#eef2f8", "#1a1512", True),
    ("SK-II", "Luxury", "Skincare", 4.8, "Unlock Radiant Skin", "Facial Treatment Essence", 5,
     ["All skin types", "Brightening", "Anti-aging"], "#fdeeee", "#c2185b", True),
    ("Tatcha", "Premium", "Skincare", 4.8, "Japanese Beauty Rituals", "The Water Cream", 4,
     ["Normal skin", "Sensitive skin", "Hydration"], "#fcf0f7", "#c2185b", True),
    ("Drunk Elephant", "Premium", "Skincare", 4.7, "Clean, Compatible Beauty", "T.L.C. Framboos Serum", 4,
     ["Combination skin", "Brightening", "Active ingredients"], "#fdf1e6", "#c2410c", True),
    ("NARS", "Premium", "Makeup", 4.8, "Bold, Unapologetic Beauty", "Sheer Glow Foundation", 3,
     ["All skin tones", "Long-wear", "Editorial looks"], "#f1f1f3", "#1a1512", True),
    ("Charlotte Tilbury", "Premium", "Makeup", 4.9, "Hollywood Glamour", "Magic Cream", 3,
     ["Dry skin", "Dewy finish", "Natural glam"], "#fdeeee", "#c2185b", True),
    ("The Ordinary", "Accessible", "Skincare", 4.6, "Clinical Formulations", "Niacinamide 10% + Zinc 1%", 1,
     ["Oily skin", "Beginners", "Active ingredients"], "#f3f3f3", "#1a1512", True),
    ("CeraVe", "Accessible", "Skincare", 4.7, "Developed with Dermatologists", "Moisturising Cream", 2,
     ["Sensitive skin", "Dry skin", "Barrier repair"], "#eaf2fd", "#1d4ed8", True),
    # Used by the skin guide and the routine builder but not shown as a card in the brand directory.
    ("Paula's Choice", "Accessible", "Skincare", 4.7, "Science-Backed Skincare", "2% BHA Liquid Exfoliant", 3,
     ["Oily skin", "Acne-prone skin", "Exfoliation"], "#f3f3f3", "#1a1512", False),
]

# Routine for oily skin, as shown on the page.
# step name, brand, duration, product, why, tip
ROUTINES = {
    ("Oily", "am"): ("Morning — for oily skin", "5–8 min", [
        ("Gentle Foaming Cleanser", "CeraVe", "60 sec", "Foaming Facial Cleanser",
         "Remove overnight buildup and excess oil without stripping",
         "Use lukewarm water — hot water strips your moisture barrier."),
        ("Balancing Toner", "Paula's Choice", "30 sec", "Skin Balancing Toner",
         "Prep skin so serums absorb evenly",
         "Pat it in with clean hands rather than a cotton pad."),
        ("Niacinamide Serum", "The Ordinary", "30 sec", "Niacinamide 10% + Zinc 1%",
         "Regulate oil and minimize the look of pores",
         "Start every other day if your skin is new to niacinamide."),
        ("Oil-Free Moisturizer", "Neutrogena", "30 sec", "Hydro Boost Water Gel",
         "Hydrate without adding shine",
         "Oily skin still needs moisture — do not skip it."),
        ("Sunscreen SPF 50", "EltaMD", "30 sec", "UV Clear Broad-Spectrum SPF 46",
         "Protect against UV damage and dark marks",
         "Apply two finger-lengths and reapply every two hours outdoors."),
    ]),
    ("Oily", "pm"): ("Evening — for oily skin", "6–9 min", [
        ("Oil Cleanser", "Banila Co", "60 sec", "Clean It Zero",
         "Melt off sunscreen and makeup",
         "Massage onto dry skin before adding water."),
        ("Foaming Cleanser", "CeraVe", "60 sec", "Foaming Facial Cleanser",
         "Second cleanse to clear remaining residue",
         "Rinse thoroughly with lukewarm water."),
        ("Salicylic Acid Exfoliant", "Paula's Choice", "30 sec", "2% BHA Liquid Exfoliant",
         "Unclog pores and smooth texture",
         "Use 2–3 nights a week, then build up."),
        ("Gel Moisturizer", "Neutrogena", "30 sec", "Hydro Boost Water Gel",
         "Lock in hydration overnight",
         "Use a thin layer so pores stay clear."),
    ]),
}

def _r(skin, am, pm):
    ROUTINES[(skin, "am")] = (f"Morning — for {skin.lower()} skin", "5–7 min", am)
    ROUTINES[(skin, "pm")] = (f"Evening — for {skin.lower()} skin", "5–8 min", pm)


_r("Normal",
   [("Gentle Gel Cleanser", "CeraVe", "60 sec", "Hydrating Facial Cleanser", "Clean without disturbing your balance", "Lukewarm water is enough."),
    ("Vitamin C Serum", "The Ordinary", "30 sec", "Ascorbyl Glucoside Solution 12%", "Brighten and protect against daily damage", "Apply to dry skin before moisturizer."),
    ("Light Moisturizer", "CeraVe", "30 sec", "Daily Moisturizing Lotion", "Keep hydration steady", "A pea-sized amount is plenty."),
    ("Sunscreen SPF 50", "EltaMD", "30 sec", "UV Daily Broad-Spectrum SPF 40", "Prevention is the best anti-aging step", "Reapply every two hours outdoors.")],
   [("Gentle Cleanser", "CeraVe", "60 sec", "Hydrating Facial Cleanser", "Remove sunscreen and the day's dirt", "Massage for a full minute."),
    ("Hydrating Serum", "The Ordinary", "30 sec", "Hyaluronic Acid 2% + B5", "Add a little extra moisture overnight", "Apply on slightly damp skin."),
    ("Night Moisturizer", "CeraVe", "30 sec", "Daily Moisturizing Lotion", "Seal in hydration", "Do not forget the neck.")])
_r("Dry",
   [("Cream Cleanser", "CeraVe", "60 sec", "Hydrating Cream-to-Foam Cleanser", "Clean without stripping oils", "Skip hot water; it dries skin further."),
    ("Hyaluronic Acid Serum", "The Ordinary", "30 sec", "Hyaluronic Acid 2% + B5", "Pull water into the skin", "Apply to damp skin so it can hold water."),
    ("Rich Moisturizer", "CeraVe", "30 sec", "Moisturising Cream", "Repair the barrier and lock moisture in", "Press it in; do not rub."),
    ("Sunscreen SPF 50", "EltaMD", "30 sec", "UV Daily Broad-Spectrum SPF 40", "Protect a thinner, drier barrier", "Choose a creamy formula.")],
   [("Oil Cleanser", "Banila Co", "60 sec", "Clean It Zero", "Melt off sunscreen gently", "Massage onto dry skin first."),
    ("Hydrating Serum", "The Ordinary", "30 sec", "Hyaluronic Acid 2% + B5", "Replenish water overnight", "Layer it under your cream."),
    ("Night Cream", "Tatcha", "30 sec", "The Dewy Skin Cream", "Restore comfort and glow", "Add a balm on flaky patches.")])
_r("Combination",
   [("Gentle Gel Cleanser", "Cetaphil", "60 sec", "Gentle Skin Cleanser", "Clean the T-zone without drying the cheeks", "Spend extra time on nose and forehead."),
    ("Niacinamide Serum", "The Ordinary", "30 sec", "Niacinamide 10% + Zinc 1%", "Balance oil and refine pores", "Use a few drops on the T-zone."),
    ("Gel-Cream Moisturizer", "Neutrogena", "30 sec", "Hydro Boost Water Gel", "Light hydration for every zone", "Use a bit more on dry cheeks."),
    ("Sunscreen SPF 50", "EltaMD", "30 sec", "UV Clear Broad-Spectrum SPF 46", "Protect without adding shine", "Reapply every two hours outdoors.")],
   [("Oil Cleanser", "Banila Co", "60 sec", "Clean It Zero", "Melt off sunscreen and makeup", "Rinse until no residue is left."),
    ("BHA on T-zone", "Paula's Choice", "30 sec", "2% BHA Liquid Exfoliant", "Clear pores where you get oily", "Only on the T-zone, 2–3 nights a week."),
    ("Richer Cream on Cheeks", "Tatcha", "30 sec", "The Water Cream", "Hydrate the dry areas", "Skip the T-zone if it feels heavy.")])
_r("Sensitive",
   [("Fragrance-Free Cleanser", "CeraVe", "60 sec", "Hydrating Facial Cleanser", "Clean without irritation", "Never use hot water."),
    ("Soothing Balm", "La Roche-Posay", "30 sec", "Cicaplast Baume B5", "Calm redness and support the barrier", "Patch-test new products first."),
    ("Ceramide Moisturizer", "CeraVe", "30 sec", "Moisturising Cream", "Strengthen the skin barrier", "Keep your routine to few products."),
    ("Mineral Sunscreen", "EltaMD", "30 sec", "UV Physical Broad-Spectrum SPF 41", "Mineral filters are gentler on reactive skin", "Reapply every two hours outdoors.")],
   [("Gentle Cleanser", "CeraVe", "60 sec", "Hydrating Facial Cleanser", "Remove the day without stinging", "Pat dry; do not rub."),
    ("Soothing Balm", "La Roche-Posay", "30 sec", "Cicaplast Baume B5", "Calm skin overnight", "Use a thin layer."),
    ("Night Moisturizer", "CeraVe", "30 sec", "PM Facial Moisturizing Lotion", "Lightweight overnight repair", "Skip actives while skin is irritated.")])

DEMO_USER = {"name": "Demo User", "email": "demo@meliora.dev", "password": "DemoPass123", "skin_type": "oily"}
DEMO_SAVED_BRANDS = ["The Ordinary", "CeraVe", "Tatcha"]
DEMO_ROUTINE = ("My oily-skin morning routine",
                "<ol><li>Foaming cleanser (CeraVe)</li><li>10% Niacinamide serum (The Ordinary)</li>"
                "<li>Oil-free SPF 50 (EltaMD)</li></ol>")
