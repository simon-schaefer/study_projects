# Relevant set of keywords for industry sector.
TAG_SET = {
    "resources": [
        "oil",
        "petroleum",
        "gas",
        "forest",
        "minerals",
        "minerals",
        "coal",
        "mining",
        "mines",
        "energy",
        "natural gas",
        "fuel",
        "reserves",
        "bcl",
        "drilling",
        "upstream",
        "downstream",
    ],
    "agriculture": [
        "farm",
        "rural",
        "agriculture",
        "organic",
        "food",
        "biological",
        "farming",
        "meat",
        "beef",
        "slaugtherer",
        "butcher",
        "cow",
        "pork",
        "chicken",
        "rind",
        "potatoes",
        "corn",
        "irrigation",
        "watering",
        "environment",
        "nature",
        "pollution",
        "pesticide",
        "fertilizer",
        "seed",
        "seeds",
    ],
    "finance": [
        "insurance",
        "bank",
        "stock market",
        "stock exchange",
        "leasing",
        "finance",
        "investing",
        "investemont",
        "asset",
        "assets",
        "deposit",
        "deposits",
        "fund",
        "funds",
        "money",
        "market",
        "crisis",
        "management",
        "mortgage",
    ],
}


def tagging(text_words):
    """Allocate industry sector to every sample by looking for specific words
    (specified above). Non-allocated texts are labelled as "others"."""
    tag = "others"
    for desc, tag_words in TAG_SET.items():
        if any([word in text_words for word in tag_words]):
            tag = desc
            break
    return tag
