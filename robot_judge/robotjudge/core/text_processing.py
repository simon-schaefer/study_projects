from typing import List

import nltk
import numpy as np

nltk.download("averaged_perceptron_tagger")
nltk.download("punkt")
nltk.download("stopwords")


def tokenizing(text: str) -> List[str]:
    """Create words vector plain text data using tokenization and remove stop words."""
    tokens = nltk.tokenize.word_tokenize(text)
    stop_words = set(nltk.corpus.stopwords.words("english"))
    tokens = [w for w in tokens if w not in stop_words]
    return tokens


def pos_tagging(tokens: List[str]) -> List[str]:
    """Apply pos tagging to given list of tokens, return list of tokens."""
    tokens = [w for w in tokens if w.isalnum()]
    pos_tags = nltk.pos_tag(tokens)
    return pos_tags


def count_adjs(tokens: List[str]) -> float:
    """Count number of descriptive words such as adjectives, adverbes."""
    pos_tags = [x[1] for x in pos_tagging(tokens)]
    if len(pos_tags) == 0:
        return 0.0
    else:
        uniques, counts = np.unique(pos_tags, return_counts=True)
        num_adv_adj = 0
        for x in ["JJ", "JJR", "JJS", "PDT", "RBR", "RBS", "RB"]:
            if x in uniques:
                num_adv_adj += counts[np.where(uniques == x)]
        return float(num_adv_adj) / len(pos_tags) * 100.0


def count_nums(tokens: List[str]) -> float:
    num_numeric = len([x for x in tokens if x.isnumeric()])
    if len(tokens) == 0:
        return 0.0
    else:
        return float(num_numeric) / len(tokens) * 100.0


def extract_year(text: str) -> int:
    """Extract year of creation of the bill from sample."""
    numbers = [int(x) for x in nltk.tokenize.word_tokenize(text) if x.isnumeric()]
    numbers = [x for x in numbers if 1900 < x < 2019]
    year = str(min(numbers)) if len(numbers) > 0 else None
    return int(year)


def split_sentences(text: str) -> List[List[str]]:
    """Split tokens in sentences using the punctuation."""
    sentences = nltk.tokenize.sent_tokenize(text)
    return [tokenizing(sent) for sent in sentences]
