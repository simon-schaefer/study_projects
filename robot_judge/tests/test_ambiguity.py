import robotjudge.core.ambiguity
import robotjudge.core.text_processing


def test_ambiguity_ambiguous():
    context = "I went to the bank to deposit money."
    # Tokenizing and POS tagging.
    tokens = robotjudge.core.text_processing.tokenizing(context)
    # Measure ambiguity.
    ambiguity_score = robotjudge.core.ambiguity.lesk(tokens, "bank", pos='n')
    assert ambiguity_score > 0.8


def test_ambiguity_nonambiguous():
    context = "The river overflowed the bank, everything is under water."
    # Tokenizing and POS tagging.
    tokens = robotjudge.core.text_processing.tokenizing(context)
    # Measure ambiguity.
    ambiguity_score = robotjudge.core.ambiguity.lesk(tokens, "bank", pos='n')
    assert ambiguity_score < 0.1


def test_ambiguity_mean():
    text = "I went to the bank to deposit money. The river overflowed the bank, everything is under water."
    # Determine ambiguity mean over text.
    ambiguity_mean = robotjudge.core.ambiguity.mean(text)
    assert 0.3 < ambiguity_mean < 0.7
