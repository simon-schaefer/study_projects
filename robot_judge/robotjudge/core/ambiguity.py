from typing import List

import nltk
import numpy as np

import robotjudge.core.text_processing

nltk.download("wordnet")


def lesk(context_tokens: List[str], ambiguous_word: str, pos=None) -> float:
    """Ambiguity measurement of an (ambiguous) word in a given context using
    word-sense disambiguation (WSD) by Lesk's algorithm from 1986 [1](implemented
    in NLTK library http://www.nltk.org/howto/wsd.html). The ambiguty score is
    thereby defined as the distribution of intersection of context and the
    sysnet entries of the queried word.

    [1] Lesk, Michael. "Automatic sense disambiguation using machine
    readable dictionaries: how to tell a pine cone from an ice cream
    cone." Proceedings of the 5th Annual International Conference on
    Systems Documentation. ACM, 1986.
    http://dl.acm.org/citation.cfm?id=318728

    :param list context_tokens: context tokens of word as list (already preprocessed)
    :param str ambiguous_word: ambiguous word that requires WSD.
    :param str pos: Part-of-Speech (POS) of word.
    :return: ``lesk_sense`` NLTK Synset() object with the highest signature overlaps.

    Usage example::

        >>> lesk(['I', 'went', 'the', 'bank', 'deposit', 'money'], 'bank', 'n')
        Synset('savings_bank.n.02')
    """
    # Preprocess context tokens (unique words).
    context = set([w.lower() for w in context_tokens if w.isalpha()])

    # Find sysnet entries of queried word and filter (if pos_tag is given). Merely
    # take sysnets into account containing the queried word itself.
    synsets_cands = nltk.corpus.wordnet.synsets(ambiguous_word)
    if pos:
        synsets_cands = [ss for ss in synsets_cands if str(ss.pos()) == pos]
    if not synsets_cands:
        return -1.0

    # Determine ambiguity by best intersection from synset and context. The score
    # is obtained by the number of intersection between the sense defintion and
    # word's context.
    sense_scores, synsets = [], []
    for ss in synsets_cands:
        ss_def = robotjudge.core.text_processing.tokenizing(ss.definition())
        intersection = context.intersection(ss_def)
        if len(intersection) > 0:
            sense_scores.append(len(intersection))
            synsets.append(ss)
    sense_scores = np.asarray(sense_scores)
    if len(synsets) == 0:
        ambiguity_score = -1.0

    # If there is only one possible sense, the text is fully non-ambiguous, therefore
    # the ambiguity score can be set to 0 without further ado.
    elif len(synsets) == 1:
        ambiguity_score = 0.0

    # To rank the (in general multiple) possible senses weight them by their
    # similarity score (WuP similarity) [0, 1].
    else:
        similarity_scores = np.zeros((len(synsets), len(synsets)))
        for ix, x in enumerate(synsets):
            for iy, y in enumerate(synsets):
                if iy <= ix:
                    continue
                sim_score = x.wup_similarity(y)
                similarity_scores[ix, iy] = sim_score if sim_score is not None else 0.0
        np.fill_diagonal(similarity_scores, 1.0)
        similarity_scores = np.round(similarity_scores + similarity_scores.T, 5)

        # The final ambiguity score now is obtained by combining both sense and
        # similarity scores. Therefore the adjoint of the similarity is determined,
        # and multiplied with the sense scores. Since an adjoint function is not
        # available it is obtained by using inv(A) = 1/|A| adj(A).
        similarity_scores_det = np.linalg.det(similarity_scores)
        if np.abs(similarity_scores_det) < 1e-5:
            ambiguity_score = 0.0
        else:
            similarity_scores_adj = similarity_scores_det * np.linalg.inv(similarity_scores)
            scores = np.dot(np.abs(similarity_scores_adj), sense_scores)
            ambiguity_score = np.amin(scores) / max(np.sum(scores), np.array(1e-8))

    return float(ambiguity_score)


def mean(text: str) -> float:
    """Determine weighted average from whole text corpus, by splitting the
    text first and then using pos tagging to determine the nouns in a sentence. The ambiguity
    score of the whole corpus is the (weighted) average of the ambiguities of each noun given
    its context."""
    sent_tokens = robotjudge.core.text_processing.split_sentences(text)
    scores = []
    for sentence in sent_tokens:
        tokens = robotjudge.core.text_processing.pos_tagging(sentence)
        for it, (w, t) in enumerate(tokens):
            if t == "NN":
                scores.append(lesk(sentence, ambiguous_word=w, pos="n"))
    return float(np.mean([x for x in scores if x >= 0.0]))
