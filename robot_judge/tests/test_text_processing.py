import robotjudge.core.text_processing


def test_text_processing():
    text = "I want to, test. tokenizing and removing stopwords"
    tokens = robotjudge.core.text_processing.tokenizing(text)
    assert len(tokens) == 8
    assert "removing" in tokens


def test_year_extraction():
    text = "I was written in 2001"
    year = robotjudge.core.text_processing.extract_year(text)
    assert year == 2001


def test_count_numeric():
    text = "this 200 is a nice year 2015"
    tokens = robotjudge.core.text_processing.tokenizing(text)
    num_adv_adj = robotjudge.core.text_processing.count_adjs(tokens)
    assert num_adv_adj == 25.0
    num_numeric = robotjudge.core.text_processing.count_nums(tokens)
    assert num_numeric == 50.0


def test_split_sentences():
    text = "First sentence ! Second. Third etc."
    sentences = robotjudge.core.text_processing.split_sentences(text)
    assert len(sentences) == 3
